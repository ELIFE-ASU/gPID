using CSV, DataFrames

function columns(input::String)
    df = CSV.read(input; ignoreemptylines=true)
    println("Columns in \"$input\":")
    foreach(n -> println("  • $n"), names(df))
end

function extract(input::String, typecol::Symbol, coding::String, noncoding::String, whole::String,
                 fields::AbstractArray{Symbol})
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
