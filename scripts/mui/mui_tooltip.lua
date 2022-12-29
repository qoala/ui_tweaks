local util = require( "modules/util" )
local mui_util = require("mui/mui_util")
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
-- TODO: Enforce minimum width if hotkeyLabel + controllerHotkeyImg are wider than the main label.
local DEFAULT_TOOLTIP = nil
function mui_tooltip:activate( screen )
	self._screen = screen
	if DEFAULT_TOOLTIP == nil then
		DEFAULT_TOOLTIP = screen:createFromSkin( "tooltip" )
	end
	self._tooltipWidget = DEFAULT_TOOLTIP

	self._screen:addWidget( self._tooltipWidget )
	self._tooltipWidget:updatePriority( self.TOOLTIP_PRIORITY )

	local tooltipLabel = self._tooltipWidget.binder.label
	if self._headerTxt then
		tooltipLabel:setText( string.format( "<ttheader>%s</>\n%s", self._headerTxt, self._bodyTxt or "" ))
	else
		tooltipLabel:setText( self._bodyTxt )
	end

	local hotkeyLabel = self._tooltipWidget.binder.hotkey
	local controllerHotkeyImg = self._tooltipWidget.binder.controllerHotkey -- CBF: Controller Bindings widget.
	local hasControllerHotkey = false
	if self._hotkey then
		local binding = util.getKeyBinding( self._hotkey )
		if binding then
			local hotkeyName = mui_util.getBindingName( binding )
			hotkeyLabel:setText( string.format( "%s: <tthotkey>[ %s ]</>", STRINGS.UI.HUD_HOTKEY, hotkeyName ))

			-- CBF: Check for Controller Bindings mod and a corresponding controller binding.
			local ctrlBinding = util.getControllerBindingImage and util.getControllerBindingImage(binding)
			if ctrlBinding and not controllerHotkeyImg.isnull then
				controllerHotkeyImg:setImage(ctrlBinding)
				hasControllerHotkey = true
			end
		else
			hotkeyLabel:setText( nil )
		end
	else
		hotkeyLabel:setText( nil )
	end
	local xmin_hotkey, ymin_hotkey, xmax_hotkey, ymax_hotkey = hotkeyLabel:getStringBounds()

	local W, H = self._screen:getResolution()
	-- String content bounds
	local xmin, ymin, xmax, ymax = tooltipLabel:getStringBounds()
	local x, y, w, h = tooltipLabel:calculateBounds()
	-- Full tooltip width and height, based off string contents bounds, in normalized UI space.
	local X_FUDGE_FACTOR = 6 / W -- This one exists because the string bounds may be inset from the actual label, a delta not easily determined here.
	local tw, th = math.max( xmax - xmin, xmax_hotkey - xmin_hotkey ), ymax - ymin
	tw = tw + 2 * math.abs(x) - w + X_FUDGE_FACTOR
	th = th + 2 * math.abs(y) - h

	local tooltipBg = self._tooltipWidget.binder.bg
	tooltipBg:setSize( W * tw, H * th )
	tooltipBg:setPosition( (W * tw) / 2, H * -th / 2 )

	local footer = self._tooltipWidget.binder.border
	if #hotkeyLabel:getText() > 0 then
		-- CBF: Track intermediates in temp variables, and adjust height for Controller Binding if necessary.
		local footerH = ymax_hotkey - ymin_hotkey
		if hasControllerHotkey then
			footerH = math.max(footerH, 25/H * (footerH >= 0 and 1 or -1))
			controllerHotkeyImg:setVisible(true)
		end
		th = th + 2 * footerH
		local footerY = H * (-th + math.abs(footerH))

		footer:setVisible(true)
		footer:setSize( W * tw, H * footerH + 8 )
		footer:setPosition(W * tw / 2, footerY)
		hotkeyLabel:setPosition(nil, footerY)
		if hasControllerHotkey then
			controllerHotkeyImg:setPosition(W * tw - 12 - 4, footerY)
		end
	else
		footer:setVisible(false)
	end
	if not hasControllerHotkey and not controllerHotkeyImg.isnull then
		controllerHotkeyImg:setVisible(false)
	end

	self._tw, self._th = tw, th
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
