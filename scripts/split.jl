using CSV, DataFrames, DrWatson

function main()
    files = filter(f -> occursin(r"\.csv$", f), readdir(datadir("sims"); join=true))
    dfs = Dict{String,DataFrame}()
    for filename in files
        params = parse_savename(filename; parsetypes=(Int,Float64,Date))[2]
        name = joinpath(
            dirname(filename),
            savename(
                params,
                "csv";
                allowedtypes= (Real, String, Symbol, Date),
                digits = 3,
                scientific = 3
            )
        )
        df = DataFrame(CSV.File(filename))
    end
end

main()
