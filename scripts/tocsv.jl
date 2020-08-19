using CSV, DrWatson, DataFrames, Discretizers, Imogen, Parameters

include(srcdir("bin.jl"))

function tocsv(indir)
    outdir = joinpath(indir, "csv")
    if isdir(outdir)
        rm(outdir; force=true, recursive=true)
    end
    mkpath(outdir)
    data = collect_results(indir)
    for group in groupby(data, :sources)
        outfile = joinpath(outdir, join(string.(group.sources[1]), "_") * ".csv")
        sorted_columns = Symbol[]
        df = if isfile(outfile)
            CSV.File(outfile) |> DataFrame
        else
            lattice = group.lattice[1]
            input = group.input[1]
            df = DataFrame()
            for (k, v) in parse_savename(input)[2]
                column_name = Symbol(k)
                push!(sorted_columns, column_name)
                if v isa Real
                    df[!, column_name] = Float64[]
                else
                    df[!, column_name] = typeof(v)[]
                end
            end
            df[!, :payload] = String[]
            for name in Imogen.prettyname.(vertices(lattice))
                df[!, Symbol(name)] = Float64[]
            end
            df
        end
        for (s, p) in [(:Iₘᵢₙ, "Imin"), (:Π, "Pi")]
            for row in eachrow(group)
                newrow = Dict{Symbol, Any}(:payload => p)
                for (k, v) in parse_savename(row[:input])[2]
                    newrow[Symbol(k)] = v
                end
                for vertex in vertices(row[:lattice])
                    name = Symbol(Imogen.prettyname(vertex))
                    data = getproperty(payload(vertex), s)
                    newrow[name] = data
                end
                push!(df, newrow)
            end
        end
        sort!(df, sorted_columns)
        CSV.write(outfile, df)
    end
end
