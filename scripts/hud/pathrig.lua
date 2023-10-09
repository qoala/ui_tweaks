local color = include("modules/color")
local util = include("modules/util")
local resources = include("resources")
local PathRig = include("gameplay/pathrig").rig

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")
local track_colors = include(SCRIPT_PATHS.qed_uitr .. "/features/track_colors")

-- ===
-- Colored Tracks for observed paths.

local function calculatePathColors(self, unitID, pathPoints)
	local simquery = self._boardRig:getSim():getQuery()
    local collisions = self._pathCollisions
    local colors = {}
    local unitColor = track_colors:assignColor(self._boardRig:getSim():getUnit(unitID))

    for i = 2, #pathPoints do
        local prevPathPoint, pathPoint = pathPoints[i - 1], pathPoints[i]
        local prevPointKey = simquery.toCellID(prevPathPoint.x, prevPathPoint.y)
        local pointKey = simquery.toCellID(pathPoint.x, pathPoint.y)

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

local oldRefreshPlannedPath = PathRig.refreshPlannedPath
function PathRig:refreshPlannedPath(unitID)
    oldRefreshPlannedPath(self, unitID)

    if uitr_util.checkOption("coloredTracks") and self._plannedPaths[unitID] then
        local pathCellColors = calculatePathColors(self, unitID, self._plannedPaths[unitID])

        -- DEMO: display footprints in place of observed paths.
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

local oldRefreshAllTracks = PathRig.refreshAllTracks
function PathRig:refreshAllTracks()
    if uitr_util.checkOption("coloredTracks") then
        self._pathCollisions = {}
    end

    return oldRefreshAllTracks(self)
end
