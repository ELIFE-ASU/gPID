using Base.Threads, DrWatson

function gpid(file::AbstractString)
    run(`julia --project=. scripts/gpid.jl -i $file -t Region -s 1 2 3 4`)
end

function runall()
	dir = datadir("sims")
    filenames = filter(s -> occursin(r"\.csv$", s), readdir(dir))
    @threads :static for filename in filenames
        gpid(filename)
	end

    bsons = filter(s -> occursin(r"\.bson\.gz$", s), readdir(datadir("results"); join=true))
    params = map(p -> p[2], parse_savename.(bsons))
    for (param, bson) in zip(params, bsons)
        dir = datadir("results", "gen=$(param["gen"])")
        mkpath(dir)
        mv(bson, joinpath(dir, basename(bson)))
    end
end

runall()
