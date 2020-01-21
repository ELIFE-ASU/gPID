using ArgParse, DataFrames, DrWatson, Discretizers, Eolas, Parameters

const s = ArgParseSettings(version="1.0", add_version=true)

@add_arg_table s begin
    "--input", "-i"
        help = "input file path"
        arg_type = String
        required = true
end

@unpack input = parse_args(s)

const inputdir = datadir(input)

df = collect_results(inputdir; subfolders=true)
for row in eachrow(df)
    @unpack input, algorithm, target = row
    sources = join(string.(row[:sources]), "_")

    filename = savename(Dict(:input => first(splitext(basename(input))),
                             :target => target,
                             :algorithm => string(algorithm),
                             :sources => sources), "svg")
    filepath = projectdir("plots", "lattice", relpath(dirname(row[:path]), inputdir), filename)
    mkpath(dirname(filepath))

    graphviz(filepath, prune(row[:lattice]))
end
