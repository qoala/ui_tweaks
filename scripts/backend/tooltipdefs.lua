local util = include("modules/util")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

local function _calculateCloakDistance(unit)
    if not unit:getTraits().cloakDistance then
        return nil
    end

    -- Cloak Distance causes cloaks to break when <= 0, but that's not how MP and ranges
    -- are calculated. The correct offset is an infinitesimal.
    local dist = math.max(unit:getTraits().cloakDistance - 0.00001, 0)
    return uitr_util.roundMP(dist)
end

local function agentCloakInfoText(unit)
    local tileCount = _calculateCloakDistance(unit)
    if not tileCount then
        return util.sformat(
                STRINGS.UITWEAKSR.UI.INVIS_COUNTDOWN_TIP, unit:getTraits().invisDuration or '-')
    elseif tileCount == 0 then
        return util.sformat(
                STRINGS.UITWEAKSR.UI.INVIS_COUNTDOWN_TIP_EXACT_DIST, unit:getTraits().invisDuration,
                tileCount)
    else
        return util.sformat(
                STRINGS.UITWEAKSR.UI.INVIS_COUNTDOWN_TIP_FUZZY_DIST, unit:getTraits().invisDuration,
                tileCount)
    end
end

local function onAgentTooltip(tooltip, unit)
    if unit:getTraits().invisible then
        -- Check For RolandJ's original mod. Don't duplicate the tooltip if both are present.
        local RJInvisTooltip =
                (unit:getSim():getParams().difficultyOptions.RJ_InvisiTooltip_Enabled or {}).enabled
        local uitrInvisOption = uitr_util.checkOption("invisCountdown")
        if not RJInvisTooltip and uitrInvisOption then
            tooltip:addAbility(
                    STRINGS.UITWEAKSR.UI.INVIS_COUNTDOWN_HEADER, agentCloakInfoText(unit),
                    "gui/items/icon-cloak.png")
        end
    end
end

return { --
    agentCloakInfoText = agentCloakInfoText,
    tooltips = {onAgentTooltip = onAgentTooltip},
}
