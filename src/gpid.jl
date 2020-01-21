using DataFrames, Eolas, IterTools

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
