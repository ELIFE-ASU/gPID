using ArgParse, CSV, DataFrames, Dates, DrWatson

const s = ArgParseSettings(version="1.0", add_version=true)

@add_arg_table! s begin
    "--rowspersim", "-r"
        help = "Number of rows in a sequence to collect as a simulation"
        arg_type = Int
        default = 20
    "--simsperrep", "-s"
        help = "Number of simulations per replicate"
        arg_type = Int
        default = 100
end

function csvname(params)
    savename(params, "csv"; allowedtypes= (Real, String, Symbol, Date), digits = 3, scientific = 3)
end

function main(rowspersim, simsperrep)
    rowsperrep = rowspersim * simsperrep
    dir = datadir("sims")

    files = filter(f -> occursin(r"\.csv$", f), readdir(dir; join=true))

    dfs = Dict{String,DataFrame}()
    for filename in files
        params = delete!(parse_savename(filename; parsetypes=(Int, Float64, Date))[2], "date")
        name = csvname(params)

        df = DataFrame(CSV.File(filename; silencewarnings=true))

        dfs[name] = haskey(dfs, name) ? vcat(dfs[name], df) : df

        rm(filename)
    end

    for (name, df) in dfs
        params = parse_savename(name; parsetypes=(Int, Float64, Date))[2]

        cols = names(df)
        df.sim = ((collect(1:nrow(df)) .- 1) .÷ rowspersim) .+ 1
        select!(df, ["sim"; cols])

        rep = 1
        while rep * rowsperrep ≤ nrow(df)
            params["replicate"] = rep
            rows = (1:rowsperrep) .+ ((rep - 1) * rowsperrep)
            gf = dropmissing(df[rows, :])
            filename = joinpath(dir, csvname(params))
            CSV.write(filename, gf)
            rep +=1
        end
    end
end

let
    @unpack rowspersim, simsperrep = parse_args(s)
    main(rowspersim, simsperrep)
end
