### A Pluto.jl notebook ###
# v0.12.9

using Markdown
using InteractiveUtils

# ╔═╡ b9fc2d30-1ad0-11eb-3cb8-758bc8de6ccd
using DrWatson, DataFrames, CSV, StatsPlots, GLM, Query, CategoricalArrays, ROCAnalysis, Printf, Statistics, ColorSchemes, GZip

# ╔═╡ eb381864-1b0c-11eb-0a16-c9ef7834003b
gr(; fmt=:png)

# ╔═╡ 3b8d17a0-1ec4-11eb-0add-c9ae29859db4
α(r::Roc) = 2abs(AUC(r) - 0.5)

# ╔═╡ b55344da-1aee-11eb-3cc7-673f1b837c05
md"""
# Classification Based on Partial Information
"""

# ╔═╡ 854e91ee-1ad1-11eb-0d78-a77acb4ef0de
alldata = datadir("results", "csv", "Fst_Dxy_Pi.csv.gz") |> GZip.open |> CSV.File |> DataFrame;

# ╔═╡ f8d36116-1b0b-11eb-1a68-89ae2e024067
md"""
## Classification Based on π in `{π}`
"""

# ╔═╡ 0a8e50f8-1b0c-11eb-1158-9769b51edc0c
begin
	pi_only = alldata |>
		@filter(_.sources == "Pi") |>
		@filter(_.payload == "Pi") |>
		@filter(_.node == "[:Pi]") |>
		@select(-:replicate, -:nsamp, -:payload, -:sources) |>
		DataFrame;
	disallowmissing!(pi_only)
end

# ╔═╡ f1aa792e-2af4-11eb-006e-ff1082d96834
@df pi_only scatter(:gf, :value, legend=nothing)

# ╔═╡ a24253ae-1ec7-11eb-3b68-5b46f723e9da
let
	plot([0,1], [0,1], style=:dash, color=:gray, label="", linewidth=2)
	for timestep in pi_only |> @groupby(_.sampgen)
		model = glm(@formula(gf ~ value), timestep, Binomial(), ProbitLink())
		scores = Array{Float64}(predict(model, timestep))
		r = roc(scores[timestep.gf .!= 0], scores[timestep.gf .== 0])
		auclabel = @sprintf "%0.3f" AUC(r)
		plot!(r, traditional=true,
			linewidth=3,
			α=α(r),
			label="t = $(timestep.sampgen[1]); AUC = $auclabel")
	end	
	plot!(title="Gene Flow ROC",
		xlabel="False Positive Rate",
		ylabel="True Positive Rate")
	plot!(grid=false)
	plot!(legendfontsize=6, legend=:bottomright, aspect_ratio=1.0, size=(600,600))
end

# ╔═╡ f54a21e4-1aee-11eb-333d-e5d3ee0424f2
md"""
## Classification Based on π in `{Dxy, Fst, π}`
"""

# ╔═╡ a98b4418-1ec7-11eb-08e2-e350416a8efd
begin
	dxy_fst_pi = alldata |>
		@filter(_.sources == "Dxy, Fst, Pi") |>
		@filter(_.replicate == 1) |>
		@filter(_.payload == "Pi") |>
		@select(-:replicate, -:nsamp, -:payload, -:sources) |>
		DataFrame;
	disallowmissing!(dxy_fst_pi)
end;

# ╔═╡ a8b44524-1ad5-11eb-365a-519261dadbcf
dxy_fst_pi_only = dxy_fst_pi |>
	@filter(_.node == "[:Pi]") |>
	@groupby(_.sampgen);

# ╔═╡ 5fb6dde4-2af6-11eb-398b-dbb3c0694a15
nrows(dxy_fst_pi_only)

