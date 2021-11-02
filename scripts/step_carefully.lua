
local astar = include( "modules/astar" )
local astar_handlers = include( "sim/astar_handlers" )
local simdefs = include( "sim/simdefs" )

-- ===================
-- modules/astar.AStar
-- ===================

local function aStarTracePath( originalFunction, self, n, ... )
	-- restore realCost if present
	if n.realCost then
		local p = n
		while p do
			p.mCost = p.realCost or p.mCost
			p = p.parent
		end
	end

	return originalFunction( self, n, ... )
end

-- ==========================
-- sim/astar_handlers.handler
-- ==========================

local function getNode( originalFunction, self, cell, parentNode, ... )
	local n = originalFunction( self, cell, parentNode, ... )
	if n then
		-- mCost: algorithmic cost of the move (includes avoidance penalties)
		-- realCost: true MP cost of the move
		n.realCost = 0
	end
	return n
end

local function handleNode( originalFunction, self, to_cell, from_node, goal_cell, ... )
	if not self._unit:isPC() then
		return originalFunction( self, to_cell, from_node, goal_cell, ... )
	end

	-- Hide max MP from the original function.
	-- Perform the max MP check ourselves.
	local maxMP = self._maxMP
	self._maxMP = nil

	local n = originalFunction( self, to_cell, from_node, goal_cell, ... )

	if n then
		local simquery = self._sim:getQuery()

		-- Update real MP cost. If Neptune is installed, use the alternate move cost function.
		local dc
		if simquery.getTrueMoveCost then
			dc = simquery.getTrueMoveCost( self._unit, from_node.location, to_cell )
		else
			dc = simquery.getMoveCost( from_node.location, to_cell )
		end
		n.realCost = from_node.realCost + dc

		-- Check max MP against the real MP cost.
		if maxMP and maxMP < n.realCost then
			return
		end

		-- Penalize paths for moving through watched and noticed tiles.
		-- Penalty is less than difference between paths with different real mp costs for reasonable path lengths.
		local watchState = simquery.isCellWatched( self._sim, self._unit:getPlayerOwner(), to_cell.x, to_cell.y )
		if watchState == simdefs.CELL_WATCHED then
			n.mCost = n.mCost + 0.001
			n.score = n.score + 0.001
		elseif watchState == simdefs.CELL_NOTICED then
			n.mCost = n.mCost + 0.00001
			n.score = n.score + 0.00001
		end
	end

	self._maxMP = maxMP
	return n
end


local patches = {
	{ package = astar.AStar, name = '_tracePath', f = aStarTracePath },
	{ package = astar_handlers.handler, name = 'getNode', f = getNode },
	{ package = astar_handlers.handler, name = '_handleNode', f = handleNode },
}

return monkeyPatch(patches)
