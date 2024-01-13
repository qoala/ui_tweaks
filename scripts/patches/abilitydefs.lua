local abilityutil = include("sim/abilities/abilityutil")
local abilitydefs = include("sim/abilitydefs")
local simquery = include("sim/simquery")

local TRIGGERS_OVERWATCH_ABILITIES = {
    "compile_software",
    "disarmtrap",
    "doorMechanism",
    -- "lastWords", -- No need to warn about this one. The normal tooltip should make this obvious.
    "manualHack",
    "melee",
    "peek",
    "shootSingle",
    "throw",
}

-- Some abilities only trigger overwatch on the abilityOwner, so don't trigger if the ability is on a held item (example: prototype chip)
local function triggersOverwatchWithoutWirelessHacking(self, sim, abilityOwner, abilityUser)
    return abilityOwner == abilityUser and abilityUser and
                   not abilityUser:getTraits().wireless_range
end

local TRIGGERS_OVERWATCH_FUNCTIONS = {
    execute_protocol = triggersOverwatchWithoutWirelessHacking,
    jackin = triggersOverwatchWithoutWirelessHacking,
    jackin_charge = abilityutil.triggersOverwatchOnOwnerOnly,
    useInvisiCloak = abilityutil.triggersOverwatchAfterCloaking,
}

local function patchOverwatchFlag()
    for _, abilityID in ipairs(TRIGGERS_OVERWATCH_ABILITIES) do
        local ability = abilitydefs.lookupAbility(abilityID)
        if ability and ability.triggersOverwatch == nil then
            ability.triggersOverwatch = true
        end
    end
    for abilityID, fn in pairs(TRIGGERS_OVERWATCH_FUNCTIONS) do
        local ability = abilitydefs.lookupAbility(abilityID)
        if ability and ability.triggersOverwatch == nil then
            ability.triggersOverwatch = fn
        end
    end
end

local function patchObservePath()
    local observePath = abilitydefs.lookupAbility("observePath")
    observePath.createToolTip = function( self, sim, abilityOwner, abilityUser, targetID )
        local target = sim:getUnit(targetID)
        local observe_title = STRINGS.ABILITIES.OBSERVE .. " " .. target:getUnitData().name
        return abilityutil.formatToolTip(observe_title, STRINGS.ABILITIES.OBSERVE_DESC)
    end
end

return {patchOverwatchFlag = patchOverwatchFlag,
        patchObservePath = patchObservePath}
