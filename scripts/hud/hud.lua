local hud = include("hud/hud")
local mui_defs = include("mui/mui_defs")
local mui_tooltip = include("mui/mui_tooltip")
local util = include("client_util")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")

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

local function hud_uitr_setVisionMode(self, doEnable)
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

local oldCreateHud = hud.createHud

hud.createHud = function(...)
    local hudObject = oldCreateHud(...)

    local btnToggleVisionMode = hudObject._screen.binder.topPnl.binder.btnToggleVisionMode
    if btnToggleVisionMode and not btnToggleVisionMode.isnull then
        hudObject._uitr_isVisionMode = false
        hudObject.uitr_setVisionMode = hud_uitr_setVisionMode

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

    return hudObject
end
