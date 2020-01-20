function renamefiles(dir::AbstractString)
    files = readdir(dir)
    roots = map(f -> last(split(f, "-")), files)
    parts = splitext.(roots)
    numbers = parse.(Int, first.(parts))
    exts = last.(parts)
    digits = Int(ceil(log(10, length(numbers))))
    newfiles = repeat.("0", digits .- Int.(ceil.(log.(10, numbers .+ 1)))) .* string.(numbers) .* exts

    for (file, newfile) in zip(files, newfiles)
        src = joinpath(dir, file)
        dst = joinpath(dir, newfile)
        if src == dst
            @info "Already well-named" file=src
        else
            @info "Moving file" from=src to=dst
            mv(src, dst)
        end
    end
end

function cleanupcsv(dir)
    for file in filter(f -> occursin(r"\.csv$", f), readdir(dir))
        filepath = joinpath(dir, file)
        @info "Formatting file" filepath
        run(`sed -i 's/,\s*$//g' $filepath`)
    end
end

function main()
    renamefiles(ARGS[1])
    cleanupcsv(ARGS[1])
end

main()
