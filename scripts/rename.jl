using Dates, DrWatson

foreach(readdir(datadir("sims"); join=true)) do from
    if occursin(r"\.csv$", from)
        _, params, _ = parse_savename(from; parsetypes=(Int, Float64, Date))
        base = savename(params, "csv";
            allowedtypes= (Real, String, Symbol, Date),
            digits = 3,
            scientific = 3
        )
        to = joinpath(dirname(from), base)
        @info "Moving" from to
        mv(from, to)
    end
end
