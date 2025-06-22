local abilityutil = include("sim/abilities/abilityutil")
local abilitydefs = include("sim/abilitydefs")

local abil = abilitydefs.lookupAbility("observePath")

abil.createToolTip = function(self, sim, abilityOwner, abilityUser, targetID)
    local target = sim:getUnit(targetID)
    local observe_title = STRINGS.ABILITIES.OBSERVE
    -- List the name of the guard being observed in the tooltip.
    if target then
        observe_title = observe_title .. " " .. target:getName()
    end
    return abilityutil.formatToolTip(observe_title, STRINGS.ABILITIES.OBSERVE_DESC)
end
