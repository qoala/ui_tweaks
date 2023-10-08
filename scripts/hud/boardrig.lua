local boardrig = include("gameplay/boardrig")
local cdefs = include("client_defs")
local resources = include("resources")
local array = include("modules/array")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local util = include("modules/util")
local mathutil = include("modules/mathutil")

local cbf_util = SCRIPT_PATHS and SCRIPT_PATHS.qoala_commbugfix and
                         include(SCRIPT_PATHS.qoala_commbugfix .. "/cbf_util")
local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

-- ===

-- Returns the real unit if the player has the correct location for the provided ghost unit.
-- Otherwise, returns nil.
-- Same criteria as the vanilla SHIFT keybind to inspect watched cells.
local function getKnownUnitFromGhost(sim, ghostUnit)
    local unit = sim:getUnit(ghostUnit:getID())
    if unit then
        local gx, gy = ghostUnit:getLocation()
        local x, y = unit:getLocation()
        if x == gx and y == gy then
            return unit
        end
    end
end

-- True if unit is either seen or known from a ghost as above.
local function playerKnowsUnit(player, unit)
    if array.find(player:getSeenUnits(), unit) then
        return true
    end

    local originalID = unit:getID()
    if player._ghost_units then
        for unitID, ghost in pairs(player._ghost_units) do
            if unitID == originalID then
                local gx, gy = ghost:getLocation()
                local x, y = unit:getLocation()
                return x == gx and y == gy
            end
        end
    end
end

-- ===
-- Overwatch Preview

local function predictLOS(sim, unit, facing)
    local startCell = sim:getCell(unit:getLocation())
    local halfArc = simquery.getLOSArc(unit) / 2
    local distance = unit:getTraits().LOSrange
    local facingRads = unit:getTraits().LOSrads or (math.pi / 4 * facing)

    local cells = sim:getLOS():calculateLOS(startCell, facingRads, halfArc, distance)

    local cbfFixMagic = cbf_util and cbf_util.simCheckFlag(sim, "cbf_fixmagicsight")

    -- (magic vision)
    if unit:getTraits().LOSrads == nil and facing % 2 == 1 and (not cbfFixMagic or not unit:isPC()) then
        -- MAGICAL SIGHT.  On a diagonal facing, see the adjacent two cells.
        local exit1 = startCell.exits[(facing + 1) % simdefs.DIR_MAX]
        if simquery.isOpenExit(exit1) and
                (not cbfFixMagic or simquery.couldUnitSeeCell(sim, unit, exit1.cell)) then
            cells[simquery.toCellID(exit1.cell.x, exit1.cell.y)] = exit1.cell
        end
        local exit2 = startCell.exits[(facing - 1) % simdefs.DIR_MAX]
        if simquery.isOpenExit(exit2) and
                (not cbfFixMagic or simquery.couldUnitSeeCell(sim, unit, exit2.cell)) then
            cells[simquery.toCellID(exit2.cell.x, exit2.cell.y)] = exit2.cell
        end

    elseif unit:getTraits().LOSarc and unit:getTraits().LOSarc >= 2 * math.pi and
            (not cbfFixMagic or unit:isPC()) then
        for _, dir in ipairs(simdefs.DIR_SIDES) do
            local exit1 = startCell.exits[dir]
            if simquery.isOpenExit(exit1) then
                cells[simquery.toCellID(exit1.cell.x, exit1.cell.y)] = exit1.cell
            end
        end
    elseif unit:getTraits().LOSrads == nil and facing % 2 == 0 and cbfFixMagic and not unit:isPC() then
        -- MAGICAL SIGHT.  CBF adds the directly faced tile orthogonally, even if the unit's vision
        -- arc is too narrow to see that normally.
        local exit = startCell.exits[facing]
        if simquery.isOpenExit(exit) and simquery.couldUnitSeeCell(sim, unit, exit.cell) then
            cells[simquery.toCellID(exit.cell.x, exit.cell.y)] = exit.cell
        end
    end

    return cells
