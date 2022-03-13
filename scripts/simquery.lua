local simquery = include( "sim/simquery" )

local oldCanSeeLOS = simquery.canSeeLOS

function simquery.canSeeLOS( sim, player, seer, ... )
	if player ~= seer:getPlayerOwner() then
		if sim:getTags().uitr_oneVision and sim:getTags().uitr_oneVision ~= seer:getID() then
			return false
		end

		local x,y = seer:getLocation()
		if sim:getTags().uitr_oneCellVision and sim:getTags().uitr_oneCellVision ~= simquery.toCellID(x,y) then
			return false
		end
	end

	if seer:getTraits().uitr_hideVision then
		return false
	end

	return oldCanSeeLOS( sim, player, seer, ... )
end
