
local abilitydefs = include( "sim/abilitydefs" )
local simquery = include( "sim/simquery" )

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
local function triggersOverwatchOnOwnerOnly(self, sim, abilityOwner, abilityUser)
	return abilityOwner == abilityUser
end

local function triggersOverwatchWithoutWirelessHacking(self, sim, abilityOwner, abilityUser)
	return abilityOwner == abilityUser and abilityUser and not abilityUser:getTraits().wireless_range
end

local TRIGGERS_OVERWATCH_FUNCTIONS = {
	execute_protocol = triggersOverwatchWithoutWirelessHacking,
	jackin = triggersOverwatchWithoutWirelessHacking,
	jackin_charge = triggersOverwatchOnOwnerOnly,
	useInvisiCloak = function(self, sim, abilityOwner)
		local userUnit = abilityOwner:getUnitOwner()
		if not userUnit then return end

		-- Technically triggers overwatch broadly, but it only matters if one of them can see invisible.
		-- Check for that to reduce false positives.
		local seers = sim:generateSeers( userUnit )
		for i,seer in ipairs(seers) do
			local unit = sim:getUnit(seer)
			if unit and unit:getTraits().detect_cloak and simquery.couldUnitSee(sim, unit, userUnit) then
				return true
			end
		end
	end
}

local function applyOverwatchFlag( )
	for _,abilityID in ipairs(TRIGGERS_OVERWATCH_ABILITIES) do
		local ability = abilitydefs.lookupAbility(abilityID)
		if ability and ability.triggersOverwatch == nil then
			ability.triggersOverwatch = true
		end
	end
	for abilityID,fn in pairs(TRIGGERS_OVERWATCH_FUNCTIONS) do
		local ability = abilitydefs.lookupAbility(abilityID)
		if ability and ability.triggersOverwatch == nil then
			ability.triggersOverwatch = fn
		end
	end
end

return {
	applyOverwatchFlag = applyOverwatchFlag,
}
