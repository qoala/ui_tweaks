local viz_manager = include("gameplay/viz_manager")
local simdefs = include("sim/simdefs")

local function onUnitRefreshTracks(viz, eventData)
    local unitID = eventData
    local player = viz.game.boardRig:getLocalPlayer()
    viz.game.boardRig:getPathRig():refreshTracks(unitID, player:getTracks(unitID))
end

local oldInit = viz_manager.init
function viz_manager:init(game)
    oldInit(self, game)

    -- Overwrite the broken vanilla handler. Vanilla fails to include track data.
    self.eventMap[simdefs.EV_UNIT_REFRESH_TRACKS][1] = onUnitRefreshTracks
end
