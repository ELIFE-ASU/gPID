using CSV, DataFrames, Dates, Clustering, StatsPlots, Printf, DrWatson, StatsBase

iscsv(f) = occursin(r"\.csv$", f)

function loaddata()
	filepaths = filter(iscsv, readdir(datadir("results", "csv"); join=true))
	
	dfs = filepaths .|> CSV.File .|> DataFrame
	
	foreach(dfs) do df
		filter!(r -> r.payload == "Pi", df)
	end

	dfs
end

sources(df) = sort(collect(Set(vcat(split.(replace.(string.(names(df)[8:end]), r"[:,{}\[\]]" => ""))...))))

function prepare(dfs; shift=true)
	data = nothing
	column_info = Vector{Any}[]
	param_order = [:date, :psrecom, :pop, :gf, :μ, :payload]
	for (i, df) in enumerate(dfs)
		allsources = "[" * join(sources(df), ", ") * "]"
		for group in groupby(df, param_order)
			sorted_group = sort(group, :sampgen)
			payloads = select(sorted_group, Not([:sampgen; param_order]))
			for name in names(payloads)
				push!(column_info, [Array(group[1, param_order]); allsources; String(name)])
			end
			new_columns = Array{Float64}(payloads)
			shift && (new_columns .-= transpose(new_columns[1,:]))
			data = isnothing(data) ? new_columns : hcat(data, new_columns)
		end
	end
	data, column_info, param_order
end

function cluster(data, k=2, epsilon = 0.01)
	clusters = kmeans(data, k)
	while maximum(clusters.costs) > epsilon
		clusters = kmeans(data, k += 1)
	end
	clusters
end

function saveclusters(data, column_info, param_order, clusters)
	today = Dates.format(now(), "Y-mm-ddTHHMMSS")
	if !isdir(plotsdir("classes", today))
		mkpath(plotsdir("classes", today))
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
		savefig(p, plotsdir("classes", today, (@sprintf "class_%02d.png" i)))
		push!(subplots, p)
	end

	p = plot(subplots..., size=(4200, 3600))
	savefig(p, plotsdir("classes", today, "clusters.png"))

	if !isdir(datadir("results", "classes", today))
		mkpath(datadir("results", "classes", today))
	end
	for i in 1:length(clusters.counts)
		members = column_info[clusters.assignments .== 1]
		df = DataFrame([
			Date;
			fill(Float64, length(param_order) - 2);
			String;
			String;
			String
		], [
			param_order;
			:allsources;
			:node
		])
		foreach(member -> push!(df, member), members)
		CSV.write(datadir("results", "classes", today, (@sprintf "class_%02d.csv" i)), df)
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

function runall()
	@info "Loading data"
	dfs = loaddata()

	@info "Constructing matrix"
	data = prepare(dfs)

	@info "Identifying fine-scale clusters"
	clusters = cluster(data[1])

	@info "Saving plots and CSVs"
	saveclusters(data..., clusters)

	@info "Identifying coarse-scale clusters"
	clusters = optimallycluster(data[1])

	@info "Saving plots and CSVs"
	saveclusters(data..., clusters)
end
