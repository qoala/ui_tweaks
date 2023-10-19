local array = include("modules/array")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local pcplayer = include("sim/pcplayer")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")
local track_colors = include(SCRIPT_PATHS.qed_uitr .. "/features/track_colors")

local oldAddSeenUnit = pcplayer.addSeenUnit
function pcplayer:addSeenUnit(unit, ...)
    oldAddSeenUnit(self, unit, ...)

    -- Initialize UI track color on sight.
    track_colors.ensureUnitHasColor(unit)
end

-- ===
-- Footprint (past guard path) Tracking
--
-- This behavior already exists on simplayer, but the rendering is broken.
-- Tracked in pcplayer._footsteps (MAP<unitID,ARRAY<STRUCT>>) and returned by :getTracks() and
-- :getTracks(unitID). Cleared automatically in pcplayer:onEndTurn.
--
-- The ARRAY<STRUCT> is an array of moved tiles, along with how/whether the player knows about it.
-- It also has its own .info sub-STRUCT with turn-wide info about the unit's history.

-- UITR: Override vanilla.
function pcplayer:clearTracks(unitID)
    -- Disabled.
    -- Only called by vanilla simplayer:addSeenUnit(), but we now want to also track data for seen
    -- units and tiles.
end

-- Returns canSeeCell, canSeeUnit, canSenseUnit
-- Mix of simengine:canPlayerSee() and simquery:couldUnitSee().
-- Done manually because the unit hasn't moved yet when trackFootsteps is called.
local function couldPlayerSeeCellAndUnit(player, unit, x, y)
    local sim = unit:getSim()
    local canSeeCell, canSenseUnit = false, false
    for i, playerUnit in ipairs(player:getUnits()) do
        if sim:canUnitSee(playerUnit, x, y) then
            if simquery.couldUnitSee(sim, playerUnit, unit, false, sim:getCell(x, y)) then
                return true, true, canSenseUnit
            end
            canSeeCell = true
        elseif playerUnit:getUnitData().type == "simpressureplate" and playerUnit.canGlimpseTarget then
            local plateX, plateY = playerUnit:getLocation()
            canSenseUnit = canSenseUnit or
                                   (plateX == x and plateY == y and
                                           playerUnit:canGlimpseTarget(sim, unit))
        end
    end
    return canSeeCell, false, canSenseUnit
end

-- UITR: Override vanilla.
function pcplayer:trackFootstep(sim, unit, cellx, celly)
    -- UITR: Remove "only if player cannot see unit" check. Track all units.

    local unitTraits, unitID = unit:getTraits(), unit:getID()
    -- Hearing
    local closestUnit, closestRange = simquery.findClosestUnit(
            self._units, cellx, celly, simquery.canHear)
    -- Vision
    local canSeeCell, canSeeUnit, canSenseUnit = couldPlayerSeeCellAndUnit(self, unit, cellx, celly)
    local footstep = {
        x = cellx,
        y = celly,
        -- UITR: replace isSeen with "is unit seen" and create a new isCellSeen for this.
        isCellSeen = canSeeCell,

        isSeen = canSeeUnit,
        isHeard = closestRange <= simquery.getMoveSoundRange(unit, sim:getCell(cellx, celly)),
        -- UITR: Instead of 'tagged' setting isHeard, set its own trait.
        -- Also, limit 'known tracked steps' to cells that the player knows. Unknown cells are not
        -- shown for TAGs/observed paths.
        -- simunit:onEndTurn clears getTraits().patrolObserved, so that's already expired.
        -- Fixing that would require figuring out if the path has deviated during the guard turn.
        isTracked = unitTraits.tagged and self:getCell(cellx, celly) ~= nil,
        -- Non-visual/non-aural senses (Neptune pressure plates)
        isSensed = canSenseUnit,
    }

    local footpath = self._footsteps[unitID]
    if footpath == nil then
        footpath = {}
        self._footsteps[unitID] = footpath
    end
    if not footpath.info then
        if not self._nextFootstepsInfo then
            -- Don't crash, but still log how we got here.
            simlog(
                    "[UITR][WARN] Tracking footsteps before player:onEndTurn was called. Some tracking may be missing.%s",
                    (uitr_util.canDebugTrace() and ("\n" .. debug.traceback()) or ""))
            self._nextFootstepsInfo = {}
        end
        footpath.info = self._nextFootstepsInfo[unitID] or {}
    end
    table.insert(footpath, footstep)

    -- UITR: Link confirmed steps of an observed path to the tracks.
    if footpath.info.observedPath then
        local observedNode, observedIdx = array.findIf(
                footpath.info.observedPath, function(n)
                    return n.x == cellx and n.y == celly and not n.observedIdx
                end)
        if observedNode then
            observedNode.isSeen = footstep.isSeen and #footpath
            observedNode.isHeard = footstep.isHeard and #footpath
            observedNode.isTagged = footstep.isTagged and #footpath
            observedNode.isSensed = footstep.isSensed and #footpath
            footstep.observedIdx = observedIdx
        end
    end
    -- simlog(
    --         "[UITR] recordTrack [%d] %d,%d seen=%s heard=%s tagged=%s sensed=%s observeID=%s",
    --         unitID, cellx, celly, tostring(footstep.isSeen), tostring(footstep.isHeard),
    --         tostring(footstep.isTracked), tostring(footstep.isSensed),
    --         tostring(footstep.observedIdx or (footpath.info.observedPath and "nil" or "-")))

    -- UITR: Track if the unit was seen moving at any point on this turn.
    -- Need to also do a hasKnownGhost check in case the unit was seen or glimpsed for other
    -- reasons.
    footpath.info.isSeen = footpath.info.isSeen or footstep.isSeen
    footpath.info.isHeard = footpath.info.isHeard or footstep.isHeard
    footpath.info.isTracked = footpath.info.isTracked or footstep.isTracked
    footpath.info.isSensed = footpath.info.isSensed or footstep.isSensed

    sim:dispatchEvent(simdefs.EV_UNIT_REFRESH_TRACKS, unit:getID())
