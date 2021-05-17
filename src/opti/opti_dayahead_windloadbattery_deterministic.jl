using JuMP


function opti_dayahead_windloadbattery_deterministic(
    power_load::Vector{T} where T<:Real,
    power_generation::Vector{T} where T<:Real,
    price_buy::Vector{T} where T<:Real,
    price_sell::Vector{T} where T<:Real,
    battery_min_level::Float64,
    battery_capacity::Float64,
    battery_charge_max::Float64,
    battery_discharge_max::Float64,
    battery_efficiency_charge::Float64,
    battery_efficiency_discharge::Float64,
    grid_energy_import_fee::Float64,
    grid_energy_export_fee::Float64,
    grid_power_fee::Float64,
    grid_power_fee_penalty::Float64;
    # Parameter
    optimizer::DataType = optimizer,
    optimizer_attribute::Dict = optimizer_attribute,
    period_length::Float64 = 1.0,
    bel_ini_level::Float64 = 0.0,
    bel_fin_level::Float64 = 0.0,
    grid_power_contract::Float64 = 0.0)


    # Description
    #   Calculate the optimal buying and selling power of a wind/solar+battery+load aggregator
    #   in the dayahead electricity market. Grid costs for energy and power are considered.
    #
    # Input
    #   power_load                      power load [*W], vector [number_of_periods]
    #   power_generation                wind/solar power generation [*W], vector [number_of_periods]
    #   price_buy                       market price for buying energy [Currency/*Wh], vector [number_of_periods]
    #   price_sell                      market price for selling energy [Currency/*Wh], vector [number_of_periods]
    #   battery_min_level               battery minimum energy level as percentage of capacity [percentage], float [0.0,1.0]
    #   battery_capacity                battery capacity [*Wh], float
    #   battery_charge_max              battery max charging power [*W], float
    #   battery_discharge_max           battery max discharging power [*W], float
    #   battery_efficiency_charge       battery efficiency when charging [percentage], float [0.0,1.0]
    #   battery_efficiency_discharge    battery efficiency when discharging [percentage], float [0.0,1.0]
    #   grid_energy_import_fee          grid fee for energy consuption [Currency/*Wh], float
    #   grid_energy_export_fee          grid fee for energy production [Currency/*Wh], float
    #   grid_power_fee                  grid contract fee for power [Currency/*W], float
    #   grid_power_fee_penalty          grid penalty fee for exceeding contract power level [Currency/*W], float
    #
    # Parameter
    #   optimizer                       SolverName.Optimizer (e.g. GLPK.Optimizer)
    #   optimizer_attribute             dictionary of solver attributes
    #   period_length                   period length relative to hour (e.g if 15min periods, then period_length = 0.25) [percentage], float
    #   bel_ini_level                   battery energy level in the beginning of the planning horizon [*Wh], float
    #   bel_fin_level                   battery energy level at the end of the planning horizon [*Wh], float
    #   grid_power_contract             grid contract power level [*W], (if set to zero then power level is optimized), float
    #
    # Output
    #   objective                       value of objective function, float
    #   energy_cost                     energy cost [Currency], vector [number_of_periods]
    #   grid_cost_energy                grid energy cost [Currency], vector [number_of_periods]
    #   grid_cost_power                 grid power cost [Currency], float
    #   power_buy                       buying power [*W], vector [number_of_periods]
    #   power_sell                      selling power [*W], vector [number_of_periods]
    #   power_contract                  power contract level [*W], float
    #   power_over                      difference between power peak and power contract level [*W], float
    #   battery_charge                  battery charging power [*W], vector [number_of_periods]
    #   battery_discharge               battery discharging power [*W], vector [number_of_periods]
    #   battery_state                   battery energy state [*Wh], vector [number_of_periods]
    #   status                          termination, primal and dual statuses
    #
    # Prefix "*" replaces some metric prefix (e.g k for kilo, M for mega, etc)


    # Assign parameter values
    generation          = power_generation
    load                = power_load
    dt                  = period_length
    # Correct initial/final battery state if values provided are infeasible
    bel_ini_level       = max(bel_ini_level, battery_min_level*battery_capacity)
    bel_fin_level       = max(bel_fin_level, battery_min_level*battery_capacity)


    # Initialize optimization model
    model = Model(optimizer)
    for atr in collect(keys(optimizer_attribute))
        set_optimizer_attribute(model, atr, optimizer_attribute[atr])
    end

    # Sets
    T = 1:length(generation)

    # Define decision variables
    @variable( model, COST_ENERGY[t in T] ) # Cost of purchased energy (negative for profit) in period t
    @variable( model, 0 <= COST_GRID_ENERGY[t in T] ) # Cost of grid connection for the transfered energy in period t
    @variable( model, 0 <= COST_GRID_POWER ) # Cost of grid connection for the power level
    @variable( model, 0 <= P_CONTR ) # Grid power level contract
    @variable( model, 0 <= P_OVER ) # Difference between power peak and power contract level

    @variable( model, 0 <= P_BUY[t in T] ) # Buying power from grid in period t
    @variable( model, 0 <= P_SELL[t in T] ) # Selling power to grid in period t
    @variable( model, battery_min_level*battery_capacity <= BEL[t in T] <= battery_capacity ) # Battery energy level in period t
    @variable( model, 0 <= B_IN[t in T] <= battery_charge_max ) # Battery charging power in period t
    @variable( model, 0 <= B_OUT[t in T] <= battery_discharge_max) # Battery discharging power in period t


    # Set the objective
    @objective( model, Min,
                    sum( COST_ENERGY[t] + COST_GRID_ENERGY[t] for t in T) + COST_GRID_POWER
    )


    # Set the constraints
    @constraint( model, energyCost[t in T],
                    COST_ENERGY[t] == price_buy[t]*P_BUY[t]*dt - price_sell[t]*P_SELL[t]*dt
    )

    @constraint( model, gridEnergyCost[t in T],
                    COST_GRID_ENERGY[t] == grid_energy_import_fee*P_BUY[t]*dt + grid_energy_export_fee*P_SELL[t]*dt
    )

    @constraint( model, gridPowerCost,
                    COST_GRID_POWER == grid_power_fee*P_CONTR + grid_power_fee_penalty*P_OVER
    )

    @constraint( model, gridOverPower1[t in T],
                    P_OVER >= P_BUY[t] - P_CONTR
    )

    @constraint( model, gridOverPower2[t in T],
                    P_OVER >= P_SELL[t] - P_CONTR
    )

    @constraint( model, energyBalance[t in T],
                    P_SELL[t] - P_BUY[t] == generation[t] + B_OUT[t] - B_IN[t] - load[t]
    )

    @constraint( model, batteryState[t in T[2:end]],
                    BEL[t] - BEL[t-1] == battery_efficiency_charge*B_IN[t]*dt  - (1/battery_efficiency_discharge)*B_OUT[t]*dt
    )

    @constraint( model, batteryStateIni[t in T[1]],
                    BEL[t] - bel_ini_level == battery_efficiency_charge*B_IN[t]*dt  - (1/battery_efficiency_discharge)*B_OUT[t]*dt
    )

    # Fix value of battery energy level at the end of planning horizon
    if bel_fin_level > battery_min_level*battery_capacity
        fix(BEL[end], bel_fin_level; force = true)
    end

    # If parameter grid_power_contract is positive then fix P_CONTR to that value
    if grid_power_contract > 0
        fix(P_CONTR, grid_power_contract; force = true)
    end


    # Solve and get solution values
    JuMP.optimize!(model)


    term_status         = string(JuMP.termination_status(model))
    primal_status       = string(JuMP.primal_status(model))
    dual_status         = string(JuMP.dual_status(model))
    status              = [term_status,primal_status,dual_status]

    objective           = JuMP.objective_value(model)

    energy_cost         = collect(JuMP.value.(COST_ENERGY))
    grid_cost_energy    = collect(JuMP.value.(COST_GRID_ENERGY))
    grid_cost_power     = JuMP.value.(COST_GRID_POWER)

    power_buy           = collect(JuMP.value.(P_BUY))
    power_sell          = collect(JuMP.value.(P_SELL))
    power_contract      = JuMP.value.(P_CONTR)
    power_over          = JuMP.value.(P_OVER)

    battery_charge      = collect(JuMP.value.(B_IN))
    battery_discharge   = collect(JuMP.value.(B_OUT))
    battery_state       = collect(JuMP.value.(BEL))



    return objective, energy_cost, grid_cost_energy, grid_cost_power,
            power_buy, power_sell, power_contract, power_over,
            battery_charge, battery_discharge, battery_state, status

end
