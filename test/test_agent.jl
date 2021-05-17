## Include modules
include("./../src/OptiMind.jl")
using .OptiMind
using CSV
using DataFrames

## Import data series
df = CSV.read("./test/data/data_static.csv"; copycols=true)


## Create a dataframe input for the agent
# The dataframe for the specific agent should have the following columns:
# timestamps, load, generation, price_sell, price_buy
data_input = DataFrame(timestamps = df[!,:timestamps], load = df[!,:load],
generation = df[!,:wind_generation] .+ df[!,:solar_generation],
price_sell = df[!,:spot_price] .- 0.04, price_buy = df[!,:spot_price] .+ 0.04)

data = Data(static_data = data_input)

## Define agent parameters
agent_parameter = agent_example(
    battery_min_level = 0.0,
    battery_capacity = 1040.0,
    battery_charge_max = 470.0,
    battery_discharge_max = 470.0,
    battery_efficiency_charge = 0.9,
    battery_efficiency_discharge = 0.9,
    bel_ini_level = 0.0,
    bel_fin_level = 0.0,
    grid_energy_import_fee = 0.015,
    grid_energy_export_fee = 0.015,
    grid_power_fee = 111.0,
    grid_power_fee_penalty = 222,
    grid_power_contract = 0.0)

agent = Agents(agent_static = agent_parameter)


## Optimize
solution = static(data, agent)

operation_plan = solution.operation_plan
grid_power_contract = solution.grid_power_contract
peak_contract_difference = solution.peak_contract_difference
grid_power_cost = solution.grid_power_cost
total_cost = solution.total_cost
