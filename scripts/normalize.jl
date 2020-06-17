using ArgParse, Parameters

function renamefiles(dir::AbstractString; verbose=true)
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
            verbose && @info "Already well-named" file=src
        else
            verbose && @info "Moving file" from=src to=dst
            mv(src, dst)
        end
    end
end

function cleanupcsv(dir::AbstractString; verbose=true)
    for file in filter(f -> occursin(r"\.csv$", f), readdir(dir))
        filepath = joinpath(dir, file)
        verbose && @info "Formatting file" filepath
        run(`sed -i 's/,\s*$//g' $filepath`)
    end
end

function main()
    s = ArgParseSettings(version="1.0", add_version=true)

    @add_arg_table! s begin
        "--verbose", "-v"
            help = "enable verbose output"
            action = :store_true
    end

    add_arg_group!(s, "Input and Output")
    @add_arg_table! s begin
        "directory"
            help = "path to a directory whose CSV files should be normalized"
            arg_type = String
            required = true
    end

    @unpack directory, verbose = parse_args(s)

    renamefiles(directory; verbose=verbose)
    cleanupcsv(directory; verbose=verbose)
end

main()
