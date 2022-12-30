local util = include("client_util")

local uitr_util = include( SCRIPT_PATHS.qed_uitr .. "/uitr_util" )

-- ===
-- Meta helpers
-- ===

if not util.tooltip_section then
	util.tooltip_section = uitr_util.extractUpvalue(util.tooltip.addSection, "tooltip_section")
end

-- ===

-- TODO: Why does this appended function never run?
local oldAppendHeader = util.tooltip_section.appendHeader
function util.tooltip_section:appendHeader( actionTxt, infoTxt, ... )
	oldAppendHeader( self, actionTxt, infoTxt, ... )

	local ctrlBinding = util.getControllerBindingImage and util.getControllerBindingImage(actionTxt)
	local widget = self._children[#self._children]
	local controllerHotkeyImg = widget.binder.controllerHotkey
	if not controllerHotkeyImg.isnull then
		if ctrlBinding then
			controllerHotkeyImg:setImage(ctrlBinding)
			controllerHotkeyImg:setVisible(true)

			-- Overwrite vanilla callback
			-- changes at CBF:
			widget.activate = function( _, screen )
				local TOP_BUFFER = 4
				local W, H = screen:getResolution()
				local rxmin, rymin, rxmax, rymax = widget.binder.lineRight:getStringBounds()
				local xmin, ymin, xmax, ymax = widget.binder.line:getStringBounds()
				local xpos = nil
				if rxmax > rxmin and xmax >= rxmin then
					local tw = math.ceil( W * (rxmin - xmin ))
					widget.binder.line:setSize( tw )
					xpos = tw / 2 + 8 -- HACK: +8 mimics the slight left-padding that normally is inherited from the default line's position
				end
				local xmin, ymin, xmax, ymax = widget.binder.line:getStringBounds()
				local h = math.max(ymax - ymin, 21/H) -- CBF: Enforce minimum height for controller hotkey image.
				local th = math.ceil(H * h / 2) * 2 + TOP_BUFFER
				widget.binder.line:setSize( nil, th )
				widget.binder.line:setPosition( xpos, (th / -2) - TOP_BUFFER )
				widget.binder.controllerHotkey:setPosition( nil, (th / -2) - TOP_BUFFER ) -- CBF: Position controller hotkey image.
			end
		else
			controllerHotkeyImg:setVisible(false)
		end
	end
end
