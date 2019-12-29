using ArgParse

include("./src/jl/extract.jl")

ArgParse.parse_item(::Type{Symbol}, x::AbstractString) = Symbol(x)

s = ArgParseSettings("""
Extract columns a CSV file containing moving-window diversity measures on a genome.




Each region — coding and non-coding — will be extracted separately as will the whole genome.



The whole genome data will include a column signifying whether the window was in a coding (1) or non-coding (0) region.
""",
version="1.0",
add_version = true)

@add_arg_table s begin
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
        nargs = '*'
end

add_arg_group(s, "output files")

@add_arg_table s begin
    "--whole", "-w"
        help = "the filename to which to output whole genome data"
        arg_type = String
        default = "whole.csv"
    "--coding", "-c"
        help = "the filename to which to output coding region data"
        arg_type = String
        default = "coding.csv"
    "--noncoding", "-n"
        help = "the filename to which to output non-coding region data"
        arg_type = String
        default = "noncoding.csv"
end

try
    args = parse_args(s)
    extract(args["filename"], args["typecol"], args["coding"], args["noncoding"], args["whole"], args["columns"])
catch e
    println(e)
    exit(1)
end
