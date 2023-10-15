local viz_manager = include("gameplay/viz_manager")
local simdefs = include("sim/simdefs")

local function onUnitRefreshTracks(viz, eventData)
    local unitID = eventData
    local player = viz.game.boardRig:getLocalPlayer()
    local pathRig = viz.game.boardRig:getPathRig()
    if pathRig:_shouldDrawTracks(unitID) then
        pathRig:refreshTracks(unitID, player:getTracks(unitID))
    elseif pathRig._tracks[unitID] then
        pathRig:refreshTrackProps(false, nil, nil, pathRig._tracks[unitID])
    end
end

local oldInit = viz_manager.init
function viz_manager:init(game)
    oldInit(self, game)

    -- Overwrite the broken vanilla handler. Vanilla fails to include track data.
    self.eventMap[simdefs.EV_UNIT_REFRESH_TRACKS][1] = onUnitRefreshTracks
end
