local simdefs = include("sim/simdefs")
local simplayer = include("sim/simplayer")
local simquery = include("sim/simquery")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")
local track_colors = include(SCRIPT_PATHS.qed_uitr .. "/features/track_colors")

-- ===

local OLD_FN_MAPPING = {
    markSeen = simplayer.markSeen,
    glimpseUnit = simplayer.glimpseUnit,
    clearTracks = simplayer.clearTracks,
    trackFootstep = simplayer.trackFootstep,
    onEndTurn = simplayer.onEndTurn,
}
local NEW_KEYS = {"getUITRKnownBounds", "_updateUITRKnownBounds"}
simplayer._uitrmeta_simplayerKnownBounds = true

local oldInit = simplayer.init
function simplayer:init(...)
    uitr_util.propagateSuperclass(
            getmetatable(self), simplayer, OLD_FN_MAPPING, NEW_KEYS,
            "_uitrmeta_simplayerKnownBounds")

    oldInit(self, ...)
end

-- ===
-- Known Bounds
-- Track the player-known bounds of the map, so that certain effects don't leak the true bounds.

function simplayer:getUITRKnownBounds()
    return self._uitr_minKnownX, self._uitr_minKnownY, self._uitr_maxKnownX, self._uitr_maxKnownY
end

function simplayer:_updateUITRKnownBounds(cellx, celly)
    -- Track min/max known cell coordinates.
    if not self._uitr_minKnownX and cellx then
        self._uitr_minKnownX = cellx
        self._uitr_maxKnownX = cellx
        self._uitr_minKnownY = celly
        self._uitr_maxKnownY = celly
    elseif cellx then
        self._uitr_minKnownX = math.min(self._uitr_minKnownX, cellx)
        self._uitr_maxKnownX = math.max(self._uitr_maxKnownX, cellx)
        self._uitr_minKnownY = math.min(self._uitr_minKnownY, celly)
        self._uitr_maxKnownY = math.max(self._uitr_maxKnownY, celly)
    end
end

local oldMarkSeen = simplayer.markSeen
function simplayer:markSeen(sim, cellx, celly, ...)
    self:_updateUITRKnownBounds(cellx, celly)
    return oldMarkSeen(self, sim, cellx, celly, ...)
end

local oldGlimpseUnit = simplayer.glimpseUnit
function simplayer:glimpseUnit(sim, unitID, ...)
    local unit = sim:getUnit(unitID)
    if unit and unit:getLocation() then
        -- Map Bounds Tracking.
        self:_updateUITRKnownBounds(unit:getLocation())

        -- Footprint Tracking.
        track_colors.ensureUnitHasColor(unit)
    end

    return oldGlimpseUnit(self, sim, unitID, ...)
end

-- ===
-- Footprint (past guard path) Tracking
--
-- This behavior already exists on simplayer, but the rendering is broken.
-- Tracked in simplayer._footsteps (MAP<unitID,ARRAY<STRUCT>>) and returned by :getTracks() and
-- :getTracks(unitID). Cleared automatically in simplayer:onEndTurn.
--
-- The ARRAY<STRUCT> is an array of moved tiles, along with how/whether the player knows about it.
-- It also has its own .info sub-STRUCT with turn-wide info about the unit's history.

-- UITR: Override vanilla.
function simplayer:clearTracks(unitID)
    -- Disabled.
    -- Only called by vanilla simplayer:addSeenUnit(), but we now want to also track data for seen
    -- units and tiles.
end

-- Mix of simengine:canPlayerSee() and simquery:couldUnitSee().
-- The unit hasn't moved yet when tracking footsteps.
local function couldPlayerSeeCellAndUnit(player, unit, x, y)
    local sim = unit:getSim()
    local canSeeCell = false
    for i, playerUnit in ipairs(player:getUnits()) do
        if sim:canUnitSee(playerUnit, x, y) then
            if simquery.couldUnitSee(sim, playerUnit, unit, false, sim:getCell(x, y)) then
                return true, true
            end
            canSeeCell = true
        end
    end
    return canSeeCell, false
end

-- UITR: Override vanilla.
function simplayer:trackFootstep(sim, unit, cellx, celly)
    -- UITR: Remove "only if player cannot see unit" check. Track all units.

    local unitTraits, unitID = unit:getTraits(), unit:getID()
    -- Hearing
    local closestUnit, closestRange = simquery.findClosestUnit(
            self._units, cellx, celly, simquery.canHear)
    -- Vision
    local canSeeCell, canSeeUnit = couldPlayerSeeCellAndUnit(self, unit, cellx, celly)
    local footstep = {
        x = cellx,
        y = celly,
        -- UITR: replace isSeen with "is unit seen" and create a new isCellSeen for this.
        isCellSeen = canSeeCell,

        isSeen = canSeeUnit,
        isHeard = closestRange <= simquery.getMoveSoundRange(unit, sim:getCell(cellx, celly)),
        -- UITR: Instead of 'tagged' setting isHeard, set its own trait.
        -- simunit:onEndTurn clears getTraits().patrolObserved, so that's already expired.
        -- Fixing that would require figuring out if the path has deviated during the guard turn.
        isTracked = (unitTraits.tagged) and self:getCell(cellx, celly),
    }

    local footpath = self._footsteps[unitID]
    if footpath == nil then
        footpath = {}
        self._footsteps[unit:getID()] = footpath
    end
    table.insert(footpath, footstep)

    -- UITR: Track if the unit was seen moving at any point on this turn.
    -- Need to also do a hasKnownGhost check in case the unit was seen or glimpsed for other
    -- reasons.
    if not footpath.info then
        footpath.info = {}
    end
    footpath.info.wasSeen = footpath.info.wasSeen or footstep.isSeen
    footpath.info.wasTracked = footpath.info.wasTracked or footstep.isTracked

    sim:dispatchEvent(simdefs.EV_UNIT_REFRESH_TRACKS, unit:getID())
end

local oldOnEndTurn = simplayer.onEndTurn
function simplayer:onEndTurn(sim)
    -- Record any known ghosts for next turn's footpaths.
    -- (Non-ghosts should already be handled by moving while seen.)
    local lastKnownGhosts = {}
    if sim:getCurrentPlayer() == self then
        for unitID, ghostUnit in pairs(self._ghost_units) do
            if simquery.isAgent(ghostUnit) and uitr_util.getKnownUnitFromGhost(sim, ghostUnit) then
                table.insert(lastKnownGhosts, unitID)
            end
        end
    end

    oldOnEndTurn(self, sim)

    if sim:getCurrentPlayer() == self then
        for _, unitID in ipairs(lastKnownGhosts) do
            self._footsteps[unitID] = {info = {wasSeen = true}}
        end
    end
end
