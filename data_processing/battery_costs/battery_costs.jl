################################################################################
#                                                                              #
#  battery_costs.jl                                                            #
#                                                                              #
#  Per each 2024 all-electric vehicle in the U.S, calculates the Cobalt        #
#  content in the battery and therefore the CO2 used in production and social  #
#  cost of carbon. Also uses the energy economy model of the vehicle to        #
#  compute the recurrent costs at the given energy generation scenario.        #
#                                                                              #
#  Author: Edward Speer                                                        #
#  Date:   3/13/2025                                                           #
#                                                                              #
################################################################################

################################################################################
#  IMPORTS                                                                     #
################################################################################

using DataFrames
using Statistics
using CSV

################################################################################
#  CONSTANTS                                                                   #
################################################################################

DATA_PATH = "light-duty-vehicles-2025-03-13.csv"
OUTPUT_PATH = "battery_costs.csv"

CB_PER_KWH = (.3 + .15) / 2 # Average cobalt over NCM 622 to NMC 811
CO2_per_CB = 10.8           # kg CO2 per kg cobalt

################################################################################
#  FUNCTIONS                                                                   #
################################################################################

"""
    get_DF()

Reads the data from the CSV file and returns it as a DataFrame.
"""
function get_DF()
    return CSV.File(DATA_PATH) |> DataFrame
end

"""
    get_battery_cobalt(df::DataFrame)

Estimates the cobalt conent in the battery of each electric car model given in 
each row of the DataFrame.
"""
function get_battery_cobalt(df::DataFrame)
    cobalt_content = []
    for row in eachrow(df)
        cobalt = row["Battery Capacity kWh"] * CB_PER_KWH
        push!(cobalt_content, cobalt)
    end
    return cobalt_content
end

"""
    get_CO2_cost(cobalt_content::Array{Float64})

Estimates the CO2 cost of producing the cobalt in the battery of each electric
car model.
"""
function get_CO2_cost(cobalt_content::Vector)
    return cobalt_content .* CO2_per_CB
end

"""
    process_fuel_economy(df::DataFrame)

Some of the fuel economy numbers are stored as individual values, but some are
reanges with the format "#-#". This function collapses the ranges to their
average.
"""
function process_fuel_economy(df::DataFrame)
    for row in eachrow(df)
        fuel_economy = row["Alternative Fuel Economy Combined"]
        # If fuel economy noot in dataset for vehicle, remove row
        if fuel_economy == ""
            delete!(df, row)
            continue
        end
        if occursin("-", fuel_economy)
            fuel_economy = split(fuel_economy, "-")
            fuel_economy = mean(parse.(Float64, fuel_economy))
        else
            fuel_economy = parse(Float64, fuel_economy)
        end
        row["Alternative Fuel Economy Combined"] = string(fuel_economy)
    end
end

"""
    mpge_to_kwh_per_m(df::DataFrame)

Converts the MPGe to kWh per mile for each vehicle in the DataFrame. MPGe is 
defined as the number of miles a car can go on the energy equivalent of a
gallon of gasoline (33.7 kWh). We are interested in the energy use per mile
instead.
"""
function mpge_to_kwh_per_m(df::DataFrame)
    KWH_per_m = []
    for row in eachrow(df)
        mpge = parse(Float64, row["Alternative Fuel Economy Combined"])
        kwh_per_m = 33.7 / mpge
        push!(KWH_per_m, kwh_per_m)
    end
    return KWH_per_m
end

################################################################################
#  MAIN                                                                        #
################################################################################

df = get_DF()
cobalt_content = get_battery_cobalt(df)
CO2_cost = get_CO2_cost(cobalt_content)

process_fuel_economy(df)

# Add the cobalt and carbon amounts to the df
df[!, "Cobalt Content (kg)"] = cobalt_content
df[!, "CO2 Cost (kg)"] = CO2_cost

# Add the KWH per mile usage to the df
df[!, "kWh Per Mile"] = mpge_to_kwh_per_m(df)

# Write selected columns of the DF to a new CSV file
df[!, ["Model", "kWh Per Mile", "Cobalt Content (kg)",
                                     "CO2 Cost (kg)"]] |> CSV.write(OUTPUT_PATH)
