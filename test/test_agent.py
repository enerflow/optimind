import sys
sys.path.append("./../src/")


#%% Import modules
import pandas as pd
from OptiMind import *


#%% Import data series
df = pd.read_csv('./data/data_static.csv')
df.loc[:,'timestamps'] = pd.to_datetime(df.loc[:,'timestamps'])


#%% Create a dataframe input for the agent
# The dataframe for the specific agent should have the following columns:
# timestamps, load, generation, price_sell, price_buy
timestamps = pd.Series(df["timestamps"], name='timestamps')
load = pd.Series(df["load"], name='load')
generation = pd.Series(df["wind_generation"]+df["solar_generation"], name='generation')
price_sell = pd.Series(df["spot_price"] - 0.04, name='price_sell')
price_buy = pd.Series(df["spot_price"] + 0.04, name='price_buy')

data_input = pd.concat([timestamps, load, generation, price_sell, price_buy], axis=1).set_index('timestamps')

#%% Create data structure
data = Data(static_data = data_input)

#%%  Define agent parameters
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

#%% Create agent parameter structure
agent = Agents(agent_static = agent_parameter)


#%% Optimize
solution = static(data, agent)

#%% Unpack solution structure
operation_plan = toPandasDf(solution.operation_plan).set_index(['timestamps'])
grid_power_contract = solution.grid_power_contract
peak_contract_difference = solution.peak_contract_difference
grid_power_cost = solution.grid_power_cost
total_cost = solution.total_cost
