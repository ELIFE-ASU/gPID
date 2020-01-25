using ArgParse, DrWatson, Parameters

include(srcdir("gpid.jl"))

const s = ArgParseSettings(version="1.0", add_version=true)

@add_arg_table s begin
    "--input", "-i"
        help = "input file path"
        arg_type = String
        default = ""
    "--verbose", "-v"
        help = "enable verbose output"
        action = :store_true
end

@unpack input, verbose = parse_args(s)

df = collect_results(datadir("results", input); subfolders=true)

for row in eachrow(df)
    @unpack input, algorithm, target = row
    sources = join(string.(row[:sources]), "_")

    filename = savename(Dict(:input => first(splitext(basename(input))),
                             :target => target,
                             :algorithm => string(algorithm),
                             :sources => sources), "svg")
    filepath = projectdir("plots", "lattice", dirname(input), filename)
    mkpath(dirname(filepath))

    verbose && @info "Writing lattice for" input algorithm target sources=row[:sources] to=filepath
    try
        graphviz(filepath, prune(row[:lattice]))
    catch
        @warn "Pruned lattice is empty; no figure generated"
    end
end
