local simquery = include( "sim/simquery" )

local oldCanSeeLOS = simquery.canSeeLOS

function simquery.canSeeLOS( sim, player, seer, ... )
	if sim:getTags().uitr_oneVision and player ~= seer:getPlayerOwner() and sim:getTags().uitr_oneVision ~= seer:getID() then
		return false
	end

	if seer:getTraits().uitr_hideVision then
		return false
	end

	return oldCanSeeLOS( sim, player, seer, ... )
end
