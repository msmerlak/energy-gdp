using DrWatson; @quickactivate
using CSV, DataFrames, DataFramesMeta
using StatsPlots
gr(label = false, dpi = 200)
using StatsBase, LinearRegression, Measurements
using Countries

data = CSV.read(datadir("owid/energy-data.csv"), DataFrame)
country_codes = [c.alpha3 for c in all_countries()]
country_data = @subset(data, in.(:iso_code, Ref(country_codes)))
@subset!(country_data, .!ismissing.(:gdp) .& .!ismissing.(:energy_per_capita) .& .!ismissing.(:population))
@transform!(country_data, :energy = :energy_per_capita .* :population)

function add_fit!(year = nothing)
    if year !== nothing
        x = @subset(country_data, :year .== year)
    else
        x = country_data
    end
    fit = linregress(
        log10.(x.gdp),
        log10.(x.energy)
    )
    @show 10^fit.coeffs[2]
    plot!(x -> fit.coeffs[2] + fit.coeffs[1] * x, lw = 3, ls = :dash, label = "α = $(round(fit.coeffs[1], digits = 3))")
end

# energy vs gdp 
ρ = corspearman(
    convert(Vector{Float64}, country_data.energy),
    convert(Vector{Float64}, country_data.gdp)
)
gdp = @df country_data scatter(
    log10.(:gdp),
    log10.(:energy), 
    group = :iso_code,
    marker_z = :year,
    ylabel = "Energy consumption (log kWh)",
    xlabel = "GDP (log USD)",
    markers = :auto,
    label = false,
    alpha = .5,
    title = "Spearman = $(round(ρ; digits = 3))"
    )
add_fit!()
savefig(plotsdir("energy-gdp"))


@df @subset(country_data, :gdp .> 1e11) scatter(
    log10.(:gdp),
    :energy_per_gdp,
    group = :iso_code,
    marker_z = :year,
    label = false,
    xlabel = "log GDP",
    ylabel = "Energy per GDP"
)
savefig(plotsdir("energy-intensity-vs-gdp"))

@df @subset(country_data, :gdp .> 1e12) plot(
    :year,
    :energy_per_gdp,
    group = :country,
    ylabel = "Energy per GDP (kWh/USD)",
    lw = 2,
    markers = :auto,
    markersize = 1,
    legend = :topleft,
)
savefig(plotsdir("energy-intensity-vs-time"))

@df @combine(groupby(country_data, :year),
    :mean_energy_per_gdp = sum(:population .* :energy_per_gdp) ./ sum(:population)
) plot(:year, :mean_energy_per_gdp,
    markers = :auto
)


# energy vs gdp (per capita)
gdp = @df country_data scatter(
    log10.(:gdp ./ :population),
    log10.(:energy_per_capita), 
    group = :iso_code,
    marker_z = :year,
    markers = :auto,
    label = false,
    alpha = .5
)



using DataVoyager
@rsubset country_data begin 
    :year == 2000
    :population > 1e6
end



df = @subset(country_data, :year .== 2018)
[corspearman(df.energy_per_gdp, var) for var in eachcol(df[:, [:gdp, :population]])]

@df country_data plot(
    log10.(:gdp),
    :energy_per_gdp,
    group = :country,
    legend = false,
    markers = :auto,
    marker_z = :year,
    )
