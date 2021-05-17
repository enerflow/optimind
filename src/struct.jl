
abstract type AgentParameter end
abstract type MarketParameter end


@with_kw struct Data
    static_data::Union{Nothing,DataFrame,PyObject} = nothing
end

function Data(static_data::Union{Nothing,PyObject})
    if typeof(static_data) == PyObject
        static_data = toDataFramesDf(static_data)
    end

    return Data(static_data)
end


@with_kw struct Agents
    agent_static::Union{Nothing,AgentParameter} = nothing
end
