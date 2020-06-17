using ArgParse, DrWatson, Parameters, Plots, Printf, StatsPlots

include(srcdir("gpid.jl"))

function gpidplots(df, field; legend=false, verbose=true)
    ylabel = field == :Π ? "Partial Information (bits)" :
             field == :Iₘᵢₙ ? "Imin (bits)" :
             throw(ArgumentError("payload field must be either :Π or :Iₘᵢₙ; got $field"))

    groups = groupby(df, [:simdir, :algorithm, :target, :sources])
    for (key, group) in zip(keys(groups), groups)
        @unpack simdir, algorithm, target, sources = key

        filename = savename(Dict(:target => target,
                                 :algorithm => string(algorithm),
                                 :sources => join(string.(sources), "_")), "svg")
        filepath = projectdir("plots", "gpid", simdir, string(field), filename)
        mkpath(dirname(filepath))

        verbose && @info "Plotting pid for" simdir algorithm target sources

        title = @sprintf "gPID (sources: %s)" join(string.(sources), " ")
        try
            gpidplot(group, field; title=title, ylabel=ylabel, legend=legend)
            savefig(filepath)
        catch
            verbose && @error "plotting failed with :density mode; falling back to :uniform"
            !verbose && @error "plotting failed with :density mode; falling back to :uniform" target sources
            gpidplot(group, field; title=title, ylabel=ylabel, legend=legend, mode=:uniform)
            savefig(filepath)
        end
    end
end

function lattices(df; verbose=true)
    for row in eachrow(df)
        @unpack simdir, input, algorithm, target, sources, lattice = row

        filename = savename(Dict(:input => first(splitext(input)),
                                 :target => target,
                                 :algorithm => string(algorithm),
                                 :sources => join(string.(sources), "_")), "svg")
        filepath = projectdir("plots", "lattice", simdir, filename)
        mkpath(dirname(filepath))

        verbose && @info "Writing lattice for" simdir input algorithm target sources to=filepath
        try
            graphviz(filepath, prune(lattice))
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

    add_arg_group!(s, "Input and Output")
    @add_arg_table s begin
        "--input", "-i"
            help = "input file path"
            arg_type = String
            default = ""
    end

    add_arg_group!(s, "Lattice Settings")
    @add_arg_table s begin
        "--no-lattice"
            help = "skip lattice plots"
            dest_name = "nolattice"
            action = :store_true
    end

    add_arg_group!(s, "gPID Plot Settings")
    @add_arg_table s begin
        "--no-gpid"
            help = "skip all gPID plots (implies --no-pi and --no-imin)"
            dest_name = "nogpid"
            action = :store_true
        "--no-pi"
            help = "skip Π plot"
            dest_name = "noΠ"
            action = :store_true
        "--no-imin"
            help = "skip Iₘᵢₙ plot"
            dest_name = "noIₘᵢₙ"
            action = :store_true
        "--legend", "-l"
            help = "enable plot legends"
            action = :store_true
    end

    @unpack input, nolattice, nogpid, noΠ, noIₘᵢₙ, legend, verbose = parse_args(s)

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
        if !noΠ
            verbose && @info "Generating Π plots"
            gpidplots(df, :Π; legend=legend, verbose=verbose)
        end
        if !noIₘᵢₙ
            verbose && @info "Generating Iₘᵢₙ plots"
            gpidplots(df, :Iₘᵢₙ; legend=legend, verbose=verbose)
        end
    end
end

main()
