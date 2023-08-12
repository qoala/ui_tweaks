local mission_util = include("sim/missions/mission_util")
local simdefs = include("sim/simdefs")
local commondefs = include("sim/unitdefs/commondefs")

-- ===
-- Propagate searched flags to corpses.

mission_util.uitr_KILLED_WITH_CORPSE = {
    trigger = simdefs.TRG_UNIT_KILLED,
    fn = function(sim, triggerData)
        if triggerData.corpse ~= nil then
            return triggerData.unit, triggerData.corpse
        end
    end,
}

mission_util.uitr_preserveSearchedOnCorpse = function(script, sim)
    while true do
        local ev, unit, corpse = script:waitFor(mission_util.uitr_KILLED_WITH_CORPSE)
        if unit and corpse then
            corpse:getTraits().searched = unit:getTraits().searched
            corpse:getTraits().searchedAnarchy5 = unit:getTraits().searchedAnarchy5

            local corpseData = corpse:getUnitData()
            if corpseData.onWorldTooltip == commondefs.uitr_oldOnCorpseTooltip then
                -- Corpse unit data is a table instance computed from the template, safe to edit.
                -- Replace with the updated tooltip that applies searched tags.
                corpseData.onWorldTooltip = commondefs.corpse_template.onWorldTooltip
            end
        end
    end
end

-- ===

local oldMissionInit = mission_util.campaign_mission.init
function mission_util.campaign_mission:init(scriptMgr, sim, finalMission, ...)
    oldMissionInit(self, scriptMgr, sim, finalMission, ...)

    scriptMgr:addHook("UITR-SEARCHEDCORPSE", mission_util.uitr_preserveSearchedOnCorpse, true)
end
