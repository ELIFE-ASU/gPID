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
end

runall()
