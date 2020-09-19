using ArgParse, CSV, DataFrames, Dates, Clustering, StatsPlots, Printf, DrWatson, StatsBase

s = ArgParseSettings(version="1.0", add_version=true)

@add_arg_table! s begin
    "--gen", "-g"
    help = "The number of generations for the data to be clustered"
    arg_type = Int
    required = true
    "--prefix", "-p"
    help = "Prepend a zero-value to each series"
    action = :store_true
end

iscsv(f) = occursin(r"\.csv$", f)

ENV["GKSwstype"] = "png"

function loaddata(gen)
    df = DataFrame(CSV.File(datadir("results", "gen=$gen", "csv", "alldata.csv")))
    filter!(r -> r.payload == "Pi" && r.replicate == 1.0, df)
    select!(df, Not([:payload]))
    sort!(df, [:replicate, :psrecom, :pop, :gf, :μ, :sources, :node, :sampgen])
end

function prepare(df; shift=true, prefix=false)
    data = reshape(df.value, 10, nrow(df) ÷ 10)
    if prefix
        data = [zeros(eltype(data), 1, size(data,2)); data]
    end
    !shift ? data : data .- reshape(data[1,:], 1, size(data,2))
end

function cluster(data, k=2, epsilon = 0.01)
    clusters = kmeans(data, k)
    while maximum(clusters.costs) > epsilon
        clusters = kmeans(data, k += 1)
    end
    clusters
end

function saveclusters(df, data, clusters, gen)
    k = size(clusters.centers, 2)

    pdir = plotsdir("gen=$gen", "classes", "k=$k")
    if !isdir(pdir)
        mkpath(pdir)
    end

    a, b = extrema(data)
    subplots = []
    for i in 1:length(clusters.counts)
        cluster = data[:, clusters.assignments .== i]
        lower_bound = clusters.centers[:, i] - minimum(cluster, dims=2)
        upper_bound = maximum(cluster, dims=2) - clusters.centers[:, i]
        p = plot(clusters.centers[:, i],
                 ribbon=(lower_bound, upper_bound),
                 linewidth=3, color=:gray, legend=false,
                 xlim=(1, size(cluster, 1)), ylim=(a - 0.1, b + 0.1),
                 title="Class $i ($(size(cluster, 2)) Members)", ylabel="ΔPi")
        savefig(p, joinpath(pdir, (@sprintf "class_%02d.png" i)))
        push!(subplots, p)
    end

    p = plot(subplots..., size=(4200, 3600))
    savefig(p, joinpath(pdir, "clusters.png"))

    rdir = datadir("results", "gen=$gen", "classes", "k=$k")
    if !isdir(rdir)
        mkpath(rdir)
    end

    df = select(df, Not([:sampgen, :value]))
    unique!(df)
    for i in 1:length(clusters.counts)
        gf = df[clusters.assignments .== i, :]
        CSV.write(joinpath(rdir, (@sprintf "class_%02d.csv" i)), gf)
    end
end

function optimallycluster(data; k=2, epsilon=0.05, n=100)
    clusters = kmeans(data, k)
    totalcost = clusters.totalcost
    maxcost = maximum(clusters.costs)

    while maxcost > epsilon
        for i in 1:n
            new_clusters = kmeans(data, k)
            new_totalcost = new_clusters.totalcost
            new_maxcost = maximum(new_clusters.costs)

            if totalcost > new_totalcost || (totalcost == new_totalcost && maxcost > new_maxcost)
                clusters = new_clusters
                totalcost = new_totalcost
                maxcost = new_maxcost
            end
        end
        k += 1
    end
    clusters
end

function main()
    @unpack gen, prefix = parse_args(s)

    @info "Loading data"
    df = loaddata(gen)

    @info "Constructing matrix"
    data = prepare(df; shift=true, prefix=prefix)

    @info "Identifying fine-scale clusters"
    clusters = cluster(data)

    @info "Saving plots and CSVs"
    saveclusters(df, data, clusters, gen)

    @info "Identifying coarse-scale clusters"
    clusters = optimallycluster(data)

    @info "Saving plots and CSVs"
    saveclusters(df, data, clusters, gen)
end

main()
