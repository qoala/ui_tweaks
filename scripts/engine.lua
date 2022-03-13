
local simengine = include( "sim/engine" )

function simengine:uitr_resetAllUnitVision()
	for unitID,unit in pairs( self:getAllUnits() ) do
		unit:getTraits().uitr_hideVision = nil
	end
end
