local simquery = include( "sim/simquery" )

local oldCanSeeLOS = simquery.canSeeLOS

function simquery.canSeeLOS( sim, player, seer, ... )
	if seer:getTraits().uitr_hideVision then
		return false
	end

	return oldCanSeeLOS( sim, player, seer, ... )
end
