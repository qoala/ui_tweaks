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

-- ===

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
        for i, dir in ipairs(simdefs.DIR_SIDES) do
            local exit1 = startCell.exits[dir]
            if simquery.isOpenExit(exit1) then
                cells[simquery.toCellID(exit1.cell.x, exit1.cell.y)] = exit1.cell
            end
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

local function checkPotentialThreat(unit, sim, selectedUnit, guardThreats, turretThreats)
    if simquery.isEnemyAgent(unit:getPlayerOwner(), selectedUnit) and
            (unit:isAiming() or unit:getTraits().skipOverwatch) and not unit:getTraits().pacifist then
        -- Note: Most logic is just for guards/drones. Turrets don't actually track around the edge of their vision!
        if unit:getBrain() then
            local senses = unit:getBrain():getSenses()
            if senses:hasTarget(selectedUnit) then
                local tracker = {
                    threat = unit,
                    facing = unit:getFacing(),
                    tracking = true,
                    inSight = true,
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

local function isWatchedByTurret(sim, turretThreats, selectedUnit, cell)
    local foundThreat = nil
    for _, tracker in ipairs(turretThreats) do
        local threat = tracker.threat
        local watchedCells = tracker:predictLos(tracker.facing)
        local couldSee = simquery.couldUnitSee(sim, threat, selectedUnit, false, cell)

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
    for _, tracker in ipairs(guardThreats) do
        local threat = tracker.threat
        local tx, ty = threat:getLocation()
        local facing = simquery.getDirectionFromDelta(cell.x - tx, cell.y - ty)
        local couldSee = simquery.couldUnitSee(sim, threat, selectedUnit, false, cell)

        -- Senses:processWarpTrigger
        -- Predict if the movement itself updates facing
        if tracker.inSight then
            -- Was already watched in the previous cell
            -- Threat will turn towards the destination.
            -- (senses:729 `if self:hasTarget // and prevCanSee`)
            simlog(
                    "LOG_UITR_OW", "  %s,%s-%s,%s %s[%s] TRACK f=%s->%s",
                    prevCell and prevCell.x or "*", prevCell and prevCell.y or "*", cell.x, cell.y,
                    threat:getName(), threat:getID(), tracker.facing, facing)
            tracker.facing = facing
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
            elseif simquery.couldUnitSee(sim, threat, selectedUnit, false, prevCell) and
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
            foundThreat = foundThreat or threat
        elseif tracker.inSight then
            simlog(
                    "LOG_UITR_OW", "  %s,%s-%s,%s %s[%s] LOST f=%s", prevCell and prevCell.x or "*",
                    prevCell and prevCell.y or "*", cell.x, cell.y, threat:getName(),
                    threat:getID(), tracker.facing)
            -- Was previously in sight. Now a lost target.
            tracker.inSight = false
        end
    end
    return foundThreat
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

local function newShootProp(self, cell, color)
    local shootTex = resources.find("uitrShoot")
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

-- ===

local SPRINT_HILITE_CLR = {142 / 255, 247 / 255, 142 / 255, 1} -- 247, 247, 142 = sprint colour

local function UITRpreviewSprintNoise(boardrig, unit, path, id)
    local pathCells = util.tcopy(path)
    local sim = boardrig:getSim()
    local sprintNoise = unit:getTraits().dashSoundRange
    -- only show for sprinting units, and only if we know the path
    if not unit or unit:getTraits().sneaking or not pathCells then
        return
    end
    -- only show if distance is sprintable
    if not boardrig._game.hud._bValidMovement then
        return
    end
    -- only show if in tactical view; that'd need to be coupled with tac view toggle amendments
    --[[if not boardrig._game:getGfxOptions().bTacticalView then
        return
    end]]

    -- remove cell we're at; we won't make noise from it
    local coords = table.remove(pathCells, 1)
    local originCell = sim:getCell(coords.x, coords.y)

    -- for each tile in path, add known tiles in a radius (r = sprintNoise) to a list 
    local cells, units = {}, {}

    for i, cellCoords in ipairs(pathCells) do
        -- Matches range-check in Senses and simsoundbug, not simquery.fillCircle().
        local xOrigin, yOrigin = cellCoords.x, cellCoords.y
        local x0, y0 = math.min((xOrigin - sprintNoise), 0), math.min((yOrigin - sprintNoise), 0)
        local x1, y1 = xOrigin + sprintNoise, yOrigin + sprintNoise
        for x = x0, x1 do
            for y = y0, y1 do
                local distance = mathutil.dist2d(xOrigin, yOrigin, x, y)
                local cell = sim:getCell(x, y)
                -- criteria:
                -- radius of SPRINTNOISE
                -- cell exists, is currently seen OR has been glimpsed before
                -- cell wasn't already added to our list
                if distance <= sprintNoise and cell and
                        (boardrig:canPlayerSee(x, y) or
                                unit:getPlayerOwner()._ghost_cells[simquery.toCellID(x, y)]) and
                        not array.find(cells, cell) then
                    table.insert(cells, cell)
                end
            end
        end
    end

    -- get only the tiles with hearing-enabled, known enemy units on them; this can include ghosts
    for i, cell in ipairs(cells) do
        if sim:canPlayerSee(sim:getPC(), cell.x, cell.y) then
            -- check real units
            for i, unit in ipairs(cell.units) do
                if unit:getTraits().hasHearing and sim:canPlayerSeeUnit(sim:getPC(), unit) and
                        unit:getPlayerOwner() ~= sim:getPC() then
                    table.insert(units, unit)
                end
            end
        else
            -- check ghost units
            local ghostCell = sim:getPC()._ghost_cells[simquery.toCellID(cell.x, cell.y)]
            for i, ghostUnit in ipairs(ghostCell.units) do
                local unit = getKnownUnitFromGhost(sim, ghostUnit)
                if unit and ghostUnit:getTraits().hasHearing and ghostUnit:getPlayerOwner() ~=
                        sim:getPC() then
                    table.insert(units, unit)
                end
            end
        end
    end

    local sprintProps = {}

    for i, target in pairs(units) do
        local targetrig = boardrig:getUnitRig(target:getID())
        local x, y = target:getLocation()
        wx, wy = boardrig:cellToWorld(x, y)
        -- tested: highlighting the unit itself (would have to be undone via rig:refresh())
        --[[targetrig._prop:setRenderFilter({
            shader = KLEIAnim.SHADER_FOW,
            r = 142/255,
            g = 247/255, 
            b = 142/255,
            a = 1,
            lum = 1.3
        })]]
        local prop = targetrig:createHUDProp(
                "kanim_soundbug_overlay_alarm", "character", "alarm_loop",
                boardrig:getLayer("ceiling"), nil, wx, wy)

        prop:setSymbolModulate("cicrcle_wave", 247 / 255, 247 / 255, 142 / 255, 1)
        prop:setSymbolModulate("line_1", 247 / 255, 247 / 255, 142 / 255, 1)
        prop:setSymbolModulate("ring", 247 / 255, 247 / 255, 142 / 255, 1)
        prop:setSymbolModulate("attention_ring", 247 / 255, 247 / 255, 142 / 255, 1)

        table.insert(sprintProps, prop)
    end

    -- highlight each tile in the list
    -- local hiliteID = boardrig:hiliteCells( preCells, SPRINT_HILITE_CLR )
    -- boardrig._UITRSprintHilite = hiliteID

    boardrig._chainCells[id].sprintProps = sprintProps
end

-- ===

local oldChainCells = boardrig.chainCells
local oldUnchainCells = boardrig.unchainCells

function boardrig:chainCells(cells, color, ...)
    local selectedUnit = self._game.hud:getSelectedUnit()
    local sim = self:getSim()
    local id = oldChainCells(self, cells, color, ...)

    if selectedUnit and uitr_util.checkOption("sprintNoisePreview") then
        UITRpreviewSprintNoise(self, selectedUnit, cells, id)
    end

    if not selectedUnit or not uitr_util.checkOption("overwatchMovement") then
        return id
    end

    -- Identify threats that could shoot us.
    local guardThreats, turretThreats = findThreats(sim, selectedUnit)
    if not next(guardThreats) and not next(turretThreats) then
        return id
    end

    simlog("LOG_UITR_OW", "overwatchTracking ===========")

    -- Mark movement cells that get us shot.
    local fgProps = {}
    local tempDoors = {}
    local prevCell = nil
    local prevCellThreat = nil
    for i, coord in ipairs(cells) do
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
            local cellIsWatched =
                    (isWatchedByGuard(sim, guardThreats, selectedUnit, cell, prevCell) or
                            isWatchedByTurret(sim, turretThreats, selectedUnit, cell))
            if cellIsWatched then
                simlog("LOG_UITR_OW", "   shot %s,%s", cell.x, cell.y)
                table.insert(fgProps, newShootProp(self, cell, color))
                prevCellThreat = true
            else
                prevCellThreat = false
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
