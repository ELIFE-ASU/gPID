using ArgParse, Base.Meta, CSV, DrWatson, Parameters, Printf

include(srcdir("gpid.jl"))

ArgParse.parse_item(::Type{Symbol}, x::AbstractString) = Symbol(x)
ArgParse.parse_item(::Type{DiscretizationAlgorithm}, x::AbstractString) = eval(Meta.parse(x))

const s = ArgParseSettings(version="1.0", add_version=true)

@add_arg_table s begin
    "--input", "-i"
        help = "input file path"
        arg_type = String
        required = true
    "--algorithm", "-a"
        help = "binning algorithm"
        arg_type = DiscretizationAlgorithm
        default = MeanBinner()
    "--target", "-t"
        help = "target variable name"
        arg_type = Symbol
        required = true
    "--numsources", "-s"
        help = "number of source variables, must be between 1 and 5 (inclusive)"
        arg_type = Int
        nargs = '+'
        range_tester = x -> 0 < x < 5
        required = true
    "--verbose", "-v"
        help = "verbose status output"
        action = :store_true
end

@unpack input, algorithm, target, numsources, verbose = parse_args(s)

numsources = unique(sort(numsources))

function save(outdir::AbstractString, results::AbstractVector{Dict{Symbol,Any}}; verbose::Bool=true)
    verbose && @info "Saving results..." outdir

    for result in results
        if result[:input] != "whole"
            result[:input] = relpath(result[:input], datadir("sims"))
        end
        input = result[:input]
        algorithm = result[:algorithm]
        sources = join(string.(result[:sources]), "_")

        filename = savename(Dict(:input => first(splitext(basename(input))),
                                 :target => target,
                                 :algorithm => string(algorithm),
                                 :sources => sources), "bson")

        @tagsave joinpath(outdir, filename) result; safe=true
    end
end

const inputpath = datadir("sims", input)

if isfile(inputpath)
    outdir = datadir("results", dirname(input))

    for n in numsources
        verbose && @info "Number of sources: $n"
        results = gpid(inputpath, target, n; algo=algorithm, verbose=verbose)
        save(outdir, results; verbose=verbose)
    end
elseif isdir(inputpath)
    outdir = datadir("results", input)

    files = joinpath.(inputpath, readdir(inputpath))
    for n in numsources
        verbose && @info "Number of sources: $n"
        for input in files
            results = gpid(input, target, n; algo=algorithm, verbose=verbose)
            save(outdir, results; verbose=verbose)
        end

        whole = vcat(DataFrame.(CSV.File.(files; ignoreemptylines=true))...)
        results = gpid(whole, target, n; algo=algorithm, verbose=verbose)
        foreach(r -> r[:input] = "whole", results)
        save(outdir, results; verbose=verbose)
    end
else
    @error "Path is neither a file nor a directory" path=input
end
