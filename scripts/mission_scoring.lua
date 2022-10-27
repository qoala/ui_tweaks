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
	-- Find rescued agents first
	for i, agent in ipairs( sim._resultTable.agents ) do
		if agent.status == "RESCUED" and type(agent.name) ~= "string" then
			agent.name = agent.name.template
			agent._cbf_name = agent.name -- Fix for MAA applying this transform a second time
			table.insert(rescued_agents, agent.name)
		end
	end
	-- Delete the duplicates
	for i=#sim._resultTable.agents, 1, -1 do
		if array.find( rescued_agents, sim._resultTable.agents[i].name ) and sim._resultTable.agents[i].status ~= "RESCUED" then
			table.remove( sim._resultTable.agents, i )
		end
	end
	-- -----
	-- END Detention Centers agent chance fix
	-- -----

	return flow_result
end
