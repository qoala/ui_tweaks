local color = include("modules/color")
local util = include("modules/util")
local resources = include("resources")
local PathRig = include("gameplay/pathrig").rig

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")
local track_colors = include(SCRIPT_PATHS.qed_uitr .. "/features/track_colors")

-- Observed Paths
local COLLISION_PATH_COLOR = color(1, 1, 1, 1)
-- Past Tracks
local UNKNOWN_TRACK_COLOR = color(0.8, 0.8, 0.8, 0.5)

-- ===
-- Colored Tracks for observed paths.

local function calculatePathColors(self, unitID, pathPoints)
    local simquery = self._boardRig:getSim():getQuery()
    local collisions = self._pathCollisions
    local colors = {}
    local unitColor = track_colors.getColor(self._boardRig:getSim():getUnit(unitID))

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

        if collided and false then
            table.insert(colors, COLLISION_PATH_COLOR)
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

        for i, prop in ipairs(self._plannedPathProps[unitID]) do
            prop:setColor(pathCellColors[i]:unpack())
        end
    end
end

-- ===
-- Footprint (past guard path) Tracking

-- UITR: Override.
function PathRig:refreshTracks(unitID, tracks)
    local optFootprints = uitr_util.checkOption("recentFootprints")
    if not optFootprints or config.NO_AI_TRACKS then
        -- Free up current track props.
        local props = self._tracks[unitID]
        if props then
            self:refreshTrackProps(false, nil, nil, props)
        end
        return
    end

    if tracks or self._tracks[unitID] then
        self._tracks[unitID] = self._tracks[unitID] or {}

        local sim = self._boardRig:getSim()
        local unit = sim:getUnit(unitID)
        self:refreshTrackProps(optFootprints, unit, tracks, self._tracks[unitID])
    end
end

-- UITR: (New)
function PathRig:_isTrackPointKnown(optFootprints, pathPoint)
    if optFootprints == "seen" then
        return pathPoint.isSeen or pathPoint.isTracked
    elseif optFootprints == "full" then
        return pathPoint.isSeen or pathPoint.isTracked or pathPoint.isHeard
    end
end

-- UITR: Copy of vanilla local getTrackProp
function PathRig:_getTrackProp()
    local prop = table.remove(self._propPool)
    if prop == nil then
        prop = MOAIProp2D.new()
        prop:setDeck(resources.find("Footprint"))
        prop:setColor(1, 1, 0, 1)
    end

    self._layer:insertProp(prop)

    return prop
end

local function calculateTrackProp(boardRig, x0, y0, x1, y1)
    local x, y = boardRig:cellToWorld(x0, y0)
    local nx, ny = boardRig:cellToWorld(x1, y1)
    local dx, dy = x1 - x0, y1 - y0
    local theta = math.atan2(dy, dx)
    local scale = math.sqrt(2 * dx * dx + 2 * dy * dy)

    local isDiag = not (dx == 0 or dy == 0)
    local propX, propY = (x + nx) / 2, (y + ny) / 2

    return isDiag, propX, propY, theta, scale
end

-- UITR: (New) Based on vanilla :refreshProps
function PathRig:refreshTrackProps(optFootprints, unit, pathPoints, props)
    -- # of props used.
    local j = 1
    if pathPoints then
        -- Update extant tracks
        local player = self._boardRig:getSim():getPC()
        local texOrth = resources.find("uitrFootprintTrail")
        local texDiag = resources.find("uitrFootprintTrailDiag")

        local unitColor = UNKNOWN_TRACK_COLOR
        local colorAlpha = 0.3
        if pathPoints.info.wasSeen or pathPoints.info.wasTracked or
                (unit and uitr_util.playerKnowsUnit(player, unit)) then
            -- If we know/knew the unit, use its color.
            unitColor = track_colors.getColor(unit)
            colorAlpha = 0.5
        end

        -- Flip sprite after diagonal steps (odd count)
        local parity = 1

        for i = 2, #pathPoints do
            local prevPathPoint, pathPoint = pathPoints[i - 1], pathPoints[i]
            local isKnown = self:_isTrackPointKnown(optFootprints, prevPathPoint) or
                                    self:_isTrackPointKnown(optFootprints, pathPoint)
            if isKnown then
                local prop = props[j] or self:_getTrackProp()
                props[j] = prop

                local isDiag, propX, propY, theta, scale = calculateTrackProp(
                        self._boardRig, prevPathPoint.x, prevPathPoint.y, pathPoint.x, pathPoint.y)

                if isDiag then
                    prop:setDeck(texDiag)
                    parity = parity * -1
                else
                    prop:setDeck(texOrth)
                end
                prop:setRot(math.deg(theta))
                prop:setScl(scale, parity)
                prop:setLoc(propX, propY)
                local r, g, b, _ = unitColor:unpack()
                prop:setColor(r, g, b, colorAlpha)

                j = j + 1
            end
        end
    end

    -- Free the unused props. Reset texture before returning to the pool.
    local texPlain = resources.find("Footprint")
    while j <= #props and #props > 0 do
        local prop = table.remove(props)
        self._layer:removeProp(prop)
        prop:setDeck(texPlain)
        table.insert(self._propPool, prop)
    end
end

-- ===
-- Shared.

-- UITR: Override (unless all relevant options are disabled)
local oldRefreshAllTracks = PathRig.refreshAllTracks
function PathRig:refreshAllTracks()
    local optColoredTracks = uitr_util.checkOption("coloredTracks")
    local optFootprints = uitr_util.checkOption("recentFootprints")
    if not (optColoredTracks or optFootprints) then
        return oldRefreshAllTracks(self)
    end

    local sim = self._boardRig:getSim()
    local player = sim:getPC()

    -- UITR: Colored Tracks reset overlap tests
    if optColoredTracks then
        self._pathCollisions = {}
    end

    -- UITR: Fix vanilla code that messes up keyvalue-vs-array loops.
    for unitID, track in pairs(player:getTracks()) do
        if self._tracks[unitID] == nil then
            self._tracks[unitID] = {}
        end
    end
    for unitID, trackProps in pairs(self._tracks) do
        self:refreshTracks(unitID, player:getTracks(unitID))
    end

    -- UITR: Copy vanilla code for resetting and then regenerating all observed (planned) paths.
    for unitID, path in pairs(sim:getNPC().pather:getPaths()) do
        if self._plannedPaths[unitID] == nil then
            self._plannedPaths[unitID] = {}
        end
    end
    for unitID, pathProps in pairs(self._plannedPaths) do
        self:regeneratePath(unitID)
    end
end