# ╔═╡ 1f62a614-1ad5-11eb-17ed-cb3d93b9c1d5
π_gf = let
	plot([0,1], [0,1], style=:dash, color=:gray, label="", linewidth=2)
	for timestep in dxy_fst_pi_only
		model = glm(@formula(gf ~ value), timestep, Binomial(), ProbitLink())
		scores = Array{Float64}(predict(model, timestep))
		r = roc(scores[timestep.gf .!= 0], scores[timestep.gf .== 0])
		auclabel = @sprintf "%0.3f" AUC(r)
		plot!(r, traditional=true,
			linewidth=3,
			α=α(r),
			label="t = $(timestep.sampgen[1]); AUC = $auclabel")
	end	
	plot!(title="Gene Flow ROC",
		xlabel="False Positive Rate",
		ylabel="True Positive Rate")
	plot!(grid=false)
	plot!(legendfontsize=6, legend=:bottomright, aspect_ratio=1.0, size=(600,600))
end

# ╔═╡ cb2c9f86-2449-11eb-1aba-13c0ce4c02d5
savefig(π_gf, plotsdir("pi_gf_roc.pdf"))

# ╔═╡ d0183666-1ae1-11eb-3906-3d5c3dff2416
π_μ_plot = let 
	plot([0,1], [0,1], style=:dash, color=:gray, label="", linewidth=2)
	for timestep in dxy_fst_pi_only
		model = glm(@formula(μ ~ value), timestep, Binomial(), ProbitLink())
		scores = Array{Float64}(predict(model, timestep))
		r = roc(scores[timestep.μ .!= 2.5e-7], scores[timestep.μ .== 2.5e-7])
		auclabel = @sprintf "%0.3f" AUC(r)
		plot!(r, traditional=true,
			linewidth=3,
			α=α(r),
			label="t = $(timestep.sampgen[1]); AUC = $auclabel")
	end
	plot!(title="Mutation Rate ROC",
		xlabel="False Positive Rate",
		ylabel="True Positive Rate")
	plot!(grid=false)
	plot!(legendfontsize=6, legend=:bottomright)
	plot!(size=(600,600))
end

# ╔═╡ 0345fbd8-244a-11eb-07a4-edb72c024cfe
savefig(π_μ_plot, plotsdir("pi_mutation_rate_roc.pdf"))

# ╔═╡ 8ca59556-1ae4-11eb-138d-e7722b885477
π_pop_plot = let 
	plot()
	plot!([0,1], [0,1], style=:dash, color=:gray, label="", linewidth=2)
	for timestep in dxy_fst_pi_only
		model = glm(@formula(pop ~ value), timestep, Normal(), IdentityLink())
		scores = Array{Float64}(predict(model, timestep))
		r = roc(scores[timestep.pop .== 1000], scores[timestep.pop .!= 1000])
		auclabel = @sprintf "%0.3f" AUC(r)
		plot!(r, traditional=true,
			linewidth=3,
			α=α(r),
			label="t = $(timestep.sampgen[1]); AUC = $auclabel")
	end
	plot!(title="Effective Population Size ROC",
		xlabel="False Positive Rate",
		ylabel="True Positive Rate")
	plot!(legendfontsize=6, legend=:bottomright)
	plot!(grid=false)
	plot!(size=(600,600))
end

# ╔═╡ 2a03a5e0-244a-11eb-27cb-cf01e0e722cc
savefig(π_pop_plot, plotsdir("pi_pop_roc.pdf"))

# ╔═╡ 54bf559e-1af0-11eb-38a9-2d4b0cf6434f
md"""
# Classification Based on Values of π
"""

# ╔═╡ d5931aee-1af9-11eb-2aa0-cb3a489049fe
simfiles = filter(f -> occursin(r"\.csv$", f), readdir(datadir("sims"); join=true))

