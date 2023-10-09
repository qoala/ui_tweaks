-- Colored Tracks: Core functionality shared between multiple rigs.
local color = include("modules/color")

PATH_COLORS = {
    color(0, 1, 0.1, 1.0), -- Green
    color(1, 1, 0.1, 1.0), -- Yellow
    color(1, 0.7, 0.1, 1.0), -- Orange
    color(1, 1, 0.6, 1.0), -- Pale Yellow
    color(0.5, 1, 0.7, 1.0), -- Pale Green
    color(0, 0.7, 0.7, 1.0), -- Teal
}

local _M = {}

_M.path_color_idx = 0

function _M:assignColor(unit)
    local traits = unit:getTraits()
    if not traits.pathColor then
        traits.pathColor = PATH_COLORS[(self.path_color_idx % #PATH_COLORS) + 1]
        self.path_color_idx = self.path_color_idx + 1
    end
    return traits.pathColor
end

return _M
