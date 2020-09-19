using Dates, DrWatson

function takekeys(d, keys)
    ndict = Dict{Symbol,Any}()
    for k in keys
        from, to = if k isa Pair
            k
        elseif k isa AbstractString
            k, Symbol(k)
        else
            String(k), k
        end
        ndict[to] = d[from]
    end
    ndict
end
takekeys(d, keys...) = takekeys(d, keys)

foreach(readdir(datadir("sims"); join=true)) do from
    if occursin(r"\.csv$", from)
        _, params, _ = parse_savename(from; parsetypes=(Int, Float64, Date))
        params = takekeys(params,
            :date,
            "ps-recom" => :psrecom,
            "gfp1" => :gf,
            "mrnc" => :μ,
            "pop1" => :pop,
            :sampgen,
            :gen,
            :nsamp
        )
        base = savename(params, "csv";
            allowedtypes= (Real, String, Symbol, Date),
            digits = 3,
            scientific = 3
        )
        to = joinpath(dirname(from), base)
        mv(from, to)
    end
end
