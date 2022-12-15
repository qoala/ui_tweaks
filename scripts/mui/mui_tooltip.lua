local mui_tooltip = include("mui/mui_tooltip")

local uitr_util = include( SCRIPT_PATHS.qed_uitr .. "/uitr_util" )


local OLD_FN_MAPPING = {
	fitOnscreen = mui_tooltip.fitOnscreen,
}

mui_tooltip._uitrmeta_muiTooltipFitOnscreen = true

local oldInit = mui_tooltip.init
function mui_tooltip:init( header, ... )
	uitr_util.propagateSuperclass(getmetatable(self), mui_tooltip, OLD_FN_MAPPING, "_uitrmeta_muiTooltipFitOnscreen", header)

	oldInit( self, header, ... )
end

-- Overwrite base mui_tooltip:fitOnscreen
-- changes at CBF:
function mui_tooltip:fitOnscreen( tw, th, tx, ty )
	local XBUFFER, YBUFFER = 0.02, 0.02 -- Buffer from the edge of the screen

	local ox, oy = self._screen:wndToUI(mui_tooltip.TOOLTIPOFFSETX,mui_tooltip.TOOLTIPOFFSETY)
	-- Ensure the tooltip bounds are on screen.
	if tx < XBUFFER then
		tx = XBUFFER
	end
	-- CBF: separate 'if' instead of 'elseif'. Recheck this bound after the previous adjustment.
	if tx + tw > 1.0 - XBUFFER then
		tx = tx - tw - XBUFFER - ox
	end
	if ty - th < YBUFFER then
		ty = ty + th + YBUFFER
	end
	-- CBF: separate 'if' instead of 'elseif'. Recheck this bound after the previous adjustment.
	if ty > 1.0 - YBUFFER then
		ty = 1.0 - YBUFFER
	end

	-- Also ensure tx, ty are EVEN.  This is a horrible ramification of choosing widget positions to represent the
	-- centre: if the tooltip segments have an even width/height and their centre is chosen on an odd-pixel, then
	-- the widget extents land on a half-pixel boundary resulting usually in a one-pixel distortion.
	local W, H = self._screen:getResolution()
	tx, ty = math.floor(tx * W / 2) * (2 / W), math.floor(ty * H / 2) * (2 / H)

	return tx, ty
end

-- Immediately propagate this to util.tooltip, to cover the vast majority of cases (and apply it before our abilityutil subclass tooltip changes)
-- The init call will catch any further subclasses.
do
	local util = include("client_util")
	uitr_util.propagateSuperclass(util.tooltip, mui_tooltip, OLD_FN_MAPPING, "_uitrmeta_muiTooltipFitOnscreen", "util.tooltip")
end