end

local function predictPeripheralLOS(sim, unit, predictedFacing)
    if not unit:getTraits().LOSperipheralArc then
        return {}
    end
    local startCell = sim:getCell(unit:getLocation())
    local halfArc = unit:getTraits().LOSperipheralArc / 2
    local distance = unit:getTraits().LOSperipheralRange
    local facingRads = unit:getTraits().LOSrads or (math.pi / 4 * predictedFacing)

    return sim:getLOS():calculateLOS(startCell, facingRads, halfArc, distance)
end

-- Memoize LOS for predicted threat facings
local function trackerPredictLos(self, facing)
    if self._losByFacing[facing] then
        return self._losByFacing[facing]
    end

    local cells = predictLOS(self._sim, self.threat, facing)
    self._losByFacing[facing] = cells
    return cells
end

-- Memoize peripheral LOS for predicted threat facings
local function trackerPredictPeripheralLos(self, facing)
    if self._peripheralLosByFacing[facing] then
        return self._peripheralLosByFacing[facing]
    end

    local cells = predictPeripheralLOS(self._sim, self.threat, facing)
    self._peripheralLosByFacing[facing] = cells
    return cells
end

-- Guards can have lost targets despite no longer being in the aiming state.
local function unitHasLostTarget(threatUnit, selectedUnit)
    local brain = threatUnit:getBrain()
    local senses = brain and brain:getSenses()
    return senses and senses:hasLostTarget(selectedUnit)
end

local function checkPotentialThreat(unit, sim, selectedUnit, guardThreats, turretThreats)
    if simquery.isEnemyAgent(unit:getPlayerOwner(), selectedUnit) and
            (unit:isAiming() or unit:getTraits().skipOverwatch or
                    unitHasLostTarget(unit, selectedUnit)) and not unit:getTraits().pacifist then
        -- Note: Most logic is just for guards/drones. Turrets don't actually track around the edge of their vision!
        if unit:getBrain() then
            local senses = unit:getBrain():getSenses()
            if senses:hasTarget(selectedUnit) then
                local tracker = {
                    threat = unit,
                    facing = unit:getFacing(),
                    tracking = true,
                    inSight = true,
                    willShoot = unit:isAiming() or unit:getTraits().skipOverwatch,
                    _sim = sim,
                    _losByFacing = {},
                    _peripheralLosByFacing = {},
                    predictLos = trackerPredictLos,
                    predictPeripheralLos = trackerPredictPeripheralLos,
                }
                table.insert(guardThreats, tracker)
                -- simlog("LOG_UITR_OW", "threat %s[%s] f=%s t=%s s=%s", unit:getName(), unit:getID(), tracker.facing, tostring(tracker.tracking), tostring(tracker.inSight))
            elseif senses:hasLostTarget(selectedUnit) then
                local tracker = {
                    threat = unit,
                    facing = unit:getFacing(),
                    tracking = true,
                    inSight = false,
                    willShoot = unit:isAiming() or unit:getTraits().skipOverwatch,
                    _sim = sim,
                    _losByFacing = {},
                    _peripheralLosByFacing = {},
                    predictLos = trackerPredictLos,
                    predictPeripheralLos = trackerPredictPeripheralLos,
                }
                table.insert(guardThreats, tracker)
                -- simlog("LOG_UITR_OW", "threat %s[%s] f=%s t=%s s=%s", unit:getName(), unit:getID(), tracker.facing, tostring(tracker.tracking), tostring(tracker.inSight))
            else
                local tracker = {
                    threat = unit,
                    facing = unit:getFacing(),
                    tracking = false,
                    inSight = false,
                    willShoot = unit:isAiming() or unit:getTraits().skipOverwatch,
                    _sim = sim,
                    _losByFacing = {},
                    _peripheralLosByFacing = {},
                    predictLos = trackerPredictLos,
                    predictPeripheralLos = trackerPredictPeripheralLos,
                }
                table.insert(guardThreats, tracker)
                -- simlog("LOG_UITR_OW", "threat %s[%s] f=%s t=%s s=%s", unit:getName(), unit:getID(), tracker.facing, tostring(tracker.tracking), tostring(tracker.inSight))
            end
        else
            local tracker = {
                threat = unit,
                facing = unit:getFacing(),
                _sim = sim,
                _losByFacing = {},
                _peripheralLosByFacing = {},
                predictLos = trackerPredictLos,
                predictPeripheralLos = trackerPredictPeripheralLos,
            }
            table.insert(turretThreats, tracker)
            -- simlog("LOG_UITR_OW", "turret %s[%s] f=%s t=%s s=%s", unit:getName(), unit:getID(), tracker.facing, tostring(tracker.tracking), tostring(tracker.inSight))
        end
    end
