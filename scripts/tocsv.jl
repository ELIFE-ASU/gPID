using CSV, DrWatson, DataFrames, Discretizers, Imogen, Parameters

const indir = datadir("results", "2020-01-05")
const outdir = datadir("results", "2020-01-05", "csv")

function main()
    if isdir(outdir)
        rm(outdir; force=true, recursive=true)
    end
    mkpath(outdir)
    for scenario in filter(!=("csv"), readdir(indir))
        data = collect_results(joinpath(indir, scenario))
        for group in groupby(data, :sources)
            outfile = joinpath(outdir, join(string.(group.sources[1]), "_") * ".csv")
            df = if isfile(outfile)
                CSV.File(outfile) |> DataFrame
            else
                lattice = group.lattice[1]
                df = DataFrame(replicate=String[], scenario=String[], payload=String[])
                for name in Imogen.prettyname.(vertices(lattice))
                    df[!, Symbol(name)] = Float64[]
                end
                df
            end
            for (s, p) in [(:Iₘᵢₙ, "Imin"), (:Π, "Pi")]
                for row in eachrow(group)
                    replicate, _ = splitext(row[:input])
                    newrow = Dict{Symbol, Any}(:replicate => replicate,
                                               :scenario => scenario,
                                               :payload => p)
                    for vertex in vertices(row[:lattice])
                        name = Symbol(Imogen.prettyname(vertex))
                        data = getproperty(payload(vertex), s)
                        newrow[name] = data
                    end
                    @assert length(newrow) == length(row[:lattice]) + 3
                    push!(df, newrow)
                end
            end
            sort!(df, [:payload, :replicate, :scenario])
            CSV.write(outfile, df)
        end
    end
end
