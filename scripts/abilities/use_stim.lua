local abilityutil = include("sim/abilities/abilityutil")
local abilitydefs = include("sim/abilitydefs")

local abil = abilitydefs.lookupAbility("use_stim")

-- Replace createToolTip with onToolTip
abil.createToolTip = nil
function abil:onTooltip(hud, sim, abilityOwner, abilityUser, targetID)
    local target = targetID and sim:getUnit(targetID) or abilityUser
    -- UITR: List the name of the agent being stimmed in the tooltip.
    local title = STRINGS.ABILITIES.STIM .. ": " .. target:getName()
    local body = STRINGS.ABILITIES.STIM_DESC

    -- Add AP Cost preview.
    local apBoost = abilityOwner:getTraits().mpRestored
    local _, reason = abilityUser:canUseAbility(sim, self, abilityOwner, targetID)
    return abilityutil.uitr_ap_tooltip(
            hud, title, body, reason, {{unit = target, apCost = -apBoost}})
end

