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

    -- If cloaked and not down, show details.
    -- If the agent is down, that text takes up all the space.
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
        widget.binder.uitrInvisTurnNum:setText(cloakTurns or '-')
        widget.binder.uitrInvisHeader:setText(STRINGS.UITWEAKSR.UI.INVIS_COUNTDOWN_HEADER)
        if cloakDist then
            cloakDist = math.max(cloakDist - 0.00001, 0)

            widget.binder.uitrInvisApNum:setText(math.floor(cloakDist))
            -- Insufficient space for "TURN(S)"
            widget.binder.uitrInvisTurnTxt:setText(STRINGS.UITWEAKSR.UI.INVIS_COUNTDOWN_TURNS_SHORT)
        else
            -- Pluralize
            widget.binder.uitrInvisTurnTxt:setText(
                    util.sformat(
                            STRINGS.UITWEAKSR.UI.INVIS_COUNTDOWN_TURNS, cloakTurns or 0))
        end
    end
end
