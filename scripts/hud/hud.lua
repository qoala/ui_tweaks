local mui_defs = include("mui/mui_defs")
local mui_tooltip = include("mui/mui_tooltip")
local cdefs = include("client_defs")
local util = include("client_util")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

-- ===

local hudAppend = {}

-- ===

local function onClickVisionToggle(hud)
    hud:uitr_setVisionMode(not hud._uitr_isVisionMode)
end

local function visionModeTooltip(currentEnable)
    return mui_tooltip(
            STRINGS.UITWEAKSR.UI.BTN_VISIONMODE_HEADER,
            currentEnable and STRINGS.UITWEAKSR.UI.BTN_VISIONMODE_DISABLE_TXT or
                    STRINGS.UITWEAKSR.UI.BTN_VISIONMODE_ENABLE_TXT, "UITR_VISIONMODE")
end

function hudAppend:uitr_setVisionMode(doEnable)
    self._uitr_isVisionMode = doEnable

    local btnToggleVisionMode = self._screen.binder.topPnl.binder.btnToggleVisionMode
    btnToggleVisionMode:setTooltip(visionModeTooltip(doEnable))
    btnToggleVisionMode:setInactiveImage(
            doEnable and "gui/hud3/UserButtons/uitr_btn_disable_visionmode.png" or
                    "gui/hud3/UserButtons/uitr_btn_enable_visionmode.png")
    btnToggleVisionMode:setActiveImage(
            doEnable and "gui/hud3/UserButtons/uitr_btn_disable_visionmode_hl.png" or
                    "gui/hud3/UserButtons/uitr_btn_enable_visionmode_hl.png")
    btnToggleVisionMode:setHoverImage(
            doEnable and "gui/hud3/UserButtons/uitr_btn_disable_visionmode_hl.png" or
                    "gui/hud3/UserButtons/uitr_btn_enable_visionmode_hl.png")

    if not doEnable then
        self._game.simCore:uitr_resetAllUnitVision()
        self._game.boardRig:getPathRig():resetTemporaryVisibility()
        self._game.boardRig:refresh()
    end
    self:refreshHud()
end

-- ===

STICKY_VISIBILITY = {e = false, h = false, s = false, ["h!"] = true, ["s!"] = true}
uitr_util.makeStrict(STICKY_VISIBILITY)

local function toggleGlobalPathVisibility(pathRig)
    local visibility = pathRig:getGlobalPathVisibility()
    if visibility == uitr_util.VISIBILITY.SHOW then
        pathRig:setGlobalPathVisibility(uitr_util.VISIBILITY.HIDE)
    else
        pathRig:setGlobalPathVisibility(uitr_util.VISIBILITY.SHOW)
    end
end
local function toggleGlobalTrackVisibility(pathRig)
    local visibility = pathRig:getGlobalTrackVisibility()
    local mode = uitr_util.VISIBILITY_MODE[uitr_util.checkOption("recentFootprintsMode") or "e"]
    if visibility == mode[1] then
        pathRig:setGlobalTrackVisibility(mode[2])
    else
        pathRig:setGlobalTrackVisibility(mode[1])
    end
end
local function onClickPathVisibilityToggle(hud)
    local pathRig = hud._game.boardRig:getPathRig()
    toggleGlobalPathVisibility(pathRig)
    hud:uitr_refreshInfoGlobalButtons()
    pathRig:refreshAllTracks()
end
local function onClickTrackVisibilityToggle(hud)
    local pathRig = hud._game.boardRig:getPathRig()
    toggleGlobalTrackVisibility(pathRig)
    hud:uitr_refreshInfoGlobalButtons()
    pathRig:refreshAllTracks()
end
local function onClickPathTrackVisibilityCycle(hud)
    local pathRig = hud._game.boardRig:getPathRig()
    local arePathsShown = pathRig:getGlobalPathVisibility() == uitr_util.VISIBILITY.SHOW
    local areTracksShown = pathRig:getGlobalTrackVisibility() == uitr_util.VISIBILITY.SHOW
    -- Both -> Paths -> Tracks -> Both
    if arePathsShown and areTracksShown then
        toggleGlobalTrackVisibility(pathRig)
    elseif arePathsShown then
        toggleGlobalPathVisibility(pathRig)
        toggleGlobalTrackVisibility(pathRig)
    elseif areTracksShown then
        toggleGlobalPathVisibility(pathRig)
    else
        -- Neither -> Reset to Default
        pathRig:resetVisibility()
    end
    hud:uitr_refreshInfoGlobalButtons()
    pathRig:refreshAllTracks()
end

