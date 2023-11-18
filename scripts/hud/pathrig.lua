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

local DEFAULT_PATH_VISIBILITY = uitr_util.VISIBILITY.SHOW

function defaultTrackVisibility()
    local option = uitr_util.checkOption("recentFootprintsMode") or "e"
    return uitr_util.VISIBILITY_MODE[option][1]
end

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
        if self._singleVisibility then
            local clr = track_colors.getColor(self._boardRig:getSim():getUnit(unitID))
            for i, prop in ipairs(self._plannedPathProps[unitID]) do
                prop:setColor(clr:unpack())
            end
        else
            local pathCellColors = calculatePathColors(self, unitID, self._plannedPaths[unitID])
            for i, prop in ipairs(self._plannedPathProps[unitID]) do
                prop:setColor(pathCellColors[i]:unpack())
            end
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
-- Also accepts pathInfo
-- isOrigin: whether or not a point is the origin or destination of a given step.
function PathRig:_isTrackPointKnown(optFootprints, pathPoint, isOrigin)
    if not pathPoint then
        return false
    elseif optFootprints == "seen" then
        return pathPoint.isSeen or pathPoint.isTracked
    elseif optFootprints == "full" then
        return pathPoint.isSeen or pathPoint.isTracked or (pathPoint.isHeard and not isOrigin)
    end
end
function PathRig:isUnitTrackKnown(unitID)
    local player = self._boardRig:getSim():getPC()
    local path = player and player:getTracks(unitID)
    if not path then
        return false
    end
    local optFootprints = uitr_util.checkOption("recentFootprints")
    return self:_isTrackPointKnown(optFootprints, path.info)
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

-- Updates the prop and returns (prop, newParity)
-- tex is a STRUCT[isDiag][parity]
function PathRig:_updateTrackProp(prop, point0, point1, tex, clr, parity)
    local x, y = self._boardRig:cellToWorld(point0.x, point0.y)
    local nx, ny = self._boardRig:cellToWorld(point1.x, point1.y)
    local dx, dy = point1.x - point0.x, point1.y - point0.y
    local theta = math.atan2(dy, dx)
    local scale = math.sqrt(2 * dx * dx + 2 * dy * dy)

    local isDiag = not (dx == 0 or dy == 0)
    local propX, propY = (x + nx) / 2, (y + ny) / 2

    -- simlog(
    --         "[UITR] draw%s [%d] %d,%d-%d,%d diag=%s parity=%s", tex.dbg_name, tostring(tex.dbg_unit),
    --         point0.x, point0.y, point1.x, point1.y, tostring(isDiag), tostring(parity))
    prop = prop or self:_getTrackProp()
    prop:setDeck(tex[isDiag][parity])
    prop:setRot(math.deg(theta))
    prop:setScl(scale, parity)
    prop:setLoc(propX, propY)
    prop:setColor(clr:unpack())

    return prop, (isDiag and (parity * -1) or parity)
end

