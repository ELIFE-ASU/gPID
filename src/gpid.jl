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
