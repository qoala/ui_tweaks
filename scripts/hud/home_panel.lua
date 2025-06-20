local cdefs = include("client_defs")
local util = include("client_util")
local panel = include("hud/home_panel").panel

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

local oldRefreshAgent = panel.refreshAgent
function panel:refreshAgent(unit, ...)
    oldRefreshAgent(self, unit, ...)

    local widget = self:findAgentWidget(unit:getID())
    if widget == nil then
        return
    end
    self:_uitr_refreshAgentAp(unit, widget)
    self:_uitr_refreshAgentCloakInfo(unit, widget)
end

function panel:_uitr_refreshAgentAp(unit, widget)
    if not uitr_util.checkOption("preciseAp") then
        return
    end

    local mp = unit:getMP()
    local hud = self._hud
    local movePreview = hud._movePreview
    local abilPreview = hud._abilityPreviewData and hud._abilityPreviewData[unit:getID()]
    if movePreview and movePreview.unitID == unit:getID() and mp > movePreview.pathCost then
        mp = mp - movePreview.pathCost
    elseif abilPreview and abilPreview.moveCost then
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
    widget.binder.apNum:setText(uitr_util.roundMP(mp))
end

function panel:_uitr_refreshAgentCloakInfo(unit, widget)
    -- If cloaked and not down, show details.
    -- If the agent is down, that text takes up all the space instead.
    -- Always runs, because we need to be able to hide previously shown info.
    local uitrInvisOption = uitr_util.checkOption("invisCountdown")
    local isCloak = (uitrInvisOption == 2) and (not unit:isDown()) and
                            (not not unit:getTraits().invisible)
    local cloakDist = isCloak and unit:getTraits().cloakDistance or nil
    widget.binder.uitrInvisHeader:setVisible(isCloak)
    widget.binder.uitrInvisTurnNum:setVisible(isCloak)
    widget.binder.uitrInvisTurnTxt:setVisible(isCloak)
    widget.binder.uitrInvisApNum:setVisible(cloakDist ~= nil)
    widget.binder.uitrInvisApTxt:setVisible(cloakDist ~= nil)

    if isCloak then
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

            widget.binder.uitrInvisApNum:setText(uitr_util.roundMP(cloakDist))
            -- Insufficient space for "TURN(S)"
            widget.binder.uitrInvisTurnTxt:setText(STRINGS.UITWEAKSR.UI.INVIS_COUNTDOWN_TURNS_SHORT)
        else
            -- Pluralize
            widget.binder.uitrInvisTurnTxt:setText(
                    util.sformat(
                            STRINGS.UITWEAKSR.UI.INVIS_COUNTDOWN_TURNS, cloakTurns or 0))
        end

        widget.binder.uitrInvisTurnNum:setText(cloakTurns or '-')
        widget.binder.uitrInvisStrikethrough:setVisible(isBroken)
        if isBroken then
            local clr = cdefs.COLOR_CORP_WARNING
            widget.binder.uitrInvisHeader:setColor(clr.r, clr.g, clr.b, 1)
            widget.binder.uitrInvisTurnNum:setColor(clr.r, clr.g, clr.b, 1)
            widget.binder.uitrInvisTurnTxt:setColor(clr.r, clr.g, clr.b, 1)
            widget.binder.uitrInvisApNum:setColor(clr.r, clr.g, clr.b, 1)
            widget.binder.uitrInvisApTxt:setColor(clr.r, clr.g, clr.b, 1)
        else
            widget.binder.uitrInvisHeader:setColor(0.9, 0.9, 0.9, 1)
            widget.binder.uitrInvisTurnNum:setColor(0.9, 0.9, 0.9, 1)
            widget.binder.uitrInvisTurnTxt:setColor(0.9, 0.9, 0.9, 1)
            widget.binder.uitrInvisApNum:setColor(0.9, 0.9, 0.9, 1)
            widget.binder.uitrInvisApTxt:setColor(0.9, 0.9, 0.9, 1)
        end
    else
        widget.binder.uitrInvisStrikethrough:setVisible(false)
    end
end
