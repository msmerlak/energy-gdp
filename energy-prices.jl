using DrWatson
using CSV, DataFrames

price_data = CSV.read(datadir("iea/energy-prices.csv"), DataFrame)
@subset!(price_data, :Indices .== "Retail", length.(:Time) .== 4, :Product .== "Electricity (MWh)")
@transform!(price_data, :year = parse.(Int, :Time))
@transform!(price_data, :energy_price = :Value ./ 1000)
@transform!(price_data, :country = :Country)
@transform!(price_data, :iso_code = :IEA_LOCATION)
@select!(price_data, :year, :iso_code, :energy_price)

df = innerjoin(country_data, price_data, on = [:year, :iso_code])