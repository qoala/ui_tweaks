local util = include( "client_util" )
local button_layout = include( "hud/button_layout" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local mui = include("mui/mui")
local mui_defs = include( "mui/mui_defs")
local cdefs = include( "client_defs" )

local mainframe_layout = class( button_layout )

function mainframe_layout:init()
	button_layout.init( self, 0, 0 ) -- Target lines vary around a semi-fixed offset, instead of radiating away from the current agent.
end

local function hasArm( widget )
	return widget.binder and widget.binder.arm and not widget.binder.arm.isnull
end

function mainframe_layout:calculateLayout( screen, game, widgets )
	for i, widget in ipairs( widgets ) do
        assert( widget.worldx )

		-- UITR: Use the ownerID (target unit ID) + skin name as the layout ID.
		--       If the widget lacks an ownerID (such as the "rebooting" floater or an activatable device),
		--       or lacks an "arm" child widget ("Target", instead of "BreakIce")
		local layoutID = nil
		if widget.layoutID and widget.ownerID and hasArm(widget) then
			layoutID = widget.layoutID
		elseif widget.ownerID and widget.getName and hasArm(widget) then
			layoutID = tostring(widget.ownerID) .. ":" .. widget:getName()
			widget.layoutID = layoutID
		else
			-- UITR: Other widgets should be drawn directly on their coordinates.
			widget.layoutID = nil
			widget.layoutStatic = true
			-- TODO: Insert bounds into the static forcing coordinates list for Activate/Target/etc?
		end

		if layoutID then
			local layout = self._layout[ layoutID ]
			if layout == nil then
				local leaderWidget = screen:createFromSkin( "LineLeader" )
				screen:addWidget( leaderWidget )
				leaderWidget.binder.line:appear( 0.5 )
				layout =
					{
						widgets = { widget },
						leaderWidget = leaderWidget
					}
				self._layout[ layoutID ] = layout
			end

			-- UITR: Each layout entry only gets a single widget, unlike the meatspace button layout.
			layout.widgets[1] = widget

			local wx, wy = game:worldToWnd( widget.worldx, widget.worldy, widget.worldz )
			layout.startx, layout.starty = wx, wy
			layout.posx, layout.posy = wx, wy

			-- UITR: Instead of radiating the offset away from a center point on the selected agent,
			--       Use a fixed offset as the base offset.
			local ox, oy = -18, -59
			local radius = mathutil.dist2d( 0, 0, ox, oy )
			-- Vary by a delta dependent on the widget index so that widgets that originate at the same
			-- world location don't end up being in the exact same position.
			-- local dox, doy = 4 * math.cos( 2*math.pi * (i / #widgets) ), 8 * math.sin( 2*math.pi * (i / #widgets ))
			-- ox, oy = ox + dox, oy + doy
			-- local dist = mathutil.dist2d( 0, 0, ox, oy )
			-- local radius = self._tuning.initRadius
			-- layout.posx, layout.posy = layout.posx + radius * ox / dist, layout.posy + radius * oy / dist
			layout.posx, layout.posy = layout.posx + ox, layout.posy + oy

			-- UITR: We'll be drawing our own arm, thank you very much.
			if hasArm(widget) then
				widget.binder.arm:setVisible(false)
			end

			-- Mark
			layout.active = true
		end
	end

	-- and Sweep
	-- UITR: Unlike meatspace buttons, mainframe widgets are retained across refreshes.
	--       So this layout is also retained and needs to cleanup layout elements for any widgets that disappeared.
	for _,k in ipairs(util.tkeys(self._layout)) do
		local layout = self._layout[k]
		if layout.active then
			layout.active = nil
		else
			screen:removeWidget(layout.leaderWidget)
			self._layout[k] = nil
		end
	end

	for i, coords in ipairs( self._statics ) do
		coords.posx, coords.posy = game:worldToWnd( coords[1], coords[2], coords[3] )
	end

	local iters = 0
	while iters < self._tuning.maxIters and self:hasOverlaps( self._layout, self._statics ) do
		self:doPass( self._layout, self._statics )
		iters = iters + 1
	end
end

function mainframe_layout:setPosition( widget )
	if widget.layoutFixed then
		-- UITR: This is a non-targeting widget, such as the 'rebooting' floater. Let the HUD draw it directly.
		return false
	end

	local layout = self._layout[ widget.layoutID ]
	if not layout then
		return false
	end

	-- UITR: Follow the implementation of button_layout:setPosition to place the button at the selected offset.
	--       Skip the steps that vary based on index within the layout element. Each element has only 1 widget.
	local W, H = widget:getScreen():getResolution()
	local x, y = widget:getScreen():wndToUI( layout.posx, layout.posy )
	local startx, starty = widget:getScreen():wndToUI( layout.startx, layout.starty )

	if hasArm(widget) then
		-- UITR: Adjust the widget position to re-center on the button instead of the arm endpoint.
		local ARM_OFFSET_X, ARM_OFFSET_Y = (18/W), (-59/H)
		widget:setPosition( x + ARM_OFFSET_X, y + ARM_OFFSET_Y )
	else
		widget:setPosition( x, y )
	end

	-- UITR: Line goes from the target unit to near the bottom-center of the button, then stays there.
	--       Instead of from target unit, to one side of an underline, to the other side of the underline.
	layout.leaderWidget:setPosition( startx, starty )
	local BUTTON_OFFSET_Y = ((36/2 - 4) / H)
	local x0, y0 = x - startx, y - BUTTON_OFFSET_Y - starty
	layout.leaderWidget.binder.line:setTarget( x0, y0, x0, y0 )
	return true
end

return mainframe_layout