# ╔═╡ 51298bc6-1af9-11eb-163e-0f37eed3f00a
begin
	df = DataFrame(μ = Float64[], gen = Int[], pop=Int[], sampgen = Int[], psrecom = Float64[], gf = Float64[], replicate=Int[], sim = Int[], Pi = Float64[], Region=String[])
	for fname in simfiles
		params = parse_savename(fname; parsetypes=(Int, Float64))[2]
		@unpack μ, gen, pop, sampgen, psrecom, gf, replicate = params;
		uf = select(DataFrame(CSV.File(fname)), :sim, :Pi, :Region)
		uf[:,:μ] = μ
		uf[:,:gen] = gen
		uf[:,:pop] = pop
		uf[:,:sampgen] = sampgen
		uf[:,:psrecom] = psrecom
		uf[:,:gf] = gf
		uf[:,:replicate] = replicate

		global df = vcat(df, uf)
	end
end

# ╔═╡ d61d5d0c-1b09-11eb-2020-e552b6dbd846
function coding_noncoding_summary(df, cols)
	combine(groupby(df, cols)) do group
		coding = mean(group[group.Region .== "coding", :Pi])
		noncoding = mean(group[group.Region .== "noncoding", :Pi])
		(; coding, noncoding)
	end
end

# ╔═╡ bedbbc7e-1aff-11eb-38de-55ba55e27287
pi_data = let cols = [:μ, :gen, :pop, :psrecom, :gf, :sampgen, :replicate, :sim]
	coding_noncoding_summary(df, cols) |> @filter(_.replicate == 1)
end

# ╔═╡ 12ed1ff0-1ec1-11eb-26e2-a990b7582aa4
pi_data |>
	@filter(_.sampgen == 8000) |>
	@df scatter(:coding, :noncoding, α=0.5, markerstrokewidth=-1,
				group=:μ,
				legend=:outertopright, size=(1000,1000))

# ╔═╡ 654865e8-1b01-11eb-0740-998503405df9
π_gf_raw_plot = let cols = [:μ, :gen, :pop, :psrecom, :gf, :sampgen, :replicate, :sim]
	pi_data = coding_noncoding_summary(df, cols) |>
		@filter(_.replicate == 1) |>
		@orderby(_.sampgen) |>
		@groupby(_.sampgen)
	
	plot([0,1], [0,1], style=:dash, color=:gray, label="", linewidth=2)
	for timestep in pi_data
		model = glm(@formula(gf ~ coding + noncoding), timestep, Binomial(), LogitLink())
		scores = Array{Float64}(predict(model, timestep))
		r = roc(scores[timestep.gf .!= 0], scores[timestep.gf .== 0])
		auclabel = @sprintf "%0.3f" AUC(r)
		plot!(r, traditional=true,
			linewidth=3,
			α=α(r),
			label="t = $(timestep.sampgen[1]); AUC = $auclabel")
	end	
	plot!(title="Gene Flow ROC",
		xlabel="False Positive Rate",
		ylabel="True Positive Rate")
	plot!(grid=false)
	plot!(legendfontsize=6, legend=:bottomright, aspect_ratio=1.0, size=(600,600))
end

# ╔═╡ e31d452a-244c-11eb-14e9-3b299db58c8a
savefig(π_gf_raw_plot, plotsdir("raw_pi_gf_roc.pdf"))

# ╔═╡ b957de9a-1b09-11eb-199a-6f16c15492a2
π_gf_avg_raw_plot = let cols = [:μ, :gen, :pop, :psrecom, :gf, :sampgen, :replicate]
	pi_data = coding_noncoding_summary(df, cols) |>
		@filter(_.replicate == 1) |>
		@orderby(_.sampgen) |>
		@groupby(_.sampgen)
	
	plot([0,1], [0,1], style=:dash, color=:gray, label="", linewidth=2)
	for timestep in pi_data
		model = glm(@formula(gf ~ coding + noncoding), timestep, Binomial(), LogitLink())
		scores = Array{Float64}(predict(model, timestep))
		r = roc(scores[timestep.gf .!= 0], scores[timestep.gf .== 0])
		auclabel = @sprintf "%0.3f" AUC(r)
		plot!(r, traditional=true,
			linewidth=3,
			α=α(r),
			label="t = $(timestep.sampgen[1]); AUC = $auclabel")
	end	
	plot!(title="Gene Flow ROC",
		xlabel="False Positive Rate",
		ylabel="True Positive Rate")
	plot!(grid=false)
	plot!(legendfontsize=6, legend=:bottomright, aspect_ratio=1.0, size=(600,600))
