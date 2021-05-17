
from julia import Julia            # This may be excluded (depends on the OS)
jl = Julia(compiled_modules=False) # This may be excluded (depends on the OS)
from julia import Main
Main.include("./../src/OptiMind.jl")


#%% Environments
static = Main.OptiMind.static

#%% Agents
agent_example = Main.OptiMind.agent_example


#%% Structures
Data    = Main.OptiMind.Data
Agents  = Main.OptiMind.Agents

#%% Functions
toDataFramesDf  = Main.OptiMind.toDataFramesDf
toPandasDf      = Main.OptiMind.toPandasDf

nothing = Main.nothing
