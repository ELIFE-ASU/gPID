using ArgParse, DrWatson, Parameters, Plots, Printf, StatsPlots

include(srcdir("gpid.jl"))

function gpidplots(df, ylabel, legend; verbose=true)
    groups = groupby(df, [:input, :algorithm, :target, :sources])
    for (key, group) in zip(keys(groups), groups)
        @unpack input, algorithm, target = key
        sources = join(string.(key.sources), "_")

        filename = savename(Dict(:target => target,
                                 :algorithm => string(algorithm),
                                 :sources => sources), "svg")
        filepath = projectdir("plots", "gpid", dirname(input), filename)
        mkpath(dirname(filepath))

        verbose && @info "Plotting pid for" sim=dirname(input) algorithm target sources=key.sources

        Π = v -> payload(v).Π
        title = @sprintf "gPID (sources: %s)" join(string.(key.sources), " ")
        try
            gpidplot(group, Π; title=title, ylabel=ylabel, legend=legend)
            savefig(filepath)
        catch
            verbose && @error "plotting failed with :density mode; falling back to :uniform"
            !verbose && @error "plotting failed with :density mode; falling back to :uniform" target=target sources=key.sources
            gpidplot(group, Π; title=title, ylabel=ylabel, legend=legend, mode=:uniform)
            savefig(filepath)
        end
    end
end

function lattices(df; verbose=true)
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
end

function main()
    s = ArgParseSettings(version="1.0", add_version=true)

    @add_arg_table s begin
        "--verbose", "-v"
            help = "enable verbose output"
            action = :store_true
    end

    add_arg_group(s, "Input and Output")
    @add_arg_table s begin
        "--input", "-i"
            help = "input file path"
            arg_type = String
            default = ""
    end

    add_arg_group(s, "Lattice Settings")
    @add_arg_table s begin
        "--no-lattice"
            help = "skip lattice plots"
            dest_name = "nolattice"
            action = :store_true
    end

    add_arg_group(s, "gPID Plot Settings")
    @add_arg_table s begin
        "--no-gpid"
            help = "skip gPID plots"
            dest_name = "nogpid"
            action = :store_true
        "--legend", "-l"
            help = "enable plot legends"
            action = :store_true
        "--ylabel", "-y"
            help = "label for the y-axis"
            arg_type = String
            default = "Partial Information (bits)"
    end

    @unpack input, nolattice, nogpid, legend, ylabel, verbose = parse_args(s)

    if nolattice && nogpid
        @warn "Both --no-lattice and --no-gpid provided; no plots generated"
        exit(1)
    end
    df = collect_results(datadir("results", input); subfolders=true)

    if !nolattice
        verbose && @info "Generating lattices"
        lattices(df; verbose=verbose)
    end

    if !nogpid
        verbose && @info "Generating plots"
        gpidplots(df, ylabel, legend; verbose=verbose)
    end
end

main()