end

# ╔═╡ 3ce9caea-244a-11eb-210b-4905d6ba3286
savefig(π_gf_avg_raw_plot, plotsdir("avg_raw_pi_gf_roc.pdf"))

# ╔═╡ 52a6146c-1ec3-11eb-1039-b1c9c1c4d19b
π_μ_raw_plot = let cols = [:μ, :gen, :pop, :psrecom, :gf, :sampgen, :replicate, :sim]
	pi_data = coding_noncoding_summary(df, cols) |>
		@filter(_.replicate == 1) |>
		@orderby(_.sampgen) |>
		@groupby(_.sampgen)
	
	plot([0,1], [0,1], style=:dash, color=:gray, label="", linewidth=2)
	for timestep in pi_data
		model = glm(@formula(μ ~ coding + noncoding), timestep, Binomial(), LogitLink())
		scores = Array{Float64}(predict(model, timestep))
		r = roc(scores[timestep.μ .!= 2.5e-7], scores[timestep.μ .== 2.5e-7])
		auclabel = @sprintf "%0.3f" AUC(r)
		plot!(r, traditional=true,
			linewidth=3,
			α=α(r),
			label="t = $(timestep.sampgen[1]); AUC = $auclabel")
	end	
	plot!(title="Mutation Rate ROC",
		xlabel="False Positive Rate",
		ylabel="True Positive Rate")
	plot!(grid=false)
	plot!(legendfontsize=6, legend=:bottomright, aspect_ratio=1.0, size=(600,600))
end

# ╔═╡ 7cea44bc-244a-11eb-03cf-15533f008373
savefig(π_μ_raw_plot, plotsdir("raw_pi_mutation_rate_roc.pdf"))

# ╔═╡ 1c911fb0-1ec2-11eb-21c3-159482f3d22e
π_μ_avg_raw_plot = let cols = [:μ, :gen, :pop, :psrecom, :gf, :sampgen, :replicate]
	pi_data = coding_noncoding_summary(df, cols) |>
		@filter(_.replicate == 1) |>
		@orderby(_.sampgen) |>
		@groupby(_.sampgen)
	
	plot([0,1], [0,1], style=:dash, color=:gray, label="", linewidth=2)
	for timestep in pi_data
		model = glm(@formula(μ ~ coding + noncoding), timestep, Binomial(), LogitLink())
		scores = Array{Float64}(predict(model, timestep))
		r = roc(scores[timestep.μ .!= 2.5e-7], scores[timestep.μ .== 2.5e-7])
		auclabel = @sprintf "%0.3f" AUC(r)
		plot!(r, traditional=true,
			linewidth=3,
			α=α(r),
			label="t = $(timestep.sampgen[1]); AUC = $auclabel")
	end	
	plot!(title="Mutuation Rate ROC",
		xlabel="False Positive Rate",
		ylabel="True Positive Rate")
	plot!(grid=false)
	plot!(legendfontsize=6, legend=:bottomright, aspect_ratio=1.0, size=(600,600))
end

# ╔═╡ 079e943a-244d-11eb-3356-5bd88feb2bd3
savefig(π_μ_avg_raw_plot, plotsdir("avg_raw_pi_mutation_rate_roc.pdf"))