end
local function findThreats(sim, selectedUnit)
    local guardThreats = {}
    local turretThreats = {}
    local player = selectedUnit:getPlayerOwner()
    if not player then
        return guardThreats, turretThreats
    end

    -- Consider units the player can see
    for _, unit in ipairs(player:getSeenUnits()) do
        checkPotentialThreat(unit, sim, selectedUnit, guardThreats, turretThreats)
    end
    -- and ghost echoes that the player has the correct location for. (Same criteria as the vanilla SHIFT keybind)
    if player._ghost_units then
        for unitID, ghost in pairs(player._ghost_units) do
            local unit = getKnownUnitFromGhost(sim, ghost)
            if unit then
                checkPotentialThreat(unit, sim, selectedUnit, guardThreats, turretThreats)
            end
        end
    end

    return guardThreats, turretThreats
end

local function checkForNewGuardThreats(sim, selectedUnit, guardThreats, cell)
    -- Pathing through a guard adds Henry to their lost targets list.
    local player = selectedUnit:getPlayerOwner()

    for _, cellUnit in ipairs(cell.units) do
        if simquery.isEnemyAgent(player, cellUnit) and cellUnit:getBrain() and
                not cellUnit:getTraits().pacifist and playerKnowsUnit(player, cellUnit) then
            local tracker = array.findIf(
                    guardThreats, function(t)
                        return t.threat == cellUnit
                    end)

            if tracker then
                tracker.tracking = true
            else
                tracker = {
                    threat = cellUnit,
                    facing = cellUnit:getFacing(),
                    tracking = true,
                    inSight = false,
                    willShoot = cellUnit:isAiming() or cellUnit:getTraits().skipOverwatch,
                    _sim = sim,
                    _losByFacing = {},
                    _peripheralLosByFacing = {},
                    predictLos = trackerPredictLos,
                    predictPeripheralLos = trackerPredictPeripheralLos,
                }
                table.insert(guardThreats, tracker)
            end
        end
    end
end

-- Predict couldUnitSee value, including modded movement-based modifiers.
local function predictCouldUnitSee(sim, threat, unit, ignoreCover, cell)
    if unit:getTraits().ITB_HenryImpass then
        local x0, y0 = threat:getLocation()
        -- Into the Breach's Henry isn't seen by units while moving through their cell.
        if x0 == cell.x and y0 == cell.y then
            return false
        end
    end
    return simquery.couldUnitSee(sim, threat, unit, ignoreCover, cell)
end

local function isWatchedByTurret(sim, turretThreats, selectedUnit, cell)
    local foundThreat = nil
    for _, tracker in ipairs(turretThreats) do
        local threat = tracker.threat
        local watchedCells = tracker:predictLos(tracker.facing)
        local couldSee = predictCouldUnitSee(sim, threat, selectedUnit, false, cell)

        if couldSee and watchedCells[cell.id] then
            local tx, ty = threat:getLocation()
            tracker.facing = simquery.getDirectionFromDelta(cell.x - tx, cell.y - ty)
            foundThreat = threat
        end
    end
    return foundThreat
end