-- UITR: (New) Based on vanilla :refreshProps
--
-- For each segment, if either the previous point or current point were sensed by the player, it is
-- drawn. Both the coming and going are assumed to be available, so the track will barely extend
-- into the unknown on each end.
--
-- Exception: Neptune pressure plates only show tracks if both points were sensed.
function PathRig:refreshTrackProps(optFootprints, unit, pathPoints, props)
    -- # of props used.
    local j = 1
    if pathPoints then
        -- Update extant tracks
        local player = self._boardRig:getSim():getPC()

        -- Track textures STRUCT[isDiag][parity]
        local texTrack = {
            [false] = {},
            [true] = {},
            dbg_name = "Track",
            dbg_unit = unit and unit:getID(),
        }
        local texGuess = {
            [false] = {},
            [true] = {},
            dbg_name = "Guess",
            dbg_unit = unit and unit:getID(),
        }
        texTrack[false][1] = resources.find("uitrFootprintTrail")
        texTrack[false][-1] = texTrack[false][1]
        texTrack[true][1] = resources.find("uitrFootprintTrailDiag")
        texTrack[true][-1] = texTrack[true][1]
        texGuess[false][1] = resources.find("uitrFootprintQuestion")
        texGuess[false][-1] = resources.find("uitrFootprintQuestionFlip")
        texGuess[true][1] = resources.find("uitrFootprintQuestionDiag")
        texGuess[true][-1] = resources.find("uitrFootprintQuestionDiagFlip")

        local unitColor = UNKNOWN_TRACK_COLOR
        if unit and
                (pathPoints.info.isSeen or pathPoints.info.isTracked or
                        uitr_util.playerKnowsUnit(player, unit)) then
            -- If we know/knew the unit, use its color.
            unitColor = track_colors.getColor(unit)
        end

        -- Flip sprite after diagonal steps (odd count).
        local parity = 1
        -- Parallel iteration over observedPath.
        local obsPoints, obsIdx, obsParity
        if pathPoints.info.observedPath and
                (not unit or not (unit:getTraits().patrolObserved or unit:getTraits().tagged)) then
            obsPoints = pathPoints.info.observedPath
            obsIdx, obsParity = 2, 1
        end
        -- Observed path if the tracked path is proceeding from an undrawn position.
        local prevSegmentDrawn = false

        -- Iterate over tracked path.
        for i = 2, #pathPoints do
            local prevPathPoint, pathPoint = pathPoints[i - 1], pathPoints[i]

            -- Draw any preceding observed but unconfirmed path
            if (not prevSegmentDrawn and obsIdx and prevPathPoint.observedIdx and obsIdx <=
                    prevPathPoint.observedIdx) then
                while obsIdx <= prevPathPoint.observedIdx do
                    local prevObsPoint, obsPoint = obsPoints[obsIdx - 1], obsPoints[obsIdx]
                    -- simlog("[UITR] guess [%d] #%d %d,%d-%d,%d known=%s,%s", unit:getID(), obsIdx, prevObsPoint.x, prevObsPoint.y, obsPoint.x, obsPoint.y, tostring(prevObsPoint.isObserved), tostring(obsPoint.isObserved))
                    if prevObsPoint.isObserved or obsPoint.isObserved then
                        props[j], obsParity = self:_updateTrackProp(
                                props[j], prevObsPoint, obsPoint, texGuess, unitColor, obsParity)
                        j = j + 1
                    end
                    obsIdx = obsIdx + 1
                end
                parity = obsParity
            end

            local isKnown0 = self:_isTrackPointKnown(optFootprints, prevPathPoint, true)
            local isKnown1 = self:_isTrackPointKnown(optFootprints, pathPoint, false)
            local areBothSensed = prevPathPoint.isSensed and pathPoint.isSensed
            -- simlog("[UITR] track [%d] #%d %d,%d-%d,%d known=%s,%s sensed=%s", unit:getID(), i, prevPathPoint.x, prevPathPoint.y, pathPoint.x, pathPoint.y, tostring(isKnown0), tostring(isKnown1), tostring(areBothSensed))
            -- if prevPathPoint.observedIdx or pathPoint.observedIdx then
            --     simlog("[UITR]                   guessed as %s-%s", prevPathPoint.observedIdx or "/", pathPoint.observedIdx or "/")
            -- end
            if isKnown0 or isKnown1 or areBothSensed then
                props[j], parity = self:_updateTrackProp(
                        props[j], prevPathPoint, pathPoint, texTrack, unitColor, parity)
                j = j + 1

                if obsIdx and pathPoint.observedIdx then
                    if pathPoint.observedIdx >= obsIdx then
                        -- Path up to here has been confirmed.
                        obsIdx = pathPoint.observedIdx + 1
                        obsParity = parity
                    end
                elseif obsIdx then
                    -- Sensed track has deviated from observation. Cancel any further obs drawing.
                    obsIdx = nil
                end
            end
        end

        -- Draw the remaining unconfirmed path.
        if obsIdx then
            while obsIdx <= #obsPoints do
                local prevObsPoint, obsPoint = obsPoints[obsIdx - 1], obsPoints[obsIdx]
                -- simlog("[UITR] guess [%d] #%d %d,%d-%d,%d", unit:getID(), obsIdx, prevObsPoint.x, prevObsPoint.y, obsPoint.x, obsPoint.y, tostring(prevObsPoint.isObserved), tostring(obsPoint.isObserved))
                if prevObsPoint.isObserved or obsPoint.isObserved then
                    props[j], obsParity = self:_updateTrackProp(
                            props[j], prevObsPoint, obsPoint, texGuess, unitColor, obsParity)
                    j = j + 1
                end
                obsIdx = obsIdx + 1
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

local oldInit = PathRig.init
function PathRig:init(boardRig, layer, throwLayer, ...)
    oldInit(self, boardRig, layer, throwLayer, ...)

    -- Can be set to a struct with {unitID, showPath, showTracks} to hide all others.
    -- Single Visibility (hovering the Info icon for that unit) takes precedence over global vis.
    self._singleVisibility = nil
    -- Global visibility toggles (between Options and buttons by the Info Mode toggle)
    self._globalPathVisibility = DEFAULT_PATH_VISIBILITY
    self._globalTrackVisibility = defaultTrackVisibility()
    -- Table mapping UnitID to {hidePath, hideTracks}.
    self._unitVisibility = {}
