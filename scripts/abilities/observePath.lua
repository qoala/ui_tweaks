local abilityutil = include("sim/abilities/abilityutil")
local abilitydefs = include("sim/abilitydefs")

local abil = abilitydefs.lookupAbility("observePath")

-- Replace createToolTip with onToolTip
abil.createToolTip = nil
function abil:onTooltip(hud, sim, abilityOwner, abilityUser, targetID)
    local target = sim:getUnit(targetID)
    local title = STRINGS.ABILITIES.OBSERVE
    local body = STRINGS.ABILITIES.OBSERVE_DESC
    -- UITR: List the name of the guard being observed in the tooltip.
    if target then
        title = title .. ": " .. target:getName()
    end

    -- Add AP Cost preview.
    local _, reason = abilityUser:canUseAbility(sim, self, abilityOwner, targetID)
    return abilityutil.uitr_ap_tooltip(hud, title, body, reason, {{unit = abilityUser, apCost = 1}})
end