-- Predict how each guard will react to this movement step.
local function isWatchedByGuard(sim, guardThreats, selectedUnit, cell, prevCell)
    local foundThreat = nil
    local foundShout = nil
    for _, tracker in ipairs(guardThreats) do
        local threat = tracker.threat
        local tx, ty = threat:getLocation()
        local facing = simquery.getDirectionFromDelta(cell.x - tx, cell.y - ty)
        local couldSee = predictCouldUnitSee(sim, threat, selectedUnit, false, cell)

        -- Senses:processWarpTrigger
        -- Predict if the movement itself updates facing
        if tracker.inSight then
            -- Was already watched in the previous cell
            -- Threat will turn towards the destination.
            -- (senses:729 `if self:hasTarget // and prevCanSee`)
            if facing < simdefs.DIR_MAX then
                simlog(
                        "LOG_UITR_OW", "  %s,%s-%s,%s %s[%s] TRACK f=%s->%s",
                        prevCell and prevCell.x or "*", prevCell and prevCell.y or "*", cell.x,
                        cell.y, threat:getName(), threat:getID(), tracker.facing, facing)
                tracker.facing = facing
            else
                -- simUnit:turnToFace no-ops when given the unit's own location.
                simlog(
                        "LOG_UITR_OW", "  %s,%s-%s,%s %s[%s] INTERSECT f=%s",
                        prevCell and prevCell.x or "*", prevCell and prevCell.y or "*", cell.x,
                        cell.y, threat:getName(), threat:getID(), tracker.facing)
            end
        elseif couldSee and tracker:predictLos(tracker.facing)[cell.id] then
            -- We just stepped into main vision.
            -- No facing changes in processWarpTrigger. (`not canSee` on below checks)
        elseif tracker.tracking and prevCell and
                not simquery.checkCover(sim, threat, prevCell.x, prevCell.y) then
            -- Threat is eligible to turn if peripheral checks pass
            -- (senses:769 `if self:hasLostTarget(...) and not simquery.checkCover(...)`)

            if couldSee and tracker:predictPeripheralLos(tracker.facing)[cell.id] then
                -- We just stepped into peripheral from a non-cover cell.
                -- Threat will turn to face this cell.
                -- (senses:749 `if not canSee and canSense`)
                simlog(
                        "LOG_UITR_OW", "  %s,%s-%s,%s %s[%s] PRETURN-A f=%s->%s", prevCell.x,
                        prevCell.y, cell.x, cell.y, threat:getName(), threat:getID(),
                        tracker.facing, facing)
                tracker.facing = facing
            elseif predictCouldUnitSee(sim, threat, selectedUnit, false, prevCell) and
                    not tracker:predictLos(tracker.facing)[prevCell.id] and
                    tracker:predictPeripheralLos(tracker.facing)[prevCell.id] then
                -- We just stepped out of peripheral.
                -- Threat will turn to face the previous cell.
                -- (senses:761 `elseif not canSee and not canSense // and simquery.couldUnitSee(... prevCell) // and not prevCanSee and prevCanSense`)
                local prevCellFacing = simquery.getDirectionFromDelta(
                        prevCell.x - tx, prevCell.y - ty)
                simlog(
                        "LOG_UITR_OW", "  %s,%s-%s,%s %s[%s] PRETURN-B f=%s->%s", prevCell.x,
                        prevCell.y, cell.x, cell.y, threat:getName(), threat:getID(),
                        tracker.facing, prevCellFacing)
                tracker.facing = prevCellFacing
                -- else
                -- 	simlog("LOG_UITR_OW", "  %s,%s-%s,%s %s[%s] no-change prevSee=%s prevSense=%s nowSense=%s nowSee=%s", prevCell and prevCell.x or "*", prevCell and prevCell.y or "*", cell.x, cell.y, threat:getName(), threat:getID(), tostring(tracker:predictLos(tracker.facing)[prevCell.id]), tostring(tracker:predictPeripheralLos(tracker.facing)[prevCell.id]), tostring(tracker:predictPeripheralLos(tracker.facing)[cell.id]), tostring(couldSee))
            end
            -- elseif tracker.tracking and prevCell then
            -- 	simlog("LOG_UITR_OW", "  %s,%s-%s,%s %s[%s] no-change prevCover=%s nowSense=%s nowSee=%s", prevCell.x, prevCell.y, cell.x, cell.y, threat:getName(), threat:getID(),tostring(simquery.checkCover(sim, threat, prevCell.x, prevCell.y)), tostring(tracker:predictPeripheralLos(tracker.facing)[cell.id]), tostring(couldSee))
        end
        -- (else) Threat is watching cells based on last known facing.

        -- Senses:processAppearedTrigger and actions.ReactToTarget / Senses:processDisappearedTrigger
        if couldSee and tracker:predictLos(tracker.facing)[cell.id] then
            -- (senses:594 `if not self:hasTarget(...) // and simquery.isEnemyTarget(...) or simquery.isKnownTraitor` => Target)
            -- Threat sees us. Now or still a target.
            simlog(
                    "LOG_UITR_OW", "  %s,%s-%s,%s %s[%s] WATCH f=%s->%s",
                    prevCell and prevCell.x or "*", prevCell and prevCell.y or "*", cell.x, cell.y,
                    threat:getName(), threat:getID(), tracker.facing, facing)
            tracker.tracking = true
            tracker.inSight = true
            tracker.facing = facing -- Technically, if multiple targets, threat only turns if we won priority in Senses:pickBestTarget.
            if tracker.willShoot then
                foundThreat = foundThreat or threat
            else
                foundShout = foundShout or threat
            end
        elseif tracker.inSight then
            simlog(
                    "LOG_UITR_OW", "  %s,%s-%s,%s %s[%s] LOST f=%s", prevCell and prevCell.x or "*",
                    prevCell and prevCell.y or "*", cell.x, cell.y, threat:getName(),
                    threat:getID(), tracker.facing)
            -- Was previously in sight. Now a lost target.
            tracker.inSight = false
        end
    end
    return foundThreat, foundShout
