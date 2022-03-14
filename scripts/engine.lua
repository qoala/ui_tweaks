
local simengine = include( "sim/engine" )

function simengine:uitr_resetAllUnitVision()
	sim:getTags().uitr_oneCellVision = nil
	sim:getTags().uitr_oneVision = nil

	for unitID,unit in pairs( self:getAllUnits() ) do
		unit:getTraits().uitr_hideVision = nil
	end
end
