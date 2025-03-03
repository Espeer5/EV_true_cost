################################################################################
#                                                                              #
#  plant_avgs.jl                                                               #
#                                                                              #
#  Calculates the average emissions per plant type from the EGRID emissions    #
#  data.                                                                       #
#                                                                              #
#  Author: Edward Speer                                                        #
#  Date:   2/23/2025                                                           #
#                                                                              #
################################################################################

################################################################################
#  IMPORTS                                                                     #
################################################################################

using DataFrames
using Statistics
using XLSX

################################################################################
#  CONSTANTS                                                                   #
################################################################################

# Data file and workbook variable
DATA_FILE        = "data/egrid2023_data_rev1.xlsx"
XF               = XLSX.readxlsx(DATA_FILE)

# Data characteristics
PLANT_SHEET_NAME = "PLNT23"

# Data labels
PLANT_FUEL_CATEGORY  = :PLFUELCT
PLANT_CO2_EMISSIONS  = :PLCO2AN  # Annual CO2 emissions (tons)
PLANT_NET_GENERATION = :PLNGENAN # Annual net generation (MWh)

# Plant primary fuel categories
PLANT_FUEL_CATEGORIES = [
    "BIOMASS",
    "COAL",
    "GAS",
    "GEOTHERMAL",
    "HYDRO",
    "NUCLEAR",
    "OFSL",
    "OIL",
    "OTHF",
    "SOLAR",
    "WIND",
]

################################################################################
#  FUNCTIONS                                                                   #
################################################################################

"""
    get_df()

Returns the EGRID data from a particular worksheet as a DataFrame.
"""
function get_sheet_df(sheet_name::String)
    worksheet = XF[sheet_name]
    # Use column 2 (short name) as the column names
    return DataFrame(worksheet[:][3:end, :], worksheet[:][2, :])
end

"""
    plant_type_filter(df::DataFrame, plant_type::String)

returns the trimmed DataFrame containing only the plant type of interest
"""
function plant_type_filter(df::DataFrame, plant_type::String)
    return filter(PLANT_FUEL_CATEGORY => x -> x == plant_type, df)
end

"""
    CO2_plant_avg(df::DataFrame)

Returns the average emissions over a DataFrame of plant data.
"""
function CO2_plant_avg(df::DataFrame)
    # Filter missing values
    df = filter(PLANT_CO2_EMISSIONS => x -> !ismissing(x), df)
    return mean(df[!, PLANT_CO2_EMISSIONS])
end

"""
    net_generation_plant_avg(df::DataFrame)

Returns the average net generation over a DataFrame of plant data.
"""
function net_generation_plant_avg(df::DataFrame)
    # Filter missing values
    df = filter(PLANT_NET_GENERATION => x -> !ismissing(x), df)
    return mean(df[!, PLANT_NET_GENERATION])
end

"""
    emmisions_profile(df::DataFrame)

Returns the emissions profile across all plant types, consisting of the average
CO2 emissions in annual tons for each plant type in the data set as well as the 
net generation in annual MWh.
"""
function emissions_profile(df::DataFrame)
    # Initialize the emissions profile DataFrame
    emissions_profile = DataFrame(
        PlantType     = String[],
        Samples       = Int64[],
        CO2Emissions  = Float64[],
        NetGeneration = Float64[]
    )

    # Iterate over each plant type
    for plant_type in PLANT_FUEL_CATEGORIES
        # Filter the data for the plant type
        plant_df = plant_type_filter(df, plant_type)

        # Data characteristics for plant type
        plant_samples = size(plant_df, 1)

        # Calculate the average emissions and net generation
        avg_CO2_emissions = CO2_plant_avg(plant_df)
        avg_net_generation = net_generation_plant_avg(plant_df)

        # Append the results to the emissions profile
        push!(emissions_profile, (plant_type, plant_samples, avg_CO2_emissions,
                                                            avg_net_generation))
    end

    return emissions_profile
end

################################################################################
#  MAIN                                                                        #
################################################################################

"""
    power_plant_emissions_profile()

Main function for the plant_avgs.jl script. Parses the EGRID XLSX file for the
plant-level data and collects the emissions to power production averaging data
for each power plant type. Returns a DataFrame with the results.
"""
function power_plant_emissions_profile()
    return emissions_profile(get_sheet_df(PLANT_SHEET_NAME))
end
