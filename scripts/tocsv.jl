using BSON, CSV, DrWatson, DataFrames, Discretizers, GZip, Imogen, Parameters

include(srcdir("bin.jl"))

sources(lattice) = join(unique(sort(vcat(vcat(name.(vertices(lattice))...)...))), ", ")

function get_results(folder;
    valid_filetypes = [".bson", "jld", ".jld2"],
    subfolders = false,
    rpath = nothing,
    verbose = true,
    kwargs...)

    df = DataFrame()
    @info "Scanning folder $folder for result files."

    if subfolders
        allfiles = String[]
        for (root, dirs, files) in walkdir(folder)
            for file in files
                push!(allfiles, joinpath(root,file))
            end
        end
    else
        allfiles = joinpath.(Ref(folder), readdir(folder))
    end

    n = 0
    existing_files = "path" in string.(names(df)) ? df[:,:path] : ()
    for file ∈ allfiles
        isgz = last(splitext(file)) == ".gz"
        if isgz
            DrWatson.is_valid_file(first(splitext(file)), valid_filetypes) || continue
        else
            DrWatson.is_valid_file(file, valid_filetypes) || continue
        end
        file = rpath === nothing ? file : relpath(file, rpath)
        file ∈ existing_files && continue

        if isgz
            io = rpath === nothing ? GZip.open(file, "r") : GZip.open(joinpath(rpath, file), "r")
            data = BSON.load(io)
            close(io)
        else
            data = rpath === nothing ? wload(file) : wload(joinpath(rpath, file))
        end
        df_new = DrWatson.to_data_row(data, file; kwargs...)
        df_new[!, :path] .= file

        df = DrWatson.merge_dataframes!(df, df_new)
        n += 1
    end
    verbose && @info "Added $n entries."
    return df
end

function tocsv(indir)
    outdir = joinpath(indir, "csv")
    if isdir(outdir)
        rm(outdir; force=true, recursive=true)
    end
    mkpath(outdir)
    data = get_results(indir)
    alldata = DataFrame[]
    for group in groupby(data, :sources)
        outfile = joinpath(outdir, join(string.(group.sources[1]), "_") * ".csv.gz")
        sorted_columns = Symbol[]
        df = if isfile(outfile)
            io = GZip.open(outfile, "r")
            df = CSV.File(outfile) |> DataFrame
            close(io)
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
        io = GZip.open(outfile, "w")
        CSV.write(io, df)
        close(io)
        push!(alldata, df)
    end
    fname = joinpath(outdir, "alldata.csv.gz")
    io = GZip.open(fname, "w")
    CSV.write(io, vcat(alldata...))
    close(io)
end

tocsv("data/results")
