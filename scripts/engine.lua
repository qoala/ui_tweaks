
local simengine = include( "sim/engine" )

function simengine:uitr_resetAllUnitVision()
	self:getTags().uitr_oneCellVision = nil
	self:getTags().uitr_oneVision = nil

	for unitID,unit in pairs( self:getAllUnits() ) do
		unit:getTraits().uitr_hideVision = nil
	end
end
