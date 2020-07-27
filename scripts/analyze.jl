using Distributed, DrWatson
addprocs(16)

@everywhere function gpid(file::AbstractString)
	display(file)
	run(`julia --project=. scripts/gpid.jl -i $file -t Region -s 1 2 3 4`)
end

function runall()
	dir = datadir("sims")
	filenames = filter(s -> occursin(r"\.csv$", s), readdir(dir))
	while !isempty(filenames)
		@sync for p in workers()
			if !isempty(filenames)
				file = pop!(filenames)
				@async remotecall_wait(gpid, p, file)
			end
		end
	end
end

runall()
