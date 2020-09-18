using CSV, DrWatson, DataFrames, Discretizers, Imogen, Parameters

include(srcdir("bin.jl"))

sources(lattice) = join(unique(sort(vcat(vcat(name.(vertices(lattice))...)...))), ", ")

function tocsv(indir)
    outdir = joinpath(indir, "csv")
    if isdir(outdir)
        rm(outdir; force=true, recursive=true)
    end
    mkpath(outdir)
    data = collect_results(indir)
    alldata = DataFrame[]
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
            df[!, :sources] = String[]
            df[!, :payload] = String[]
            df[!, :node] = String[]
            df[!, :value] = Float64[]
            df
        end
        for (s, p) in [(:Iₘᵢₙ, "Imin"), (:Π, "Pi")]
            for row in eachrow(group)
                newrow = Dict{Symbol, Any}(:payload => p, :sources => sources(row[:lattice]))
                for (k, v) in parse_savename(row[:input])[2]
                    newrow[Symbol(k)] = v
                end
                for vertex in vertices(row[:lattice])
                    name = Imogen.prettyname(vertex)
                    data = getproperty(payload(vertex), s)
                    newrow[:node] = name
                    newrow[:value] = data
                    push!(df, newrow)
                end
            end
        end
        sort!(df, sorted_columns)
        CSV.write(outfile, df)
        push!(alldata, df)
    end
    CSV.write(joinpath(outdir, "alldata.csv"), vcat(alldata...))
end

tocsv("data/results/10000")
tocsv("data/results/100000")
