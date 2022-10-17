local simdefs = include("sim/simdefs")
local simengine = include("sim/engine")

local uitr_util = include( SCRIPT_PATHS.qed_uitr .. "/uitr_util" )

local dispatchEvent_old = simengine.dispatchEvent
simengine.dispatchEvent = function( self, evType, evData, noSkip, ... )
	assert( evType )
	if evType == simdefs.EV_UNIT_USECOMP then
		local unitID = evData.unitID
		local unit = self:getUnit( evData.unitID )
		if unit:getTraits().xuShanking then
			return
		end
	end

	return dispatchEvent_old( self, evType, evData, noSkip, ... )
end

local simquery = include("sim/simquery")
local abilitydefs = include( "sim/abilitydefs" )

local manualHack = abilitydefs.lookupAbility("manualHack")
local manualHack_executeAbility_old = manualHack.executeAbility
manualHack.executeAbility = function( self, sim, unit, userUnit, target, ... )
	local xuShank_enabled = uitr_util.checkOption("xuShank")
	local newFacing = nil
	if xuShank_enabled then
		unit:getTraits().xuShanking = true
		local targetUnit = sim:getUnit(target)
		local x0,y0 = userUnit:getLocation()
		local x1,y1 = targetUnit:getLocation()
		newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0)
		sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = unit:getID(), facing = newFacing, sound="SpySociety/Actions/use_scanchip", soundFrame=2 } )
	end

	manualHack_executeAbility_old( self, sim, unit, userUnit, target, ... )

	if unit and xuShank_enabled then
		sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = unit:getID(), facing = newFacing } )
		unit:getTraits().xuShanking = nil
	end
end
