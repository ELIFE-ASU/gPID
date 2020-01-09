using DataFrames, Eolas, IterTools

include("bin.jl")

function Eolas.pid(::Type{T}, df::DataFrame, stimulus, k::Int) where T
    naman = let allnames = names(df)
        allnames[allnames .!= stimulus]
    end
    d = Dict{Tuple,Hasse}()
    for responses = subsets(naman, k)
        h = pid(T, df[:, stimulus], transpose(Array(df[:, responses])), responses)
        d[(stimulus, responses...)] = h
    end
    d
end
