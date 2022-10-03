local abilityutil = include("sim/abilities/abilityutil")
local simability = include("sim/simability")

local oldCreate = simability.create

local function isNormalAbility( t )
	return (
		-- Programs and Daemons use a completely different tooltip fn signature.
		t.program == nil and t.standardDaemon == nil and t.reverseDaemon == nil
		-- PE Counter AI Subroutines are not added to ability defs.
		-- Don't modify spells (wizard) for now.
		and t.spellLevel == nil
	)
end

function simability.create( abilityID, ... )
	local t = oldCreate(abilityID, ...)

	if not isNormalAbility(t) then
		return t
	end
	if t.onTooltip or t.createToolTip then
		-- Hide whichever tooltip callbacks exist
		t._uitr_oldOnTooltip = t.onTooltip
		t._uitr_oldCreateToolTip = t.createToolTip

		t.onTooltip = abilityutil.uitr_wrappedOnTooltip
	end
	if t.acquireTargets then
		t._uitr_oldAcquireTargets = t.acquireTargets

		t.acquireTargets = abilityutil.uitr_wrappedAcquireTargets
	end

	return t
end
