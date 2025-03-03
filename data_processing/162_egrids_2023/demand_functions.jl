################################################################################
#                                                                              #
#  demand_functions.jl                                                         #
#                                                                              #
#  Computes carbon emissions for different energy production profiles used to  #
#  meet demand levels. i.e, given a demand level, compute the carbon emissions #
#  for each plant type when each plant type is used to compute a given         #
#  percentage of the demand.
#                                                                              #
#  Author: Edward Speer                                                        #
#  Date:   2/23/2025                                                           #
#                                                                              #
################################################################################

################################################################################
#  IMPORTS                                                                     #
################################################################################

using DataFrames

include("plant_avgs.jl")

################################################################################
#  CONSTANTS                                                                   #
################################################################################

PLANT_CATEGORIES = (
    :BIOMASS,
    :COAL,
    :GAS,
    :GEOTHERMAL,
    :HYDRO,
    :NUCLEAR,
    :OFSL,
    :OIL,
    :OTHF,
    :SOLAR,
    :WIND,
)

################################################################################
#  FUNCTIONS                                                                   #
################################################################################

"""
    plant_pct_to_MWh(plant_category::String, percentage::Float64)
    
Given the percentage of power production from a plant category, compute the
total power demand from the plant category in MWh at the given demand level.
"""
function plant_pct_to_MWh(percentage::Float64, demand::Float64)
    return percentage * demand
end

"""
    plant_pcts_to_MWh_vec(
        percentage_vec::NamedTuple{PLANT_CATEGORIES, 
                                     NTuple{length(PLANT_CATEGORIES), Float64}},
        demand::Float64
    )

Given a vector of percentages of power production from all plant types, compute
the total power demand from each plant type in MWh at the given demand level.
"""
function plant_pcts_to_MWh_vec(
    percentage_vec::NamedTuple{PLANT_CATEGORIES, 
                                     NTuple{length(PLANT_CATEGORIES), Float64}},
    demand::Float64
)
    return NamedTuple{PLANT_CATEGORIES,
                                     NTuple{length(PLANT_CATEGORIES), Float64}}(
        map(x -> plant_pct_to_MWh(x, demand), percentage_vec)
    )
end

"""
    MWh_to_CO2(
        plant_category::String,
        MWh::Float64,
        emissions_profile::DataFrame
    )

Given the total power demand from a plant category in MWh, compute the total
CO2 emissions from the plant category in tons.
"""
function MWh_to_CO2(
    plant_category::Symbol,
    MWh::Float64,
    emissions_profile::DataFrame
)
    category_index = findfirst(emissions_profile[!, :PlantType]
                                                     .== string(plant_category))
    power_to_emission_ratio = 
                          emissions_profile[category_index, :]["CO2Emissions"] /
                           emissions_profile[category_index, :]["NetGeneration"]
    return MWh * power_to_emission_ratio
end

"""
    MWh_vec_to_CO2_vec(
        MWh_vec::NamedTuple{PLANT_CATEGORIES, 
                                     NTuple{length(PLANT_CATEGORIES), Float64}},
        emissions_profile::DataFrame
    )

Given a vector of total power demands from all plant types in MWh, compute the
total CO2 emissions from each plant type in tons.
"""
function MWh_vec_to_CO2_vec(
    MWh_vec::NamedTuple{PLANT_CATEGORIES, 
                                     NTuple{length(PLANT_CATEGORIES), Float64}},
    emissions_profile::DataFrame
)
    return NamedTuple{PLANT_CATEGORIES,
                                     NTuple{length(PLANT_CATEGORIES), Float64}}(
        map(x -> MWh_to_CO2(x, MWh_vec[x], emissions_profile), PLANT_CATEGORIES)
    )
end
