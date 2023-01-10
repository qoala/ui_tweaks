local mui_defs = include("mui/mui_defs")
local mui_tooltip = include("mui/mui_tooltip")
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
        self._game.boardRig:refresh()
    end
    self:refreshHud()
end

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
    local x, y = unit:getLocation()
    if not x then
        return
    end

    for i, lbl in ipairs(GRID_N_LABELS) do
        createGridCoordinate(self, x, y + i, lbl)
    end
    for i, lbl in ipairs(GRID_S_LABELS) do
        createGridCoordinate(self, x, y - i, lbl)
    end
    for i, lbl in ipairs(GRID_E_LABELS) do
        createGridCoordinate(self, x + i, y, lbl)
    end
    for i, lbl in ipairs(GRID_W_LABELS) do
        createGridCoordinate(self, x - i, y, lbl)
    end
end

function hudAppend:_refreshUITRGridCoordinates()
    self._world_hud:destroyWidgets(HUD_GRID_COORDS)

    local gridOption = uitr_util.checkOption("gridCoords")
    if gridOption == 1 then
        self:_refreshUITRGridCoordinatesAgentRelative()
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

        local oldOnSimEvent = hudObject.onSimEvent
        function hudObject:onSimEvent(ev, ...)
            local result = oldOnSimEvent(self, ev, ...)

            if ev.eventType == simdefs.EV_TURN_END then
                self._game.simCore:uitr_resetAllUnitVision()
            end

            return result
        end

        btnToggleVisionMode:setTooltip(visionModeTooltip(false))
        btnToggleVisionMode:setHotkey("UITR_VISIONMODE")
        btnToggleVisionMode.onClick = util.makeDelegate(nil, onClickVisionToggle, hudObject)
    end

    do -- Grid Coordinates
        hudObject._refreshUITRGridCoordinates = hudAppend._refreshUITRGridCoordinates
        hudObject._refreshUITRGridCoordinatesAgentRelative =
                hudAppend._refreshUITRGridCoordinatesAgentRelative

        local oldRefreshHud = hudObject.refreshHud
        function hudObject:refreshHud(...)
            oldRefreshHud(self, ...)

            self:_refreshUITRGridCoordinates()
        end
    end

    return hudObject
end