function hudAppend:uitr_refreshInfoGlobalButtons()
    local pathRig = self._game.boardRig:getPathRig()
    local pathVisibility = pathRig:getGlobalPathVisibility()
    local trackVisibility = pathRig:getGlobalTrackVisibility()

    local btnTogglePaths = self._screen.binder.topPnl.binder.btnInfoTogglePaths
    if pathVisibility == uitr_util.VISIBILITY.SHOW then
        btnTogglePaths:setInactiveImage("gui/hud3/UserButtons/uitr_btn_enable_visionmode.png")
        btnTogglePaths:setActiveImage("gui/hud3/UserButtons/uitr_btn_enable_visionmode_hl.png")
        btnTogglePaths:setHoverImage("gui/hud3/UserButtons/uitr_btn_enable_visionmode_hl.png")
    else
        btnTogglePaths:setInactiveImage("gui/hud3/UserButtons/uitr_btn_disable_visionmode.png")
        btnTogglePaths:setActiveImage("gui/hud3/UserButtons/uitr_btn_disable_visionmode_hl.png")
        btnTogglePaths:setHoverImage("gui/hud3/UserButtons/uitr_btn_disable_visionmode_hl.png")
    end

    local btnToggleTracks = self._screen.binder.topPnl.binder.btnInfoToggleTracks
    if trackVisibility == uitr_util.VISIBILITY.SHOW then
        btnToggleTracks:setInactiveImage("gui/hud3/UserButtons/uitr_btn_enable_visionmode.png")
        btnToggleTracks:setActiveImage("gui/hud3/UserButtons/uitr_btn_enable_visionmode_hl.png")
        btnToggleTracks:setHoverImage("gui/hud3/UserButtons/uitr_btn_enable_visionmode_hl.png")
    else
        btnToggleTracks:setInactiveImage("gui/hud3/UserButtons/uitr_btn_disable_visionmode.png")
        btnToggleTracks:setActiveImage("gui/hud3/UserButtons/uitr_btn_disable_visionmode_hl.png")
        btnToggleTracks:setHoverImage("gui/hud3/UserButtons/uitr_btn_disable_visionmode_hl.png")
    end
end

-- ===

-- ===