end

local function clearLosCache(guardThreats, turretThreats)
    for _, tracker in ipairs(guardThreats) do
        -- Clear LOS cache
        tracker._losByFacing = {}
        tracker._peripheralLosByFacing = {}
    end
    for _, tracker in ipairs(turretThreats) do
        -- Clear LOS cache
        tracker._losByFacing = {}
        tracker._peripheralLosByFacing = {}
    end
end

local function predictDoorOpening(sim, tempDoors, prevCell, cell)
    local dir = simquery.getDirectionFromDelta(cell.x - prevCell.x, cell.y - prevCell.y)
    local willOpen = (prevCell.exits[dir] and prevCell.exits[dir].door and
                             prevCell.exits[dir].closed)

    if willOpen then
        local rdir = simquery.getReverseDirection(dir)
        table.insert(tempDoors, {prevCell = prevCell, dir = dir, cell = cell, rdir = rdir})

        sim:getLOS():removeSegments(prevCell, dir, cell, rdir)
        prevCell.exits[dir].closed = nil
        cell.exits[rdir].closed = nil
    end

    return willOpen
end

local function restoreDoors(sim, tempDoors)
    for _, door in ipairs(tempDoors) do
        sim:getLOS():insertSegments(door.prevCell, door.dir, door.cell, door.rdir)
        door.prevCell.exits[door.dir].closed = true
        door.cell.exits[door.rdir].closed = true
    end
end

local function newShootProp(self, cell, color, icon)
    local shootTex = resources.find(icon or "uitrShoot")
    local x, y = self:cellToWorld(cell.x, cell.y)

    local prop = MOAIProp2D.new()
    prop:setDeck(shootTex)
    prop:setLoc(x, y)
    if color then
        prop:setColor(color.r, color.g, color.b, color.a)
    else
        prop:setColor(cdefs.COLOR_WATCHED_BOLD:unpack())
    end
    return prop
end

