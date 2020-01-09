using DrWatson, CSV, Base.Meta

include(srcdir("gpid.jl"))

df = CSV.read(ARGS[1])
bin!(df; algo=eval(Meta.parse(ARGS[2])), replace=true)
results = pid(WilliamsBeer, df, ARGS[3], parse(Int, ARGS[4]))
for (vars, lattice) in results
    println(vars, " ", length(lattice))
end
