using DataFrames, Eolas, RecipesBase
using DelimitedFiles

import IterTools: subsets

include("bin.jl")

function Eolas.pid(::Type{T}, df::DataFrame, stimulus, k::Int) where T
    naman = let allnames = names(df)
        allnames[allnames .!= stimulus]
    end
    results = Dict{Symbol,Any}[]
    for responses = subsets(naman, k)
        lattice = pid(T, df[:, stimulus], transpose(Array(df[:, responses])), responses)
        push!(results, Dict(:target => stimulus, :sources => responses, :lattice => lattice))
    end
    results
end

function gpid(input::AbstractString, target::Symbol, numsources::Int;
              algo::Union{Nothing,DiscretizationAlgorithm}=MeanBinner(),
              verbose::Bool=true)

    verbose && @info "Reading..." file=input

    df = DataFrame(CSV.File(input; ignoreemptylines=true))
    dropmissing!(df)
    disallowmissing!(df)

    results = gpid!(df, target, numsources; algo=algo, verbose=verbose)
    foreach(r -> r[:input] = input, results)

    results
end

function gpid(df::DataFrame, target::Symbol, numsources::Int;
              algo::Union{Nothing,DiscretizationAlgorithm}=MeanBinner(),
              verbose::Bool=true)
    gpid!(copy(df), target, numsources; algo=algo, verbose=verbose)
end

function gpid!(df::DataFrame, target::Symbol, numsources::Int;
              algo::Union{Nothing,DiscretizationAlgorithm}=MeanBinner(),
              verbose::Bool=true)

    verbose && @info "Binning data..."
    ef = bin(df; algo=algo, replace=true)
    if any(Array(aggregate(ef, maximum) .< 2))
        algo = MeanBinner()
        @warn "Binning resulted in fewer than two bins; falling back to" algo
        df = bin(df; algo=algo, replace=true)
        if any(Array(aggregate(df, maximum) .< 2))
            @error """Default binning method resulted in fewer than two bins;
                      do all of your data columns have at least two distinct values?"""
            throw(ErrorException("invalid binning"))
        end
    else
        df = ef
    end

    verbose && @info "Computing information decompositions..."
    results = pid(WilliamsBeer, df, target, numsources)
    foreach(r -> r[:algorithm] = algo, results)
    results
end

@userplot GpidPlot

@recipe function f(g::GpidPlot; dotplot=true, mode=:density)
    df = g.args[1]
    field = g.args[2]

    ef = DataFrame(input = String[],
                   name = String[],
                   value = Float64[])
    for row in eachrow(df)
        for v in vertices(row.lattice)
            value = getproperty(payload(v), field)
            if !isapprox(value, zero(value), atol=1e-6)
                push!(ef, (input=row.input, name=Eolas.prettyname(v), value=value))
            end
        end
    end

    names = unique(sort(ef.name))

    samples = ef[ef.input .!= "whole",:]
    whole = ef[ef.input .== "whole",:]

    width = max(1000, 25length(names))
    height = (2width) ÷ 5
    size --> (width, height)

    xrotation --> 45.0
    xticks --> ((1:length(names)) .- 0.5, names)
    xlabel --> "Variables"

    if dotplot
        @series begin
            seriestype := :dotplot
            marker := (:circ, 4, 1.0)
            color := 1
            label := "Simulations"
            mode := mode
            samples.name, samples.value
        end
    end

    @series begin
        seriestype := :violin
        color := 1
        label := dotplot ? "" : "Simulations"
        α --> 0.5
        samples.name, samples.value
    end

    @series begin
        seriestype := :dotplot
        marker := (:star, 8, 1.0)
        color := 2
        label := "Aggregate"
        mode := :center
        whole.name, whole.value
    end
end
