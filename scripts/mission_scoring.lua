local mission_scoring = include( "mission_scoring" )
local array = include( "modules/array" )
local serverdefs = include( "modules/serverdefs" )
local rand = include("modules/rand")
local util = include( "modules/util" )
local unitdefs = include("sim/unitdefs")

local oldDoFinishMission = mission_scoring.DoFinishMission
mission_scoring.DoFinishMission = function( sim, campaign, ... )

	local flow_result = oldDoFinishMission( sim, campaign, ... )

	-- -----
	-- Rescued agent status fix (Copied from Community Bug Fixes)
	-- -----
	local rescued_agents = {}
	local mia_agents = {}
	-- Find rescued agents first
	for i, agent in ipairs( sim._resultTable.agents ) do
		if agent.status == "RESCUED" and not agent._cbf_name and type(agent.name) == "table" and type(agent.name.template) == "string" then
			agent.name = agent.name.template
			agent._cbf_name = agent.name -- Fix for MAA applying this transform a second time
			rescued_agents[agent.name] = true
		elseif agent.status ~= "ACTIVE" and type(agent.name) == "string" then
			-- Something *else* happened to the agent after they were rescued. That status should take precedence.
			mia_agents[agent.name] = true
		end
	end
	-- Delete the duplicates
	for i=#sim._resultTable.agents, 1, -1 do
		local agent = sim._resultTable.agents[i]
		if mia_agents[agent.name] and agent.status == "RESCUED" then
			-- Delete RESCUED if MIA.
			table.remove( sim._resultTable.agents, i )
		elseif not mia_agents[agent.name] and rescued_agents[agent.name] and agent.status == "ACTIVE" then
			-- Delete ACTIVE if RESCUED.
			table.remove( sim._resultTable.agents, i )
		end
	end
	-- -----
	-- END Detention Centers agent chance fix
	-- -----

	return flow_result
end