# ╔═╡ afb9577a-1ec3-11eb-3842-6d522210c2a6
π_pop_raw_plot = let cols = [:μ, :gen, :pop, :psrecom, :gf, :sampgen, :replicate, :sim]
	pi_data = coding_noncoding_summary(df, cols) |>
		@filter(_.replicate == 1) |>
		@orderby(_.sampgen) |>
		@groupby(_.sampgen)
	
	plot([0,1], [0,1], style=:dash, color=:gray, label="", linewidth=2)
	for timestep in pi_data
		model = glm(@formula(pop ~ coding + noncoding), timestep, Normal(), IdentityLink())
		scores = Array{Float64}(predict(model, timestep))
		r = roc(scores[timestep.pop .!= 500], scores[timestep.pop .== 500])
		auclabel = @sprintf "%0.3f" AUC(r)
		plot!(r, traditional=true,
			linewidth=3,
			α=α(r),
			label="t = $(timestep.sampgen[1]); AUC = $auclabel")
	end	
	plot!(title="Effective Population Size ROC",
		xlabel="False Positive Rate",
		ylabel="True Positive Rate")
	plot!(grid=false)
	plot!(legendfontsize=6, legend=:bottomright, aspect_ratio=1.0, size=(600,600))
end

# ╔═╡ 91f51508-244a-11eb-29d7-074522279dc5
savefig(π_pop_raw_plot, plotsdir("raw_pi_pop_roc.pdf"))

# ╔═╡ 7ddfc762-1ec2-11eb-1a4d-2b48e285ab9d
π_pop_avg_raw_plot = let cols = [:μ, :gen, :pop, :psrecom, :gf, :sampgen, :replicate]
	pi_data = coding_noncoding_summary(df, cols) |>
		@filter(_.replicate == 1) |>
		@orderby(_.sampgen) |>
		@groupby(_.sampgen)
	
	plot([0,1], [0,1], style=:dash, color=:gray, label="", linewidth=2)
	for timestep in pi_data
		model = glm(@formula(pop ~ coding + noncoding), timestep, Normal(), IdentityLink())
		scores = Array{Float64}(predict(model, timestep))
		r = roc(scores[timestep.pop .!= 500], scores[timestep.pop .== 500])
		auclabel = @sprintf "%0.3f" AUC(r)
		plot!(r, traditional=true,
			linewidth=3,
			α=α(r),
			label="t = $(timestep.sampgen[1]); AUC = $auclabel")
	end	
	plot!(title="Effective Population Size ROC",
		xlabel="False Positive Rate",
		ylabel="True Positive Rate")
	plot!(grid=false)
	plot!(legendfontsize=6, legend=:bottomright, aspect_ratio=1.0, size=(600,600))
end

# ╔═╡ 1e884724-244d-11eb-290f-4b7928bdbe67
savefig(π_pop_avg_raw_plot, plotsdir("avg_raw_pi_pop_roc.pdf"))

# ╔═╡ 1974f89c-1ecc-11eb-3603-f5d91a3f94ff
let cols = [:μ, :pop, :psrecom, :gf, :gen, :sampgen, :replicate]
	p = plot(legend=:outerright)
	data = coding_noncoding_summary(df, cols) |>
		@filter(_.replicate == 1) |>
		@orderby(_.sampgen) |>
		DataFrame
	colors = Dict(map(Pair, [0.0, 0.01, 0.1], palette(:default)))
	styles = Dict([2.5e-7 => :dash, 2.5e-6 => :solid])
	for (i, group) in enumerate(groupby(data, [:gf, :μ]))
		gf, μ = first(group.gf), first(group.μ)
		@df group plot!(p, :sampgen, :noncoding ./ :coding,
					    group=(:μ, :pop, :psrecom, :gf),
						linewidth=2,
						α = (0.15 - gf)/ 0.15,
						linecolor=colors[gf],
						linestyle=styles[μ], label="$gf, $μ")
	end
	p
end

# ╔═╡ b4cc7c6c-1ec6-11eb-0d1a-191a02e1dcc5
md"""
## What's going on with S?
"""

