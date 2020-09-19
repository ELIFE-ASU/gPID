using ArgParse, DrWatson

const JULIA = `julia --project=$(projectdir())`
const EXTRACT = `elvish $(scriptsdir("extract.elv"))`
const RENAME = `$JULIA $(scriptsdir("rename.jl"))`
const COMBINE = `$JULIA $(scriptsdir("combine.jl"))`

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

function main()
    @unpack rowspersim, simsperrep = parse_args(s)

    @info "Removing CSV files"
    csvs = filter(f -> occursin(r".csv$", f), readdir(datadir("sims"); join=true))
    rm.(csvs)

    @info "Extracting CSVs"
    run(pipeline(EXTRACT; stdout=devnull))

    @info "Renaming CSVs"
    run(pipeline(RENAME; stdout=devnull))

    @info "Combining and Splitting CSVs"
    run(pipeline(`$COMBINE -r $rowspersim -s $simsperrep`; stdout=devnull))
end

main()
