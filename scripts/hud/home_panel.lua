local mui_tooltip = include("mui/mui_tooltip")
local cdefs = include("client_defs")
local util = include("client_util")
local panel = include("hud/home_panel").panel

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")
local tooltipdefs = include(SCRIPT_PATHS.qed_uitr .. "/backend/tooltipdefs")

local function generateCloakedAgentTooltip(hud, unit)
    local txt = unit:getUnitData().toolTip .. "\n" .. tooltipdefs.agentCloakInfoText(unit)
    return mui_tooltip(util.toupper(unit:getName()), txt, "cycleSelection")
end

local oldRefreshAgent = panel.refreshAgent
function panel:refreshAgent(unit, ...)
    oldRefreshAgent(self, unit, ...)

    local widget = self:findAgentWidget(unit:getID())
    if widget == nil then
        return
    end
    self:_uitr_refreshAgentAp(unit, widget)
    self:_uitr_refreshAgentStatus(unit, widget)
    self:_uitr_refreshAgentCloakInfo(unit, widget, widget.binder.uitrStatusCloak)
end

function panel:_uitr_refreshAgentAp(unit, widget)
    if not uitr_util.checkOption("preciseAp") then
        return
    end

    local mp = unit:getMP()
    local hud = self._hud
    local movePreview = hud._movePreview
    local abilPreview = hud._abilityPreviewData and hud._abilityPreviewData[unit:getID()]
    if movePreview and movePreview.unitID == unit:getID() and mp >= movePreview.pathCost then
        mp = mp - movePreview.pathCost
    elseif abilPreview and abilPreview.moveCost and mp >= abilPreview.moveCost then
        mp = mp - abilPreview.moveCost
        if abilPreview.moveCost > 0 then
            widget.binder.apNum:setColor(cdefs.AP_COLOR_PREVIEW:unpack())
            widget.binder.apTxt:setColor(cdefs.AP_COLOR_PREVIEW:unpack())
        elseif abilPreview.moveCost < 0 then
            widget.binder.apNum:setColor(cdefs.AP_COLOR_PREVIEW_BONUS:unpack())
            widget.binder.apTxt:setColor(cdefs.AP_COLOR_PREVIEW_BONUS:unpack())
        end
        -- No need to reset or color non-ability-preview cases. Vanilla refresh does so.
    end
    widget.binder.apNum:setText(uitr_util.roundPointFive(mp))
end

local function isHacking(unit)
    return unit:getTraits().data_hacking or unit:getTraits().monster_hacking or
                   unit:getTraits().mod_data_hacking
end

function panel:_uitr_refreshAgentStatus(unit, widget)
    local stat = nil
    if not uitr_util.checkOption("agentStatusIcons") then
        -- No lights.
    elseif unit:getTraits().isMeleeAiming then
        stat = 1
        -- screens rotation value is unused, so set it here.
        -- widget.binder.uitrStatusAmbush:setRotation(-90)
    elseif unit:isAiming() then
        stat = 2
    elseif isHacking(unit) then
        stat = 3
    end
    widget.binder.uitrStatusAmbush:setVisible(stat == 1)
    widget.binder.uitrStatusOverwatch:setVisible(stat == 2)
    widget.binder.uitrStatusHacking:setVisible(stat == 3)
end

function panel:_uitr_refreshAgentCloakInfo(unit, agentWidget, widget)
    -- If cloaked and not down, show details.
    -- If the agent is down, that text takes up all the space instead.
    -- Always runs, because we need to be able to hide previously shown info.
    local uitrInvisOption = uitr_util.checkOption("invisCountdown")
    local isCloak = (uitrInvisOption == 2) and (not unit:isDown()) and
                            (not not unit:getTraits().invisible)
    local cloakDist = isCloak and unit:getTraits().cloakDistance or nil
    widget:setVisible(isCloak)

    if isCloak then
        agentWidget:setTooltip(generateCloakedAgentTooltip(self._hud, unit))

        local cloakTurns = unit:getTraits().invisDuration
        cloakTurns = cloakTurns and math.max(math.floor(cloakTurns), 0)

        local isBroken = false
        if cloakDist then
            cloakDist = math.max(cloakDist - 0.00001, 0.00001)
            -- Cloak distance ONLY decreases with movePreview, not abilityPreview.
            if self._hud._movePreview and self._hud._movePreview.unitID == unit:getID() then
                cloakDist = cloakDist - self._hud._movePreview.pathCost
                if cloakDist <= 0 then
                    cloakTurns = '-'
                    cloakDist = '--'
                    isBroken = true
                end
            end

            widget.binder.apNum:setText(uitr_util.roundMP(cloakDist))
            -- Insufficient space for "TURN(S)"
            widget.binder.turnTxt:setText(STRINGS.UITWEAKSR.UI.INVIS_COUNTDOWN_TURNS_SHORT)
        else
            -- Pluralize
            widget.binder.turnTxt:setText(
                    util.sformat(
                            STRINGS.UITWEAKSR.UI.INVIS_COUNTDOWN_TURNS, cloakTurns or 0))
        end

        widget.binder.turnNum:setText(cloakTurns or '-')
        widget.binder.apNum:setVisible(cloakDist ~= nil)
        widget.binder.apTxt:setVisible(cloakDist ~= nil)
        widget.binder.strikethrough:setVisible(isBroken)
        if isBroken then
            local clr = cdefs.COLOR_CORP_WARNING
            widget.binder.header:setColor(clr.r, clr.g, clr.b, 1)
            widget.binder.turnNum:setColor(clr.r, clr.g, clr.b, 1)
            widget.binder.turnTxt:setColor(clr.r, clr.g, clr.b, 1)
            widget.binder.apNum:setColor(clr.r, clr.g, clr.b, 1)
            widget.binder.apTxt:setColor(clr.r, clr.g, clr.b, 1)
        else
            widget.binder.header:setColor(0.9, 0.9, 0.9, 1)
            widget.binder.turnNum:setColor(0.9, 0.9, 0.9, 1)
            widget.binder.turnTxt:setColor(0.9, 0.9, 0.9, 1)
            widget.binder.apNum:setColor(0.9, 0.9, 0.9, 1)
            widget.binder.apTxt:setColor(0.9, 0.9, 0.9, 1)
        end
    end
end
