
local astar = include( "modules/astar" )
local astar_handlers = include( "sim/astar_handlers" )
local simdefs = include( "sim/simdefs" )

-- ===================
-- modules/astar.AStar
-- ===================

local oldAStarTracePath = astar.AStar._tracePath
function astar.AStar:_tracePath( n, ... )
	-- restore realCost if present
	if n.realCost then
		local p = n
		while p do
			p.mCost = p.realCost or p.mCost
			p = p.parent
		end
	end

	return oldAStarTracePath( self, n, ... )
end

-- ==========================
-- sim/astar_handlers.handler
-- ==========================

local oldHandlerGetNode = astar_handlers.handler.getNode
function astar_handlers.handler:getNode( cell, parentNode, ... )
	local n = oldHandlerGetNode( self, cell, parentNode, ... )
	local uiTweaks = self._sim:getParams().difficultyOptions.uiTweaks
	if n and uiTweaks and uiTweaks.stepCarefully and self._unit and self._unit:isPC() then
		-- mCost: algorithmic cost of the move (includes avoidance penalties)
		-- realCost: true MP cost of the move
		n.realCost = 0
	end
	return n
end

local oldHandlerHandleNode = astar_handlers.handler._handleNode
function astar_handlers.handler:_handleNode( to_cell, from_node, goal_cell, ... )
	local uiTweaks = self._sim:getParams().difficultyOptions.uiTweaks
	if not uiTweaks or not uiTweaks.stepCarefully or not self._unit or not self._unit:isPC() then
		return oldHandlerHandleNode( self, to_cell, from_node, goal_cell, ... )
	end

	-- Hide max MP from the original function.
	-- Perform the max MP check ourselves.
	local maxMP = self._maxMP
	self._maxMP = nil

	local n = oldHandlerHandleNode( self, to_cell, from_node, goal_cell, ... )

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
