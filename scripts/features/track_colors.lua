-- Colored Tracks: Core functionality shared between multiple rigs.
local color = include("modules/color")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

-- ===

PATH_COLORS = {
    color(0, 1, 0.1, 1.0), -- Green
    color(1, 1, 0.1, 1.0), -- Yellow
    color(1, 0.7, 0.1, 1.0), -- Orange
    color(1, 1, 0.6, 1.0), -- Pale Yellow
    color(0.5, 1, 0.7, 1.0), -- Pale Green
    color(0, 0.7, 0.7, 1.0), -- Teal
}

local _M = {}

function _M._assignColor(unit, traits)
    local sim = unit:getSim()
    local idx = sim._uitr_nextPathColorIndex or 0

    traits.pathColor = PATH_COLORS[(idx % #PATH_COLORS) + 1]

    sim._uitr_nextPathColorIndex = idx + 1
end

-- Assign the unit's UI Track color, if it doesn't already have one.
-- Called only from sim (save/rewind safe).
function _M.ensureUnitHasColor(unit)
    local simquery = unit and unit:getSim():getQuery()
    local traits = unit:getTraits()
    if simquery.isAgent(unit) and not traits.pathColor then
        _M._assignColor(unit, traits)
    end
end

-- Get the unit's UI Track color.
-- Called only from client. Will assign a color if necessary, but log the safety violation.
-- This safety violation only affects minor colors, so not a serious issue.
function _M.getColor(unit)
    local traits = unit:getTraits()
    if not traits.pathColor then
        simlog(
                "[UITR][WARN] Assigning [%d] unit color from client. Colors may change on rewind/reload.%s",
                tostring(unit and unit:getID()),
                (uitr_util.canDebugTrace() and ("\n" .. debug.traceback()) or ""))
        _M._assignColor(unit, traits)
    end
    return traits.pathColor
end

return _M