end

-- Record a unit's observed 'planned path' at end of turn.
-- Based on pathrig:regeneratePath().
--
-- patrolObserved expires at the end of the player turn, unlike TAG which continues to update for
-- any repathing during the guard turn. If not confirmed by the player's own senses, this will be
-- drawn with question marks instead of footprints.
local function recordObservedPath(player, unit)
    local path = unit:getPather():getPath(unit)
    if path and path.path and not path.result then
        local plannedPath
        local movePoints = unit:getTraits().mpMax
        local path = unit:getPather():getPath(unit)
        local moveCostFn = simquery.getMoveCost
        if simquery.getTrueMoveCost then
            moveCostFn = function(cell1, cell2)
                return simquery.getTrueMoveCost(unit, cell1, cell2)
            end
        end

        do
            -- Starting point isn't included by the pather.
            local x, y = unit:getLocation()
            plannedPath = {{x = x, y = y, isObserved = player:getCell(x, y) ~= nil}}
            -- simlog(
            --         "[UITR] recordObserved [%d] %d,%d known=%s", unit:getID(), x, y,
            --         tostring(player:getCell(x, y) ~= nil))
        end
        local prevNode
        for _, node in ipairs(path.path:getNodes()) do
            if movePoints and node and prevNode then
                movePoints = movePoints - moveCostFn(prevNode.location, node.location)
                if movePoints < 0 then
                    break -- that's all the path we have time for right now
                end
            end
            table.insert(
                    plannedPath, {
                        x = node.location.x,
                        y = node.location.y,
                        isObserved = player:getCell(node.location.x, node.location.y) ~= nil,
                    })
            prevNode = node
            -- simlog(
            --         "[UITR] recordObserved [%d] %d,%d known=%s", unit:getID(), node.location.x,
            --         node.location.y,
            --         tostring(player:getCell(node.location.x, node.location.y) ~= nil))
        end
        return plannedPath
    end
end

-- WARNING: pcplayer:onEndTurn isn't overridden in vanilla, so starts as a reference to the vanilla
--   simplayer:onEndTurn. Any appends to simplayer:onEndTurn fail to reach pcplayer.
local oldOnEndTurn = pcplayer.onEndTurn
function pcplayer:onEndTurn(sim)
    -- Record any known units for next turn's footpaths.
    if sim:getCurrentPlayer() == self then
        -- simlog("[UITR] resetTracks %d", sim:getTurnCount())
        self._footsteps = {} -- Also cleared by oldOnEndTurn.
        self._nextFootstepsInfo = {}
        for _, unit in ipairs(self:getSeenUnits()) do
            if simquery.isAgent(unit) and unit:getPlayerOwner() ~= self then
                local info = {isSeen = true}
                if unit:getTraits().patrolObserved then
                    info.observedPath = recordObservedPath(self, unit)
                end
                -- simlog(
                --         "[UITR] recordWasSeen [%d] observed=%s path=%s", unit:getID(),
                --         tostring(unit:getTraits().patrolObserved), tostring(info.plannedPath))
                self._nextFootstepsInfo[unit:getID()] = info
            end
        end
        for unitID, ghostUnit in pairs(self._ghost_units) do
            local knownUnit, unit = uitr_util.getKnownUnitFromGhost(sim, ghostUnit)
            if unit and simquery.isAgent(unit) and unit:getPlayerOwner() ~= self then
                local info = {isSeen = knownUnit ~= nil}
                if unit:getTraits().patrolObserved then
                    info.observedPath = recordObservedPath(self, unit)
                end
                -- simlog(
                --         "[UITR] recordWasGlimpsed [%d] observed=%s path=%s", unit:getID(),
                --         tostring(unit:getTraits().patrolObserved), tostring(info.plannedPath))
                self._nextFootstepsInfo[unit:getID()] = info
            end
        end
    end

    oldOnEndTurn(self, sim)

    if sim:getCurrentPlayer() == self then
        for unitID, info in pairs(self._nextFootstepsInfo) do
            if info.observedPath then
                self._footsteps[unitID] = {info = info}
            end
        end
    end
end
