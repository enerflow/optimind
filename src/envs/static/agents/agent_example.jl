
@with_kw struct agent_example <: AgentParameter
    agent = agent_example
    battery_min_level::Float64
    battery_capacity::Float64
    battery_charge_max::Float64
    battery_discharge_max::Float64
    battery_efficiency_charge::Float64
    battery_efficiency_discharge::Float64
    bel_ini_level::Float64 = 0.0
    bel_fin_level::Float64 = 0.0
    grid_energy_import_fee::Float64
    grid_energy_export_fee::Float64
    grid_power_fee::Float64
    grid_power_fee_penalty::Float64
    grid_power_contract::Float64 = 0.0
    period_length::Float64 = 1.0
end

@with_kw struct agent_example_out
    operation_plan::DataFrame
    grid_power_contract::Float64
    peak_contract_difference::Float64
    grid_power_cost::Float64
    total_cost::Float64
end

function agent_example(data_input::Data, agent_input::agent_example)

    # Unpack structures
    @unpack battery_min_level, battery_capacity, battery_charge_max, battery_discharge_max,
            battery_efficiency_charge ,battery_efficiency_discharge, bel_ini_level,
            bel_fin_level, grid_energy_import_fee,grid_energy_export_fee,grid_power_fee,
            grid_power_fee_penalty, grid_power_contract, period_length = agent_input
    @unpack static_data = data_input

    # Data series
    power_load = static_data[!,:load]
    power_generation = static_data[!,:generation]
    price_buy = static_data[!,:price_buy]
    price_sell = static_data[!,:price_sell]

    # Optimize
    objective, energy_cost, grid_cost_energy, grid_cost_power,
    power_buy, power_sell, power_contract, power_over,
    battery_charge, battery_discharge, battery_state, status = opti_dayahead_windloadbattery_deterministic(
        power_load, power_generation, price_buy, price_sell,
        battery_min_level,  battery_capacity, battery_charge_max, battery_discharge_max, battery_efficiency_charge, battery_efficiency_discharge,
        grid_energy_import_fee, grid_energy_export_fee, grid_power_fee, grid_power_fee_penalty;
        period_length = period_length,  bel_ini_level = bel_ini_level,  bel_fin_level = bel_fin_level,
        grid_power_contract = grid_power_contract)

    # Results
    operation_plan = DataFrame(timestamps = static_data[!,:timestamps], power_sell = power_sell,
                                power_buy = power_buy, energy_cost = energy_cost,
                                grid_energy_cost = grid_cost_energy, battery_state = battery_state)

    grid_power_contract = round(power_contract,digits=1)
    peak_contract_difference = round(power_over,digits=1)
    grid_power_cost = round(grid_cost_power,digits=1)
    total_cost = round(objective,digits=1)

    solution = agent_example_out(operation_plan, grid_power_contract, peak_contract_difference, grid_power_cost, total_cost)

    return solution
end
