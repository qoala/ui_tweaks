
local abilitydefs = include( "sim/abilitydefs" )
local simquery = include( "sim/simquery" )

local TRIGGERS_OVERWATCH_ABILITIES = {
	"compile_software",
	"disarmtrap",
	"doorMechanism",
	-- "lastWords", -- No need to warn about this one. The normal tooltip should make this obvious.
	"peek",
	"throw",
}

local TRIGGERS_OVERWATCH_FUNCTIONS = {
	jackin = function(self, sim, abilityOwner, abilityUser)
		return (
			-- Can only trigger overwatch on the abilityOwner.
			abilityOwner == abilityUser
			-- Wireless hacking apparently counts as magic here.
			and not abilityUser:getTraits().wireless_range
		)
	end,
	jackin_charge = function(self, sim, abilityOwner, abilityUser)
		-- Can only trigger overwatch on the abilityOwner.
		-- So doesn't apply to the vanilla prototype chip, but could apply if added directly to a modded agent.
		return abilityOwner == abilityUser
	end,
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
