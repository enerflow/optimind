

function static(data::Data,agents::Agents)

    @unpack agent_static = agents
    @unpack agent = agent_static # Agent function

    solution = agent(data, agent_static)

    return solution
end
