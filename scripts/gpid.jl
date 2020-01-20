using ArgParse, Base.Meta, DrWatson, CSV, Printf

include(srcdir("gpid.jl"))

function validbinner(ex::Expr)
    algorithm = try
        eval(ex)
    catch MethodError
        false
    end
    isa(algorithm, DiscretizationAlgorithm)
end

ArgParse.parse_item(::Type{Symbol}, x::AbstractString) = Symbol(x)
ArgParse.parse_item(::Type{Expr}, x::AbstractString) = Meta.parse(x)

const s = ArgParseSettings(version="1.0", add_version=true)

@add_arg_table s begin
    "--input", "-i"
        help = "input file path"
        arg_type = String
        range_tester = ispath
        required = true
    "--output", "-o"
        help = "output directory"
        arg_type = String
        required = true
    "--algorithm", "-a"
        help = "binning algorithm"
        arg_type = Expr
        range_tester = validbinner
        default = :(MeanBinner())
    "--target", "-t"
        help = "target variable name"
        arg_type = Symbol
        required = true
    "--numsources", "-s"
        help = "number of source variables, must be between 1 and 5 (inclusive)"
        arg_type = Int
        range_tester = x -> 0 < x < 5
        required = true
end

args = parse_args(s)

function processfile(input::AbstractString,
                     output::AbstractString,
                     algo::DiscretizationAlgorithm,
                     target::Symbol,
                     numsources::Int)
    @info "Reading..." file=input
    df = CSV.read(input)

    @info "Binning data..."
    bin!(df; algo=algo, replace=true)

    @info "Computing information decompositions..."
    results = pid(WilliamsBeer, df, target, numsources)

    @info "Saving results..." outdir=datadir(output)
    for result in results
        sources = join(string.(result[:sources]), "_")
        filename = savename(Dict(:input => first(splitext(basename(input))),
                                 :target => target,
                                 :sources => sources), "bson")

        result[:input] = input
        wsave(datadir(args["output"], filename), result)
    end
end

if isfile(args["input"])
    processfile(args["input"], args["output"],
                eval(args["algorithm"]),
                args["target"], args["numsources"])
else
    @error "Path is not a file; cannot process yet" path=args["input"]
end
