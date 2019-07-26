import Base.Filesystem: rm, mkdir
using CSV, DataFrames, Base.Filesystem

status(message, verbose=true) = if verbose
    @info message
end

struct Filenames
    input::String
    coding::String
    noncoding::String
    whole::String

    function Filenames(input::String)
        new(input,
            joinpath(dirname(input), "coding", basename(input)),
            joinpath(dirname(input), "noncoding", basename(input)),
            joinpath(dirname(input), "whole", basename(input))
        )
    end
end

flags(fs::Filenames) = ["-i", fs.input, "-c", fs.coding, "-n", fs.noncoding, "-w", fs.whole]

function rm(fs::Filenames)
    rm(dirname(fs.coding); force=true, recursive=true)
    rm(dirname(fs.noncoding); force=true, recursive=true)
    rm(dirname(fs.whole); force=true, recursive=true)
end

function mkdir(fs::Filenames)
    mkpath(dirname(fs.coding))
    mkpath(dirname(fs.noncoding))
    mkpath(dirname(fs.whole))
end

function gpid(pidexe::String, filepath::String; verbose=false)
    cd(dirname(filepath))
    status("Computing PID for $filepath...", verbose)
    proc = run(pipeline(`$pidexe $(basename(filepath)) 2`, stdout="summary.dat"))
    cd(rootdir)
    proc
end

function gpid(pidexe::String, fs::Filenames; verbose=false)
    gpid(pidexe, fs.coding; verbose=verbose)
    gpid(pidexe, fs.noncoding; verbose=verbose)
    gpid(pidexe, fs.whole; verbose=verbose)
end

function columns(input::String)
    df = CSV.read(input; ignoreemptylines=true)
    println("Columns in \"$input)\":")
    foreach(n -> println("  • $(n)"), names(df))
end

function extract(input::String, typecol::Symbol, coding::String, noncoding::String, whole::String, fields::AbstractArray{Symbol})
    if isempty(fields)
        columns(input)
    else
        df = CSV.read(input; ignoreemptylines=true)
        df[!, :iscoding] = Int64.(df[:, typecol] .== "cod")

        for g in groupby(df, :iscoding)
            outname = if g[1, :iscoding] == 1
                coding
            else
                noncoding
            end

            CSV.write(outname, g[:, [fields...]])
        end

        CSV.write(whole, df[:, [fields..., :iscoding]])
    end
end

function extract(fs::Filenames, typecol::Symbol, fields::AbstractArray{Symbol})
    extract(fs.input, typecol, fs.coding, fs.noncoding, fs.whole, fields)
end
