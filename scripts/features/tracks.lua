local color = include("modules/color")
local pathrig = include("gameplay/pathrig")
local agentrig = include("gameplay/agentrig")
local util = include("modules/util")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

PATH_COLORS = {
    color(0, 1, 0.1, 1.0), -- Green
    color(1, 1, 0.1, 1.0), -- Yellow
    color(1, 0.7, 0.1, 1.0), -- Orange
    color(1, 1, 0.6, 1.0), -- Pale Yellow
    color(0.5, 1, 0.7, 1.0), -- Pale Green
    color(0, 0.7, 0.7, 1.0), -- Teal
}

local path_color_idx = 0

local function assignColor(unit)
    local traits = unit:getTraits()
    if not traits.pathColor then
        traits.pathColor = PATH_COLORS[(path_color_idx % #PATH_COLORS) + 1]
        path_color_idx = path_color_idx + 1
    end
    return traits.pathColor
end

local function calculatePathColors(self, unitID, pathPoints)
    local collisions = self._pathCollisions
    local colors = {}
    local unitColor = assignColor(self._boardRig:getSim():getUnit(unitID))

    for i = 2, #pathPoints do
        local prevPathPoint, pathPoint = pathPoints[i - 1], pathPoints[i]
        local prevPointKey = prevPathPoint.x .. "." .. prevPathPoint.y
        local pointKey = pathPoint.x .. "." .. pathPoint.y

        local collided = false

        if not collisions[pointKey] then
            collisions[pointKey] = {}
        end

        collisions[pointKey][unitID] = prevPointKey

        for otherUnitID in pairs(collisions[pointKey]) do
            if unitID ~= otherUnitID and collisions[pointKey][otherUnitID] == prevPointKey then
                collided = true
            end
        end

        if collided then
            table.insert(colors, color(1, 1, 1, 1))
        else
            table.insert(colors, unitColor)
        end
    end

    return colors
end

local oldRefreshPlannedPath = pathrig.rig.refreshPlannedPath
function pathrig.rig:refreshPlannedPath(unitID)
    oldRefreshPlannedPath(self, unitID)

    if uitr_util.checkOption("coloredTracks") and self._plannedPaths[unitID] then
        local pathCellColors = calculatePathColors(self, unitID, self._plannedPaths[unitID])

        -- DEMO: display footprints in place of observed paths.
        local resources = include("resources")
        local tex, texDiag = resources.find("uitrFootprintTrail"), resources.find("uitrFootprintTrailDiag")
        local pathPoints = self._plannedPaths[unitID]

        local parity = 1
        for i, prop in ipairs(self._plannedPathProps[unitID]) do
            prop:setColor(pathCellColors[i]:unpack())

            -- DEMO: Limitation all path points must be visible
			local prevPathPoint, pathPoint = pathPoints[i], pathPoints[i+1]
            local xEq = pathPoint.x == prevPathPoint.x
            local yEq = pathPoint.y == prevPathPoint.y
            if not xEq and not yEq then
                prop:setDeck(texDiag)
                prop:setScl(math.sqrt(4), parity)
                parity = parity * -1
            elseif not xEq or not yEq then
                prop:setDeck(tex)
                prop:setScl(math.sqrt(2), parity)
            end
        end
    end
end

-- { package = pathrig.rig,  name = 'refreshAllTracks',   f = refreshAllTracks },
local oldRefreshAllTracks = pathrig.rig.refreshAllTracks
function pathrig.rig:refreshAllTracks()
    if uitr_util.checkOption("coloredTracks") then
        self._pathCollisions = {}

        if not self._pathColors then
            self._pathColors = {}
        end
    end

    return oldRefreshAllTracks(self)
end

-- { package = agentrig.rig, name = 'drawInterest',       f = drawInterest }
local oldDrawInterest = agentrig.rig.drawInterest
function agentrig.rig:drawInterest(interest, alerted)
    oldDrawInterest(self, interest, alerted)

    if uitr_util.checkOption("coloredTracks") and self.interestProp then
        local color = assignColor(self:getUnit())
        self.interestProp:setSymbolModulate("interest_border", color:unpack())
        self.interestProp:setSymbolModulate("down_line", color:unpack())
        self.interestProp:setSymbolModulate("down_line_moving", color:unpack())
        self.interestProp:setSymbolModulate("interest_line_moving", color:unpack())
    end
end

