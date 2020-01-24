using ArgParse, DataFrames, DrWatson, Parameters, Plots, Printf, StatsPlots

include(srcdir("gpid.jl"))

const s = ArgParseSettings(version="1.0", add_version=true)

@add_arg_table s begin
    "--input", "-i"
        help = "input file path"
        arg_type = String
        default = "results"
    "--outdir", "-o"
        help = "output directory for plots"
        arg_type = String
        default = "gpid"
    "--legend", "-l"
        help = "enable plot legends"
        action = :store_true
    "--ylabel", "-y"
        help = "label for the y-axis"
        arg_type = String
        default = "Partial Information (bits)"
end

@unpack input, outdir, legend, ylabel = parse_args(s)

const inputdir = datadir(input)
df = collect_results(inputdir; subfolders=true)
df[!,:simdir] = relpath.(dirname.(df[:,:path]), inputdir)

groups = groupby(df, [:simdir, :algorithm, :target, :sources])
for (key, group) in zip(keys(groups), groups)
    @unpack simdir, algorithm, target = key
    sources = join(string.(key.sources), "_")

    filename = savename(Dict(:target => target,
                             :algorithm => string(algorithm),
                             :sources => sources), "svg")
    filepath = projectdir("plots", outdir, simdir, filename)
    mkpath(dirname(filepath))

    Π = v -> payload(v).Π
    title = @sprintf "gPID (sources: %s)" join(string.(key.sources), " ")
    try
        gpidplot(group, Π; title=title, ylabel=ylabel, legend=legend)
        savefig(filepath)
    catch
        @error "plotting failed with :density mode; falling back to :uniform" target=target sources=key.sources
        gpidplot(group, Π; title=title, ylabel=ylabel, legend=legend, mode=:uniform)
        savefig(filepath)
    end
end