local function UITRpreviewOverwatch(self, selectedUnit, cells, color, id)
    local sim = self:getSim()

    -- Identify threats that could shoot us.
    local guardThreats, turretThreats = findThreats(sim, selectedUnit)
    -- If not ITB Henry scurrying mid-path, movement is always stopped before getting shot, so no
    -- threats is safe.
    local isITBHenry = selectedUnit:getTraits().ITB_HenryImpass
    if not next(guardThreats) and not next(turretThreats) and not isITBHenry then
        return
    end

    simlog("LOG_UITR_OW", "overwatchTracking ===========")

    -- Mark movement cells that get us shot.
    local fgProps = {}
    local tempDoors = {}
    local prevCell = nil
    local prevCellThreat = nil
    for _, coord in ipairs(cells) do
        local cell = sim:getCell(coord.x, coord.y)
        if prevCell and predictDoorOpening(sim, tempDoors, prevCell, cell) then
            simlog("LOG_UITR_OW", "   door %s,%s %s,%s", prevCell.x, prevCell.y, cell.x, cell.y)
            clearLosCache(guardThreats, turretThreats)

            local doorIsWatched =
                    (isWatchedByGuard(sim, guardThreats, selectedUnit, prevCell, nil) or
                            isWatchedByTurret(sim, turretThreats, selectedUnit, prevCell))
            if not prevCellThreat and doorIsWatched then
                simlog("LOG_UITR_OW", "   shot %s,%s", prevCell.x, prevCell.y)
                table.insert(fgProps, newShootProp(self, prevCell, color))
            end
        end

        if not prevCell then
            -- Don't mark the origin cell of the path, even if it's obviously watched.
            prevCellThreat = false
            -- We still want to update possible peripheral rotations though.
            -- isWatchedByGuard(sim, guardThreats, selectedUnit, cell, nil)
        else
            local guardWatch, guardShout = isWatchedByGuard(
                    sim, guardThreats, selectedUnit, cell, prevCell)
            local cellIsWatched = (guardWatch or
                                          isWatchedByTurret(sim, turretThreats, selectedUnit, cell))
            if cellIsWatched then
                simlog("LOG_UITR_OW", "   shot %s,%s", cell.x, cell.y)
                table.insert(fgProps, newShootProp(self, cell, color))
                prevCellThreat = true
            elseif guardShout then
                simlog("LOG_UITR_OW", "   shot %s,%s", cell.x, cell.y)
                local prop = newShootProp(self, cell, color, "uitrShoutAlert")
                local tx, ty = guardShout:getLocation()
                local dx, dy = cell.x - tx, cell.y - ty
                local theta = math.atan2(-dx, dy)
                prop:setRot(math.deg(theta))
                table.insert(fgProps, prop)
                prevCellThreat = true
            else
                prevCellThreat = false
            end

            if isITBHenry then
                checkForNewGuardThreats(sim, selectedUnit, guardThreats, cell)
            end
        end
        prevCell = cell
    end
    restoreDoors(sim, tempDoors)

    local layer = self:getLayer("ceiling")
    for _, prop in ipairs(fgProps) do
        layer:insertProp(prop)
    end
    self._chainCells[id].fgProps = fgProps

    simlog("LOG_UITR_OW", "overwatchTracking END ===========")
end

-- ===
-- Sprint preview

local function pathMakesNoise(sim, unit, path)
    for _, coord in ipairs(path) do
        local c = sim:getCell(coord.x, coord.y)
        if simquery.getMoveSoundRange(unit, c) > 0 then
            return true
        end
    end
end

