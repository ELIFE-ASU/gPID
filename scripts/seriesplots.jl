using CSV, DataFrames, DrWatson, ProgressMeter, StatsPlots

pyplot()

dir = plotsdir("series")
if isdir(dir)
    rm(dir; recursive=true)
end

dir = plotsdir("series", "all")
mkpath(dir)

df = vcat(DataFrame(CSV.File(datadir("results", "gen=10000", "csv", "alldata.csv"))),
          DataFrame(CSV.File(datadir("results", "gen=100000", "csv", "alldata.csv"))))
df = df[(df.replicate .== 1.0) .& (df.payload .== "Pi"), :]
sort!(df, [:sources, :node, :μ, :pop, :psrecom, :gf, :gen, :sampgen])

plotdata = collect(groupby(df, [:sources, :node]))
@showprogress for pd in plotdata
    sources, node = string(first(pd.sources)), string(first(pd.node))
    title = "Sources: $sources\nNode: $node"
    p = @df pd plot(:sampgen, :value, group=(:psrecom, :gf, :pop, :μ),
                     xlim=(1000, 100000), ylim=(0, 1),
                     title=title, titlepos=:left,
                     xlabel="generation", ylabel="Π",
                     legend=:outertopright, legendtitle="RR, GF, Nₑ, μ",
                     size=(800,500))
    vline!(p, [10000], style=:dash, color=:gray, label="")
    basename = replace(replace("$sources - $node", " " => ""), "," => "_") * ".png"
    filename = joinpath(dir, basename)
    savefig(p, filename)
end

dir = plotsdir("series", "extreme")
mkpath(dir)

plotdata = filter(g -> maximum(g.value) ≥ 0.05, plotdata)
@showprogress for pd in plotdata
    sources, node = string(first(pd.sources)), string(first(pd.node))
    title = "Sources: $sources\nNode: $node"
    p = @df pd plot(:sampgen, :value, group=(:psrecom, :gf, :pop, :μ),
                     xlim=(1000, 100000), ylim=(0, 1),
                     title=title, titlepos=:left,
                     xlabel="generation", ylabel="Π",
                     legend=:outertopright, legendtitle="RR, GF, Nₑ, μ",
                     size=(800,500))
    vline!(p, [10000], style=:dash, color=:gray, label="")
    basename = replace(replace("$sources - $node", " " => ""), "," => "_") * ".png"
    filename = joinpath(dir, basename)
    savefig(p, filename)
end