# ╔═╡ acd0e8de-23d7-11eb-16b9-ffd9c396d3be
D_Da_S = alldata |>
	@filter(_.sources == "D, Da, S") |>
	@filter(_.payload == "Pi") |>
	@filter((_.node == "[:S, :D]" || _.node == "[:S]") && _.replicate == 1) |>
	@orderby(:sampgen) |>
	DataFrame |>
	df -> unstack(df, :node, :value) |>
	df -> rename(df, Symbol("[:S]") => :S, Symbol("[:S, :D]") => :S_D)

# ╔═╡ 3f93e854-23df-11eb-1b2b-29ed59108411
D_Da_S |>
	@df plot(:sampgen, :S_D, group=(:gf, :μ, :pop, :psrecom),
			 α = 3 * :μ / 2.5e-6,
			 linestyle = map(x -> x == 500 ? :dash : :dot, :pop),
			 linewidth = 3,
			 legend=:outerright)

# ╔═╡ 51904f60-23e0-11eb-3d5d-7d14b1160299
D_Da_S |>
	@df plot(:sampgen, :S, group=(:gf, :μ, :pop, :psrecom),
			 α = 3 * :μ / 2.5e-6,
			 linestyle = map(x -> x == 500 ? :dash : :dot, :pop),
			 linewidth = 3,
			 legend=:outerright)

# ╔═╡ b4319fa6-244a-11eb-0da2-4feb966119f8
alldata |>
	@filter(_.sources == "D, Fst, Pi, S") |>
	@filter(_.payload == "Pi") |>
	@filter(_.replicate == 1) |>
	@filter(_.value ≥ 0.1) |>
	@filter(_.gf == 0) |>
	@filter(_.μ == 2.5e-7) |>
	@filter(_.pop == 500) |>
	@filter(_.psrecom == 0.0) |>
	@filter(_.sampgen == 90000) |>
	@select(:node, :value) |>
	DataFrame

# ╔═╡ b171faea-244a-11eb-1852-fbdfc9c61369
D_Fst_Pi_S = alldata |>
	@filter(_.sources == "D, Fst, Pi, S") |>
	@filter(_.payload == "Pi") |>
	@filter(_.replicate == 1) |>
	@filter(_.node == "[:S, :D, :Pi]" || _.node == "[:S, :Pi]" || _.node == "[:S]") |>
	@orderby(:sampgen) |>
	DataFrame |>
	df -> unstack(df, :node, :value) |>
	df -> rename(df, Symbol("[:S]") => :S, Symbol("[:S, :Pi]") => :S_Pi, Symbol("[:S, :D, :Pi]") => :S_D_Pi)

# ╔═╡ 701e4f38-244c-11eb-03a5-155646016069
D_Fst_Pi_S |>
	@df plot(:sampgen, :S_D_Pi, group=(:gf, :μ, :pop, :psrecom),
			 α = 3 * :μ / 2.5e-6,
			 linestyle = map(x -> x == 500 ? :dash : :dot, :pop),
			 linewidth = 3,
			 legend=:outerright)

# ╔═╡ 79553896-244c-11eb-14ac-275e83a11daa
D_Fst_Pi_S |>
	@df plot(:sampgen, :S_Pi, group=(:gf, :μ, :pop, :psrecom),
			 α = 3 * :μ / 2.5e-6,
			 linestyle = map(x -> x == 500 ? :dash : :dot, :pop),
			 linewidth = 3,
			 legend=:outerright)

# ╔═╡ 808d4e0a-244c-11eb-37ce-23fda92bafae
D_Fst_Pi_S |>
	@df plot(:sampgen, :S, group=(:gf, :μ, :pop, :psrecom),
			 α = 3 * :μ / 2.5e-6,
			 linestyle = map(x -> x == 500 ? :dash : :dot, :pop),
			 linewidth = 3,
			 legend=:outerright)

