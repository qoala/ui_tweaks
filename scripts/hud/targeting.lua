local array = include("modules/array")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local targeting = include("hud/targeting")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

-- ===
-- areaTargetBase

targeting.areaTargetBase = targeting.areaTargetBase or targeting.simpleAreaTarget._base
local ATB_OLD_FN_MAPPING = {setTargetCell = targeting.areaTargetBase.setTargetCell}
local ATB_NEW_KEYS = { --
    "setAreaMode",
    "_calcTargetCells",
}

targeting.areaTargetBase._uitrmeta_ATB_areamode = true

local oldATBInit = targeting.areaTargetBase.init
function targeting.areaTargetBase:init(...)
    uitr_util.propagateSuperclass(
            getmetatable(self), targeting.areaTargetBase, ATB_OLD_FN_MAPPING, ATB_NEW_KEYS,
            "_uitrmeta_ATB_areamode")

    oldATBInit(self, ...)
end

function targeting.areaTargetBase:setAreaMode(mode)
    -- simdefs.TARGETAREA_*
    self._areaMode = mode
end

-- Convert a list of cells to a list of alternating x and y coordinates (like rasterCircle).
local function flattenCells(cells)
    local coords = {}
    for i, c in ipairs(cells) do
        coords[2 * i - 1], coords[2 * i] = c.x, c.y
    end
    return coords
end

-- Calculate target area. (new method)
-- Valid target will already have been checked before calling.
-- (Vanilla only performed TARGETAREA_GEOMETRIC)
function targeting.areaTargetBase:_calcTargetCells(x, y)
    if self._areaMode == nil or self.areaMode == simdefs.TARGETAREA_GEOMETRIC then
        return simquery.rasterCircle(self.sim, x, y, self.range)
    elseif self._areaMode == simdefs.TARGETAREA_FLOOD_MANHATTAN then
        local cell = self.sim:getCell(x, y)
        return flattenCells(
                simquery.floodFill(
                        self.sim, nil, cell, self.range, --
                        simquery.getManhattanMoveCost, simquery.canPathBetween))
    elseif self._areaMode == simdefs.TARGETAREA_FLOOD_GEOMETRIC then
        local cell = self.sim:getCell(x, y)
        return flattenCells(
                simquery.floodFill(
                        self.sim, nil, cell, self.range, --
                        simquery.getMoveCost, simquery.canPathBetween))
    end
end

-- Overwrite setTargetCell, replacing target cell calculation.
function targeting.areaTargetBase:setTargetCell(cellx, celly)
    self.mx, self.my = cellx, celly

    if self:isValidTargetLoc(cellx, celly) then
        -- UITR: Support alternate area modes other than a geometric rasterCircle.
        -- And delegate that calculation to a private helper.
        self.cells = self:_calcTargetCells(cellx, celly)
    else
        self.cells = nil
    end

    if self.unitTargetFn then
        local count = #self.unitTargets
        if self.cells then
            for i = 1, #self.cells, 2 do
                local cell = self.sim:getCell(self.cells[i], self.cells[i + 1])
                if cell then
                    for j, cellUnit in ipairs(cell.units) do
                        if self.unitTargetFn(cellUnit) then
                            -- Hey: does this already exist in the list?
                            local idx = array.find(self.unitTargets, cellUnit:getID())
                            if idx then
                                table.insert(self.unitTargets, table.remove(self.unitTargets, idx))
                                count = count - 1
                            else
                                table.insert(self.unitTargets, cellUnit:getID())
                                self._game.boardRig:getUnitRig(cellUnit:getID()):getProp()
                                        :setRenderFilter(
                                                cdefs.RENDER_FILTERS["focus_target"])
                            end
                        end
                    end
                end
            end
        end

        while count > 0 do
            local unitRig = self._game.boardRig:getUnitRig(table.remove(self.unitTargets, 1))
            unitRig:refreshRenderFilter()
            count = count - 1
        end
    end
end

-- ===
-- throwTarget

-- TODO: Also patch EAA mod's itemThrowTarget, which overwrites onDraw to display the AP cost.

function cellInLOS(sim, x0, y0, x, y)
    local raycastX, raycastY = sim:getLOS():raycast(x0, y0, x, y)
    return raycastX == x and raycastY == y
end

-- Overwrite onDraw.
-- Instead of sim:canPlayerSee, use player:getLastKnownCell. Highlight affected tiles that the player knows about, not just those the player can currently see.
function targeting.throwTarget:onDraw()
    local sim = self.sim
    local player = self.unit:getPlayerOwner()
    if not (self.mx and self.my and self.cells and player) then
        return false
    end

    MOAIGfxDevice.setPenColor(unpack(self._hiliteClr))
    -- UITR: Use self.cells instead of recalculating them.
    for i = 1, #self.cells, 2 do
        local x, y = self.cells[i], self.cells[i + 1]
        -- UITR: Replace canPlayerSee check with getLastKnownCell.
        -- UITR: Ignore LOS with flood-fill area modes, which handle obstructions in their own way.
        local ignoreLOS = self._ignoreLOS or self._areaMode == simdefs.TARGETAREA_FLOOD_GEOMETRIC or
                                  self._areaMode == simdefs.TARGETAREA_FLOOD_MANHATTAN
        if (ignoreLOS or cellInLOS(sim, self.mx, self.my, x, y)) and
                player:getLastKnownCell(sim, x, y) then
            local x0, y0 = self._game:cellToWorld(x + 0.4, y + 0.4)
            local x1, y1 = self._game:cellToWorld(x - 0.4, y - 0.4)
            MOAIDraw.fillRect(x0, y0, x1, y1)
        end
    end
    return true
end
