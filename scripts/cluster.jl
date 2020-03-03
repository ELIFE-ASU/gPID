using Clustering, DrWatson, DataFrames, Discretizers, Eolas, Parameters

function getdata(dir)
    df = collect_results(datadir("results", "2020-01-05", dir))
    filter!(r -> length(r.sources) == 4, df)
    sort!(df, (:sources, :input))
    data = Array{Float64}(undef, length(df.lattice[1].vertices), size(df, 1))
    for (i, row) in enumerate(eachrow(df))
        data[:, i] = map(v -> payload(v).Π, row.lattice.vertices)
    end
    df.sources, data
end

function main()
    sources, dsdata = getdata("ds")
    data = hcat(dsdata, last(getdata("ps")), last(getdata("ns")), last(getdata("ps-ds")))
    @unpack assignments = kmeans(data, 4)

    sources, data, assignments
    #  stride = size(data, 2) ÷ 4
    #  ds = assignments[1:stride]
    #  ps = assignments[1+stride:2stride]
    #  ns = assignments[1+2stride:3stride]
    #  psds = assignments[1+3stride:4stride]

    #  consistent = Int[]
    #  for i in 1:stride
    #      if length(Set([ds[i], ps[i], ns[i], psds[i]])) == 4
    #          push!(consistent, i)
    #          println(sources[i])
    #      end
    #  end
    #  println(length(consistent))
end