end

function PathRig:resetTemporaryVisibility()
    self._singleVisibility = nil
    self._unitVisibility = {}
end
function PathRig:resetVisibility()
    self._globalPathVisibility = DEFAULT_PATH_VISIBILITY
    self._globalTrackVisibility = defaultTrackVisibility()
    self._singleVisibility = nil
    self._unitVisibility = {}
end

function PathRig:getGlobalPathVisibility()
    return self._globalPathVisibility
end
function PathRig:getGlobalTrackVisibility()
    return self._globalTrackVisibility
end
function PathRig:getUnitVisibility(unitID)
    return self._unitVisibility[unitID] or {}
end

function PathRig:setGlobalPathVisibility(visibility)
    if visibility then
        self._globalPathVisibility = visibility
    else -- Reset.
        self._globalPathVisibility = DEFAULT_PATH_VISIBILITY
    end
end
function PathRig:setGlobalTrackVisibility(visibility)
    if visibility then
        self._globalTrackVisibility = visibility
    else -- Reset.
        self._globalTrackVisibility = defaultTrackVisibility()
    end
end

-- Takes a struct with {unitID, showPath, showTracks} to hide all other units.
function PathRig:setSingleVisibility(showVisibility)
    self._singleVisibility = showVisibility
end

function PathRig:setUnitPathVisibility(unitID, isShown)
    local unitVis = self._unitVisibility[unitID]
    if unitVis then
        unitVis.hidePath = not isShown
    elseif not isShown then
        self._unitVisibility[unitID] = {hidePath = true}
    end
end
function PathRig:setUnitTracksVisibility(unitID, isShown)
    local unitVis = self._unitVisibility[unitID]
    if unitVis then
        unitVis.hideTracks = not isShown
    elseif not isShown then
        self._unitVisibility[unitID] = {hideTracks = true}
    end
end
-- Also, PathRig:isUnitTrackKnown(unitID) above

function PathRig:_checkGlobalVisibility(globalVisibility)
    if globalVisibility == uitr_util.VISIBILITY.ENEMY_TURN then
        local sim = self._boardRig:getSim()
        if sim:getCurrentPlayer() and sim:getCurrentPlayer():isNPC() then
            return uitr_util.VISIBILITY.SHOW
        else
            return uitr_util.VISIBILITY.HIDE
        end
    end
    return globalVisibility
end
function PathRig:_shouldDrawPath(unitID)
    if self._singleVisibility then
        return self._singleVisibility.unitID == unitID and self._singleVisibility.showPath
    end
    if self:_checkGlobalVisibility(self._globalPathVisibility) == uitr_util.VISIBILITY.HIDE then
        return false
    end
    return not (self._unitVisibility[unitID] and self._unitVisibility[unitID].hidePath)
end
function PathRig:_shouldDrawTracks(unitID)
    if self._singleVisibility then
        return self._singleVisibility.unitID == unitID and self._singleVisibility.showTracks
    end
    if self:_checkGlobalVisibility(self._globalTrackVisibility) == uitr_util.VISIBILITY.HIDE then
        return false
    end
    return not (self._unitVisibility[unitID] and self._unitVisibility[unitID].hideTracks)
end

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
        if self:_shouldDrawTracks(unitID) then
            self:refreshTracks(unitID, player:getTracks(unitID))
        elseif trackProps and #trackProps > 0 then
            -- Free up current track props.
            self:refreshTrackProps(false, nil, nil, trackProps)
        end
    end

    -- UITR: Copy vanilla code for resetting and then regenerating all observed (planned) paths.
    for unitID, path in pairs(sim:getNPC().pather:getPaths()) do
        if self._plannedPaths[unitID] == nil then
            self._plannedPaths[unitID] = {}
        end
    end
    for unitID, path in pairs(self._plannedPaths) do
        if self:_shouldDrawPath(unitID) then
            self:regeneratePath(unitID)
        else
            if self._plannedPathProps[unitID] and #self._plannedPathProps[unitID] > 0 then
                -- Free up current track props.
                self:refreshProps(nil, self._plannedPathProps[unitID], nil)
            end
            if self._plannedThrowProps[unitID] then
                self._throwLayer:removeProp(self._plannedThrowProps[unitID])
                self._plannedThrowProps[unitID] = nil
            end
        end
    end
end