local function UITRpreviewSprintNoise(boardrig, unit, path, id)
    local sim = boardrig:getSim()
    local displayOption = uitr_util.checkOption("sprintNoisePreview")
    local markUnits, markRadius = false
    if displayOption == 1 then
        markUnits = true
    elseif displayOption == 2 then
        markRadius = true
    elseif displayOption == 3 then
        markUnits = true
        markRadius = true
    end

    -- only show if distance is sprintable
    if not boardrig._game.hud._bValidMovement then
        return
    end
    -- only show if the unit has a path that can make noise
    if not unit or not path or not pathMakesNoise(sim, unit, path) then
        return
    end
    -- only show if in tactical view; that'd need to be coupled with tac view toggle amendments
    --[[if not boardrig._game:getGfxOptions().bTacticalView then
        return
    end]]

    -- remove cell we're at; we won't make noise from it
    local pathCells = util.tcopy(path)
    local coords = table.remove(pathCells, 1)
    local originCell = sim:getCell(coords.x, coords.y)

    -- For each tile in path, add known tiles in a radius (r = sprintNoise) to a list.
    -- Also track the units in radius of the last cell (current cursor position).
    local cells, units, hasAnyUnits = {}, {}, false
    local focusCells, hasFocusUnits = {}, false

    local lastPathIdx = #pathCells
    for pathIdx, cellCoords in ipairs(pathCells) do
        -- Matches range-check in Senses and simsoundbug, not simquery.fillCircle().
        local xOrigin, yOrigin = cellCoords.x, cellCoords.y
        local radius = simquery.getMoveSoundRange(unit, sim:getCell(xOrigin, yOrigin))
        local x0, y0 = math.min((xOrigin - radius), 0), math.min((yOrigin - radius), 0)
        local x1, y1 = xOrigin + radius, yOrigin + radius
        local isFocus = pathIdx == lastPathIdx
        for x = x0, x1 do
            for y = y0, y1 do
                local cell = sim:getCell(x, y)
                -- criteria:
                -- cell wasn't already added to our list
                -- within noise radius
                -- cell is currently seen OR has been glimpsed before
                if cell and (not cells[cell.id] or isFocus) and
                        (mathutil.dist2d(xOrigin, yOrigin, x, y) <= radius) and
                        (boardrig:canPlayerSee(x, y) or
                                unit:getPlayerOwner()._ghost_cells[simquery.toCellID(x, y)]) then
                    cells[cell.id] = cell
                    if isFocus then
                        focusCells[cell.id] = cell
                    end
                end
            end
        end
    end

    -- get only the tiles with hearing-enabled, known enemy units on them; this can include ghosts
    for _, cell in pairs(cells) do
        local isFocus = nil
        if focusCells[cell.id] then
            isFocus = true
        end

        if sim:canPlayerSee(sim:getPC(), cell.x, cell.y) then
            -- check real units
            for _, unit in ipairs(cell.units) do
                if unit:getTraits().hasHearing and sim:canPlayerSeeUnit(sim:getPC(), unit) and
                        unit:getPlayerOwner() ~= sim:getPC() and not unit:isDown() then
                    table.insert(units, unit)
                    hasAnyUnits = true
                    hasFocusUnits = hasFocusUnits or isFocus
                end
            end
        else
            -- check ghost units
            local ghostCell = sim:getPC()._ghost_cells[simquery.toCellID(cell.x, cell.y)]
            for _, ghostUnit in ipairs(ghostCell.units) do
                local unit = getKnownUnitFromGhost(sim, ghostUnit)
                if unit and ghostUnit:getTraits().hasHearing and ghostUnit:getPlayerOwner() ~=
                        sim:getPC() and not unit:isDown() then
                    table.insert(units, unit)
                    hasAnyUnits = true
                    hasFocusUnits = hasFocusUnits or isFocus
                end
            end
        end
    end

    if markUnits then
        local sprintProps = {}
        for _, target in ipairs(units) do
            local targetrig = boardrig:getUnitRig(target:getID())
            local x, y = target:getLocation()
            wx, wy = boardrig:cellToWorld(x, y)

            -- Add overhead indicator to all units that will hear the movement.
            local prop = targetrig:createHUDProp(
                    "kanim_soundbug_overlay_alarm", "character", "alarm_loop",
                    boardrig:getLayer("ceiling"), nil, wx, wy)

            local r, g, b, a = 247 / 255, 247 / 255, 142 / 255, 1
            prop:setSymbolModulate("cicrcle_wave", r, g, b, a)
            prop:setSymbolModulate("line_1", r, g, b, a)
            prop:setSymbolModulate("ring", r, g, b, a)
            prop:setSymbolModulate("attention_ring", r, g, b, a)

            table.insert(sprintProps, prop)

            -- Highlight any units in the immediate radius. Not as noticeable under the overhead mark.
            --[[if focusUnits[target:getID()] then
                targetrig._prop:setRenderFilter(cdefs.RENDER_FILTERS["uitr_focus_penalty"])
            end]]
        end
        boardrig._chainCells[id].sprintProps = sprintProps
    end

    if markRadius then
        -- Highlight tiles in sound range of the cursor.
        -- Hilite code expects a flat stream of x and y values.
        local hCells = {}
        for _, cell in pairs(focusCells) do
            table.insert(hCells, cell.x)
            table.insert(hCells, cell.y)
        end

        local hClr
        if hasFocusUnits then
            -- Radius is important.
            hClr = {0.3, 0.3, 0.3, 0.3}
        elseif hasAnyUnits then
            -- Radius is somewhat important.
            hClr = {0.15, 0.15, 0.15, 0.15}
        else
            -- Radius is probably irrelevant.
            hClr = {0.08, 0.08, 0.08, 0.08}
        end

        local hiliteID = boardrig:hiliteCells(hCells, hClr)
        boardrig._chainCells[id].sprintHilite = hiliteID
    end
