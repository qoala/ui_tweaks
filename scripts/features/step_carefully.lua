local astar = include("modules/astar")
local astar_handlers = include("sim/astar_handlers")
local simdefs = include("sim/simdefs")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

-- ===================
-- modules/astar.AStar
-- ===================

local oldAStarTracePath = astar.AStar._tracePath
function astar.AStar:_tracePath(n, ...)
    -- restore realCost if present
    if n.realCost then
        local p = n
        while p do
            p.mCost = p.realCost or p.mCost
            p = p.parent
        end
    end

    return oldAStarTracePath(self, n, ...)
end

-- ==========================
-- sim/astar_handlers.handler
-- ==========================

local oldHandlerGetNode = astar_handlers.handler.getNode
function astar_handlers.handler:getNode(cell, parentNode, ...)
    local n = oldHandlerGetNode(self, cell, parentNode, ...)
    if n and uitr_util.checkOption("stepCarefully") and self._unit and self._unit:isPC() then
        -- mCost: algorithmic cost of the move (includes avoidance penalties)
        -- realCost: true MP cost of the move
        n.realCost = 0
    end
    return n
end

-- Given a watched cell, check if the unit has any scurry benefits.
-- Returns [state], [isEscape]
-- WATCHED: unit is scurrying past some unit(s), but is still watched by others.
-- NOTICED: all full watchers are being prevented by scurry.
-- isEscape: this move escapes overwatch via scurry!
local function predictScurry(sim, unit, cellx, celly)
    if not unit:getTraits().ITB_HenryImpass then
        return false, false
    end
    local player = unit:getPlayerOwner()
    local simquery = sim:getQuery()

    local isWatched = false
    -- Is any scurry happening? Does it escape an overwatch?
    local isScurry, isEscape = false, false

    local seers = sim:getLOS():getSeers(cellx, celly)
    for _, seerID in ipairs(seers) do
        local seerUnit
        if seerID >= simdefs.SEERID_PERIPHERAL then
            seerUnit = sim:getUnit(seerID - simdefs.SEERID_PERIPHERAL)
        else
            seerUnit = sim:getUnit(seerID)
        end

        if seerUnit and seerUnit:getPlayerOwner() ~= player and
                simquery.canSeeLOS(sim, player, seerUnit) then
            local x1, y1 = seerUnit:getLocation()
            if cellx == x1 and celly == y1 then
                -- Not seen. Unit is scurrying through.
                isScurry = true
                local senses = seerUnit:getBrain() and seerUnit:getBrain():getSenses()
                if senses:hasTarget(unit) then
                    -- Escape overwatch through scurry. Very valuable.
                    isEscape = true
                end
            elseif simquery.checkCover(sim, seerUnit, cellx, celly) then
                -- Not seen. Hidden.
            else
                isWatched = true
            end
        end
    end

    if not isScurry then
        -- No scurry benefits.
        return false, false
    elseif isWatched then
        return simdefs.CELL_WATCHED, isEscape
    else
        -- Even with no other seers, scurrying still gets noticed by the target.
        return simdefs.CELL_NOTICED, isEscape
    end
end

local oldHandlerHandleNode = astar_handlers.handler._handleNode
function astar_handlers.handler:_handleNode(to_cell, from_node, goal_cell, ...)
    if not uitr_util.checkOption("stepCarefully") or not self._unit or not self._unit:isPC() then
        return oldHandlerHandleNode(self, to_cell, from_node, goal_cell, ...)
    end

    -- Hide max MP from the original fn.
    -- Perform the max MP check ourselves.
    local maxMP = self._maxMP
    self._maxMP = nil

    local n = oldHandlerHandleNode(self, to_cell, from_node, goal_cell, ...)

    if n then
        local simquery = self._sim:getQuery()

        -- Update real MP cost. If Neptune is installed, use the alternate move cost fn.
        local dc
        if simquery.getTrueMoveCost then
            dc = simquery.getTrueMoveCost(self._unit, from_node.location, to_cell)
        else
            dc = simquery.getMoveCost(from_node.location, to_cell)
        end
        n.realCost = from_node.realCost + dc

        -- Check max MP against the real MP cost.
        if maxMP and maxMP < n.realCost then
            return
        end

        -- Penalize paths for moving through watched and noticed tiles.
        -- Penalty is less than difference between paths with different real mp costs for reasonable path lengths.
        local watchState = simquery.isCellWatched(
                self._sim, self._unit:getPlayerOwner(), to_cell.x, to_cell.y)
        local isScurry, isScurryEscape = false, false
        if watchState == simdefs.CELL_WATCHED then
            local scurryWatchState, isEscape = predictScurry(
                    self._sim, self._unit, to_cell.x, to_cell.y)
            if scurryWatchState then
                watchState = scurryWatchState
                isScurry = true
                isScurryEscape = isEscape
            end
        end

        if isScurryEscape then
            -- Escaping overwatch (without any other watchers) beats all other concerns.
            n.mCost = n.mCost - 0.001
            n.score = n.score - 0.001
        elseif watchState == simdefs.CELL_WATCHED then
            if isScurry then
                -- Scurrying through a unit is slightly more favorable than other watched tiles.
                n.mCost = n.mCost + 0.0005
                n.score = n.score + 0.0005
            else
                n.mCost = n.mCost + 0.001
                n.score = n.score + 0.001
            end
        elseif watchState == simdefs.CELL_NOTICED then
            n.mCost = n.mCost + 0.000001
            n.score = n.score + 0.000001
        end
    end

    self._maxMP = maxMP
    return n
end
