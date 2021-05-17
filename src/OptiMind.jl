module OptiMind


## Packages
using DataFrames
using CSV
using Dates
using TimeZones
using Statistics
using Parameters
using JuMP
using PyCall
import Pandas

## Solver
#using Gurobi
#const optimizer = Gurobi.Optimizer
#const optimizer_attribute = Dict()
using GLPK
const optimizer = GLPK.Optimizer;
const optimizer_attribute = Dict("presolve" => true)
#using Cbc
#const optimizer = Cbc.Optimizer
#const optimizer_attribute = Dict("logLevel" => 1, "ratioGap" => 0.005)


## Export
export static
export Data, Agents
export agent_example
export toDataFramesDf, toPandasDf


## Types/Structures
include("./struct.jl")

## Environments
include("./envs/static/static.jl")

## Agents
include("./envs/static/agents/agent_example.jl")

## Optimization models
include("./opti/opti_dayahead_windloadbattery_deterministic.jl")

## Auxiliary
include("./auxi/convert_dataframe.jl")

end