local GRID_N_LABELS = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"}
local GRID_S_LABELS = {"O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
local GRID_E_LABELS = {"-1", "-2", "-3", "-4", "-5", "-6", "-7", "-8", "-9", "-10", "-11", "-12"}
local GRID_W_LABELS = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"}
local HUD_GRID_COORDS = "hudUitrGrid"

local function createGridCoordinate(self, x, y, labelText)
    local wx, wy = self._game:cellToWorld(x, y)
    local wz = -6
    local widget = self._world_hud:createWidget(
            HUD_GRID_COORDS, "uitrGridCoordinate", {worldx = wx, worldy = wy, worldz = wz})
    widget.binder.label:setText(labelText)
    return widget
end

function hudAppend:_refreshUITRGridCoordinatesAgentRelative()
    if self._game:isReplaying() then
        return
    end
    local unit = self:getSelectedUnit()
    if not unit then
        return
    end
    local x0, y0 = unit:getLocation()
    if not x0 then
        return
    end
    local localPlayer = self._game:getLocalPlayer()
    local minX, minY, maxX, maxY
    if localPlayer ~= nil then
        minX, minY, maxX, maxY = localPlayer:getUITRKnownBounds()
        if x0 < minX or x0 > maxX or y0 < minY or y0 > maxY then
            simlog(
                    "[UITR] Warning: current unit outside player's known bounds: %s,%s vs %s,%s-%s,%s",
                    x0, y0, minX, minY, maxX, maxY)
            return
        end
        -- else, if there is no local player, just reveal everything
    end
    -- simlog("[UITR:TODO] coords %s,%s vs %s,%s-%s,%s", x0, y0, minX, minY, maxX, maxY)

    for i, lbl in ipairs(GRID_N_LABELS) do
        if y0 + i > maxY then
            break
        end
        createGridCoordinate(self, x0, y0 + i, lbl)
    end
    for i, lbl in ipairs(GRID_S_LABELS) do
        if y0 - i < minY then
            break
        end
        createGridCoordinate(self, x0, y0 - i, lbl)
    end
    for i, lbl in ipairs(GRID_E_LABELS) do
        if x0 + i > maxX then
            break
        end
        createGridCoordinate(self, x0 + i, y0, lbl)
    end
    for i, lbl in ipairs(GRID_W_LABELS) do
        if x0 - i < minX then
            break
        end
        createGridCoordinate(self, x0 - i, y0, lbl)
    end
end

function hudAppend:_refreshUITRGridCoordinates()
    self._world_hud:destroyWidgets(HUD_GRID_COORDS)

    local gridOption = uitr_util.checkOption("gridCoords")
    if gridOption == 1 then
        self:_refreshUITRGridCoordinatesAgentRelative()
    end
end

function hudAppend:_showMovementRange_fixCloakDistance(unit)
    if self._cloakCells and unit:getTraits().cloakDistance and unit:getTraits().cloakDistance > 0 then
        local sim = self._game.simCore
        local simquery = sim:getQuery()

        local cell = sim:getCell(unit:getLocation())
        -- CBF: Cloak Distance causes cloaks to break when <= 0, but that's not how MP and ranges
        --      are calculated. The correct offset is an infinitesimal, instead of vanilla '-1'.
        local distance = math.min(unit:getTraits().cloakDistance - 0.00001, unit:getMP())
        local costFn = simquery.getMoveCost
        if simquery.getTrueMoveCost then
            -- CBF: Adjust for Neptune if present. This append is outside of Neptune's wrapper.
            costFn = function(cell1, cell2)
                return simquery.getTrueMoveCost(unit, cell1, cell2)
            end
        end

        self._cloakCells = nil
        self._cloakCells = simquery.floodFill(sim, unit, cell, distance, costFn)

        if self._cloakCells then
            self._game.boardRig:setCloakTiles(
                    self._cloakCells, 0.8 * cdefs.MOVECLR_INVIS, cdefs.MOVECLR_INVIS)
        else
            self._game.boardRig:clearCloakTiles()
        end
    end
end

-- ===

local hud = include("hud/hud")
local oldCreateHud = hud.createHud

hud.createHud = function(...)
    local hudObject = oldCreateHud(...)

    local btnToggleVisionMode = hudObject._screen.binder.topPnl.binder.btnToggleVisionMode
    if btnToggleVisionMode and not btnToggleVisionMode.isnull then -- Vision Mode
        hudObject._uitr_isVisionMode = false
        hudObject.uitr_setVisionMode = hudAppend.uitr_setVisionMode
        hudObject.uitr_refreshInfoGlobalButtons = hudAppend.uitr_refreshInfoGlobalButtons

        local oldOnSimEvent = hudObject.onSimEvent
        function hudObject:onSimEvent(ev, ...)
            local result = oldOnSimEvent(self, ev, ...)

            if ev.eventType == simdefs.EV_TURN_END then
                self._game.simCore:uitr_resetAllUnitVision()
                if STICKY_VISIBILITY[uitr_util.checkOption("recentFootprintsMode")] then
                    -- Global toggles are sticky.
                    self._game.boardRig:getPathRig():resetTemporaryVisibility()
                else
                    self._game.boardRig:getPathRig():resetVisibility()
                end
                self._game.boardRig:getPathRig():refreshAllTracks()
            end

            return result
        end

        btnToggleVisionMode:setTooltip(visionModeTooltip(false))
        btnToggleVisionMode:setHotkey("UITR_VISIONMODE")
        btnToggleVisionMode.onClick = util.makeDelegate(nil, onClickVisionToggle, hudObject)

        local btnTogglePaths = hudObject._screen.binder.topPnl.binder.btnInfoTogglePaths
        btnTogglePaths.onClick = util.makeDelegate(nil, onClickPathVisibilityToggle, hudObject)
        local btnToggleTracks = hudObject._screen.binder.topPnl.binder.btnInfoToggleTracks
        btnToggleTracks.onClick = util.makeDelegate(nil, onClickTrackVisibilityToggle, hudObject)
        local btnCyclePathsTracks = hudObject._screen.binder.topPnl.binder.btnInfoCyclePathsTracks
        btnCyclePathsTracks:setHotkey("UITR_CYCLE_PATH_FOOTPRINT")
        btnCyclePathsTracks.onClick = util.makeDelegate(
                nil, onClickPathTrackVisibilityCycle, hudObject)
        hudObject:uitr_refreshInfoGlobalButtons()
    end

    do -- Grid Coordinates, HUD-refresh for Info global buttons.
        hudObject._refreshUITRGridCoordinates = hudAppend._refreshUITRGridCoordinates
        hudObject._refreshUITRGridCoordinatesAgentRelative =
                hudAppend._refreshUITRGridCoordinatesAgentRelative

        local oldRefreshHud = hudObject.refreshHud
        function hudObject:refreshHud(...)
            oldRefreshHud(self, ...)

            self:uitr_refreshInfoGlobalButtons()
            self:_refreshUITRGridCoordinates()
        end
    end

    do -- Cloak Distance
        hudObject._showMovementRange_fixCloakDistance =
                hudAppend._showMovementRange_fixCloakDistance

        local oldShowMovementRange = hudObject.showMovementRange
        function hudObject:showMovementRange(unit, ...)
            oldShowMovementRange(self, unit, ...)

            self:_showMovementRange_fixCloakDistance(unit)
        end
    end

    return hudObject
end