end

-- ===

local oldChainCells = boardrig.chainCells
local oldUnchainCells = boardrig.unchainCells

function boardrig:chainCells(cells, color, ...)
    local selectedUnit = self._game.hud:getSelectedUnit()
    local id = oldChainCells(self, cells, color, ...)

    if selectedUnit and uitr_util.checkOption("sprintNoisePreview") then
        UITRpreviewSprintNoise(self, selectedUnit, cells, id)
    end
    if selectedUnit and uitr_util.checkOption("overwatchMovement") then
        UITRpreviewOverwatch(self, selectedUnit, cells, color, id)
    end

    return id
end

function boardrig:unchainCells(id, ...)
    local chain = self._chainCells[id]
    if chain and chain.fgProps then
        local layer = self:getLayer("ceiling")
        for _, prop in ipairs(chain.fgProps) do
            layer:removeProp(prop)
        end
    end
    if chain and chain.sprintProps then
        local layer = self:getLayer("ceiling")
        for _, prop in ipairs(chain.sprintProps) do
            layer:removeProp(prop)
        end
    end
    if chain and chain.sprintHilite then
        self:unhiliteCells(chain.sprintHilite)
    end

    oldUnchainCells(self, id, ...)
end

-- Overwrite selectUnit
-- Changes at UITR: Don't fail to deselect debug units without rigs.
function boardrig:selectUnit(unit)
    if unit ~= self.selectedUnit then
        if self.selectedUnit and self.selectedUnit:isValid() then
            local unitRig = self:getUnitRig(self.selectedUnit:getID())
            -- UITR: nil check on unitRig. (on the other side, isAgent is sufficient)
            if unitRig and unitRig.selectedToggle then
                unitRig:selectedToggle(false)
            end
        end
        if unit and unit:isValid() and unit:getTraits().isAgent then
            local unitRig = self:getUnitRig(unit:getID())
            if unitRig.selectedToggle then
                unitRig:selectedToggle(true)
            end
        end
    end
    self.selectedUnit = unit
end

function boardrig:uitr_onDraw()
    if self._uitr_sprintHiliteCells then
        MOAIGfxDevice.setPenColor(unpack(self._uitr_sprintHiliteClr))
        for _, cell in pairs(self._uitr_sprintHiliteCells) do
            local x0, y0 = self._game:cellToWorld(cell.x + 0.4, cell.y + 0.4)
            local x1, y1 = self._game:cellToWorld(cell.x - 0.4, cell.y - 0.4)
            MOAIDraw.fillRect(x0, y0, x1, y1)
        end
    end
end
