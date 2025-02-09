local abilitydefs = include("sim/abilitydefs")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local mathutil = include("modules/mathutil")
local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

local emp_tooltip = uitr_util.extractUpvalue(abilitydefs._abilities.prime_emp.onTooltip, "emp_tooltip")

local _activate = emp_tooltip.activate
emp_tooltip.activate = function(self, ...)
    _activate(self, ...)

    local displayOption = uitr_util.checkOption("sprintNoisePreview")
    if not displayOption then
        return
    end

    local x0, y0 = self._unit:getLocation()
    local radius = simdefs.SOUND_RANGE_1
    local sim = self._game.simCore
    local player = sim:getPC()
    local hearingUnits = {}

    local cells = simquery.rasterCircle(sim, x0, y0, radius)
    for i = 1, #cells, 2 do
        local x1, y1 = cells[i], cells[i+1]
        local cellId = simquery.toCellID(x1, y1)
        if sim:canPlayerSee(player, x1, y1) then -- check real units
            for _, unit in ipairs(sim:getCell(x1, y1).units) do
                if unit:getTraits().hasHearing and sim:canPlayerSeeUnit(player, unit) and
                    unit:getPlayerOwner() ~= player and not unit:isDown() then
                    table.insert(hearingUnits, unit)
                end
            end
        elseif player._ghost_cells[cellId] then -- check ghost units
            for _, ghostUnit in ipairs(player._ghost_cells[cellId].units) do
                local unit = uitr_util.getKnownUnitFromGhost(sim, ghostUnit)
                if unit and ghostUnit:getTraits().hasHearing and
                    ghostUnit:getPlayerOwner() ~= player and not unit:isDown() then
                    table.insert(hearingUnits, unit)
                end
            end
        end
    end

    local boardrig = self._game.boardRig
    local noiseProps = {}
    for _, unit in ipairs(hearingUnits) do
        local unitrig = boardrig:getUnitRig(unit:getID())
        wx, wy = boardrig:cellToWorld(unit:getLocation())

        local prop = unitrig:createHUDProp(
                "kanim_soundbug_overlay_alarm", "character", "alarm_loop",
                boardrig:getLayer("ceiling"), nil, wx, wy)

        local r, g, b, a = 247 / 255, 247 / 255, 142 / 255, 1
        prop:setSymbolModulate("cicrcle_wave", r, g, b, a)
        prop:setSymbolModulate("line_1", r, g, b, a)
        prop:setSymbolModulate("ring", r, g, b, a)
        prop:setSymbolModulate("attention_ring", r, g, b, a)

        table.insert(noiseProps, prop)
    end
    self.noiseProps = noiseProps
end

local _deactivate = emp_tooltip.deactivate
emp_tooltip.deactivate = function(self, ...)
    _deactivate(self, ...)

    if self.noiseProps then
        local layer = self._game.boardRig:getLayer("ceiling")
        for _, prop in ipairs(self.noiseProps) do
            layer:removeProp(prop)
        end
    end
end
