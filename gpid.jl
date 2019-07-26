using ArgParse

include("./src/jl/gpid.jl")

ArgParse.parse_item(::Type{Symbol}, x::AbstractString) = Symbol(x)

const rootdir = pwd()

const s = ArgParseSettings(version="1.0", add_version = true)

@add_arg_table s begin
    "--gpid", "-g"
        help = "the path to the gpid executable"
        arg_type = String
        default = joinpath(rootdir, "bin", "gpid")
    "--filename", "-i"
        help = "the composite file of diversity measurements"
        arg_type = String
        required = true
    "--typecol", "-t"
        help = "the column name containing the region type"
        arg_type = Symbol
        default = Symbol("Region-type")
    "columns"
        help = "the columns to extract. If none are provided, all the the column names in the file will be printed to standard output."
        arg_type = Symbol
        nargs = '+'
        required = true
end

args = parse_args(s)

function main(; verbose=false)
    args = parse_args(s)

    filenames = Filenames(args["filename"])
    try
        status("Removing any previous analyses", verbose)
        rm(filenames)
        mkdir(filenames)

        status("Extracting files from $(filenames.input)...", verbose)
        extract(filenames, args["typecol"], args["columns"])
        gpid(args["gpid"], filenames; verbose=verbose)
    catch e
        println(e)
        status("Removing failed analysis...", verbose)
        rm(filenames)
        exit(1)
    end
end
main(; verbose=true)
