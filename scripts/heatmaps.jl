using CSV, DataFrames, Distances, DrWatson, Statistics, StatsPlots, ProgressMeter

function plots(df, columns=[:μ, :pop, :psrecom, :gf])
    srcgroups = groupby(df, :sources)
    progress = Progress(length(srcgroups))
    combine(srcgroups) do srcgroup
        labels = map(x -> string(tuple(x...)), eachrow(unique(select(srcgroup, columns))))
        data = map(collect(groupby(srcgroup, :node))) do nodegroup
            pairwise(MeanAbsDeviation(), reshape(nodegroup.value, 10, nrow(nodegroup) ÷ 10))
        end |> mean
        for i in 1:size(data, 1), j in 1:size(data, 2)
            i > j && (data[i, j] = zero(data[i,j]))
        end
        p = heatmap(data, ticks=1:size(data,1), size=(500, 470), title="MAD - $(first(srcgroup.sources))", titleloc=:left)
        next!(progress)
        (plot=p, matrix=data, max=maximum(data))
    end
end

function savedata(dir, df)
    df = plots(df)

    mkpath(plotsdir(dir))

    @info "Saving plots"
    for row in eachrow(df)
        filename = joinpath(plotsdir(dir), replace(row.sources, ", " => "_") * ".png")
        savefig(row.plot, filename)
    end

    filename = datadir("results", join(reverse(splitpath(dir)), "_") * ".csv")
    @info "Saving maximum difference data to" filename
    CSV.write(filename, select(df, Not([:plot, :matrix])))
end

function main()
    @info "Loading data"
    df = vcat(DataFrame(CSV.File(datadir("results", "gen=10000", "csv", "alldata.csv"))),
              DataFrame(CSV.File(datadir("results", "gen=100000", "csv", "alldata.csv"))));
    df = df[df.payload .== "Pi", :]
    sort!(df, [:sources, :node, :gen, :psrecom, :pop, :gf, :μ, :replicate, :sampgen])

    gen10000 = df[df.gen .== 10000, :]
    gen100000 = df[df.gen .== 100000, :]

    dir = plotsdir("heatmaps")
    if isdir(dir)
        rm(dir; recursive=true)
    end

    @info "Generating heatmaps for" gen=10000
    dir = joinpath("heatmaps", "gen=10000")
    savedata(dir, gen10000)
    CSV.write(plotsdir(dir, "labels.csv"),
              unique(select(df, [:μ, :pop, :psrecom, :gf])))

    @info "Generating heatmaps for" gen=100000
    dir = joinpath("heatmaps", "gen=100000")
    df = filter(row -> row.replicate == 1, gen100000)
    savedata(dir, df)
    CSV.write(plotsdir(dir, "labels.csv"),
              unique(select(df, [:μ, :pop, :psrecom, :gf])))

    @info "Generating heatmaps for technical replicates"
    dir = joinpath("heatmaps", "replicates")
    replicates = unique(select(gen100000[gen100000.replicate .!= 1, :], [:μ, :pop, :psrecom, :gf]))
    df = join(gen100000, replicates, on=[:μ, :pop, :psrecom, :gf])
    savedata(dir, df)
    CSV.write(plotsdir(dir, "labels.csv"),
              unique(select(df, [:μ, :pop, :psrecom, :gf])))
end

main()