# ╔═╡ Cell order:
# ╠═b9fc2d30-1ad0-11eb-3cb8-758bc8de6ccd
# ╠═eb381864-1b0c-11eb-0a16-c9ef7834003b
# ╠═3b8d17a0-1ec4-11eb-0add-c9ae29859db4
# ╟─b55344da-1aee-11eb-3cc7-673f1b837c05
# ╠═854e91ee-1ad1-11eb-0d78-a77acb4ef0de
# ╟─f8d36116-1b0b-11eb-1a68-89ae2e024067
# ╠═0a8e50f8-1b0c-11eb-1158-9769b51edc0c
# ╠═f1aa792e-2af4-11eb-006e-ff1082d96834
# ╠═a24253ae-1ec7-11eb-3b68-5b46f723e9da
# ╟─f54a21e4-1aee-11eb-333d-e5d3ee0424f2
# ╠═a98b4418-1ec7-11eb-08e2-e350416a8efd
# ╠═a8b44524-1ad5-11eb-365a-519261dadbcf
# ╠═5fb6dde4-2af6-11eb-398b-dbb3c0694a15
# ╠═1f62a614-1ad5-11eb-17ed-cb3d93b9c1d5
# ╠═cb2c9f86-2449-11eb-1aba-13c0ce4c02d5
# ╠═d0183666-1ae1-11eb-3906-3d5c3dff2416
# ╠═0345fbd8-244a-11eb-07a4-edb72c024cfe
# ╠═8ca59556-1ae4-11eb-138d-e7722b885477
# ╠═2a03a5e0-244a-11eb-27cb-cf01e0e722cc
# ╟─54bf559e-1af0-11eb-38a9-2d4b0cf6434f
# ╟─d5931aee-1af9-11eb-2aa0-cb3a489049fe
# ╟─51298bc6-1af9-11eb-163e-0f37eed3f00a
# ╠═d61d5d0c-1b09-11eb-2020-e552b6dbd846
# ╟─bedbbc7e-1aff-11eb-38de-55ba55e27287
# ╟─12ed1ff0-1ec1-11eb-26e2-a990b7582aa4
# ╠═654865e8-1b01-11eb-0740-998503405df9
# ╠═e31d452a-244c-11eb-14e9-3b299db58c8a
# ╠═b957de9a-1b09-11eb-199a-6f16c15492a2
# ╠═3ce9caea-244a-11eb-210b-4905d6ba3286
# ╠═52a6146c-1ec3-11eb-1039-b1c9c1c4d19b
# ╠═7cea44bc-244a-11eb-03cf-15533f008373
# ╠═1c911fb0-1ec2-11eb-21c3-159482f3d22e
# ╠═079e943a-244d-11eb-3356-5bd88feb2bd3
# ╠═afb9577a-1ec3-11eb-3842-6d522210c2a6
# ╠═91f51508-244a-11eb-29d7-074522279dc5
# ╠═7ddfc762-1ec2-11eb-1a4d-2b48e285ab9d
# ╠═1e884724-244d-11eb-290f-4b7928bdbe67
# ╟─1974f89c-1ecc-11eb-3603-f5d91a3f94ff
# ╟─b4cc7c6c-1ec6-11eb-0d1a-191a02e1dcc5
# ╠═acd0e8de-23d7-11eb-16b9-ffd9c396d3be
# ╠═3f93e854-23df-11eb-1b2b-29ed59108411
# ╟─51904f60-23e0-11eb-3d5d-7d14b1160299
# ╠═b4319fa6-244a-11eb-0da2-4feb966119f8
# ╠═b171faea-244a-11eb-1852-fbdfc9c61369
# ╠═701e4f38-244c-11eb-03a5-155646016069
# ╠═79553896-244c-11eb-14ac-275e83a11daa
# ╠═808d4e0a-244c-11eb-37ce-23fda92bafae
