local util = include( "client_util" )
local button_layout = include( "hud/button_layout" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local mui = include("mui/mui")
local mui_defs = include( "mui/mui_defs")
local cdefs = include( "client_defs" )

local uitr_util = include( SCRIPT_PATHS.qed_uitr .. "/uitr_util" )

-- ===

local mainframe_layout = class( button_layout )

local TUNING =
{
	-- Magnitude at which buttons/static regions push away at eachother (button_layout: 5)
	repulseMagnitude = 5,
	-- Inverse squared magnitude is capped at this minimum distance. (button_layout: 40)
	repulseScaleCap = 0.4,
	-- Repulsion is applied up to this amount of separation + bounding radii.
	repulseMaxSep = 20,
	-- Max iterations to figure out a layout placement. (button_layout: 10)
	maxIters = 10,

	-- Horizontal spacing between spacers (both static and wide widgets).
	itemSpacing = 40,

	-- Overlap radius of layout widgets/spacer.
	itemRadius = 21,
	-- Overlap radius of the static bubble at the target circle for a layout item.
	staticIceRadius = 3,
	-- Overlap radius of the static bubble around fixed widgets, by skin name.
	staticRadius = {
		["Activate"] = 31,
		["Target"] = 21,
	},
	-- Additional horizontal spacers for wide fixed widgets, by skin name.
	staticSpacerCount = {
		["Activate"] = 5,
	},
	staticSpacerRadius = {
		["Activate"] = 21,
	},
}

-- Extra element for layout widget-lists to make the layout entry wider.
local SPACER = {}

function mainframe_layout:init()
	button_layout.init( self, 0, 0 ) -- Target lines vary around a semi-fixed offset, instead of radiating away from the current agent.
	self._tuning = util.tcopy(TUNING)

	self._lastSettingsID = -1
	self:refreshTuningSettings()
end

function mainframe_layout:refreshTuningSettings()
	local uitrSettings = uitr_util.getOptions()
	if self._lastSettingsID ~= uitrSettings._tempID then
		self._tuning.repulseMagnitude = uitrSettings.mainframeLayoutMagnitude
		self._tuning.repulseScaleCap = uitrSettings.mainframeLayoutScaleLimit
		self._tuning.repulseMaxSep = uitrSettings.mainframeLayoutMaxSeparation

		self._tuning.itemRadius = uitrSettings.mainframeLayoutItemRadius
		self._tuning.staticIceRadius = uitrSettings.mainframeLayoutStaticIceRadius
		self._tuning.staticRadius["Activate"] = uitrSettings.mainframeLayoutStaticActivateRadius
		self._tuning.staticRadius["Target"] = uitrSettings.mainframeLayoutStaticTargetRadius
		self._tuning.staticSpacerCount["Activate"] = uitrSettings.mainframeLayoutStaticActivateTextWidth
		self._tuning.staticSpacerRadius["Activate"] = uitrSettings.mainframeLayoutStaticActivateTextRadius

		self._lastSettingsID = uitrSettings._tempID
	end
end

local function hasArm( widget )
	return widget.binder and widget.binder.arm and not widget.binder.arm.isnull
end

-- Restore modified widgets if we're destroyed by a settings change.
function mainframe_layout.restoreWidgets( widgets )
	for _, widget in ipairs( widgets ) do
		if hasArm(widget) then
			widget.binder.arm:setVisible(true)
		end
	end
end

function mainframe_layout:calculateLayout( screen, game, widgets )
	-- UITR: Populate the list of statics from static widgets each time we calculate.
	self._statics = {}

	local layoutsByPosition = {}
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

			if widget.getName and self._tuning.staticRadius[widget:getName()] then
				-- UITR: Insert into the static forcing coordinates list to keep clear around this button.
				local radius = self._tuning.staticRadius[widget:getName()]
				local wx, wy = game:worldToWnd( widget.worldx, widget.worldy, widget.worldz )
				table.insert(self._statics, { posx = wx, posy = wy, radius = radius })

				if self._tuning.staticSpacerCount[widget:getName()] then
					for i = 1, self._tuning.staticSpacerCount[widget:getName()] do
						local offset = math.floor(radius * 1.5)
						spacerRadius = self._tuning.staticSpacerRadius[widget:getName()] 
						table.insert(self._statics, { posx = wx + i * offset, posy = wy, radius = spacerRadius or radius })
					end
				end
			end
		end

		if layoutID then
			local layout = self._layout[ layoutID ]
			if layout == nil then
				local leaderWidget = screen:createFromSkin( "MainframeLayoutLineLeader" )
				screen:addWidget( leaderWidget )
				-- UITR: Move to back.
				screen:reorderWidget( leaderWidget, 1 )
				leaderWidget.binder.line:appear( 0.5 )
				layout =
					{
						widgets = { widget },
						leaderWidget = leaderWidget
					}
				self._layout[ layoutID ] = layout
			end

			-- UITR: Each layout entry only gets a single widget, unlike the meatspace button layout.
			--       If the widget is extra-wide, add some dummy entries for the spacing calculations.
			if widget.layoutWide then
				 -- Layout treats each widget as 40px wide.
				 -- program.daemonKnown.bg is 234px wide, including borders.
				layout.widgets = { widget, SPACER, SPACER, SPACER, SPACER }
			else
				layout.widgets = { widget }
			end

			local wx, wy = game:worldToWnd( widget.worldx, widget.worldy, widget.layoutWorldz or widget.worldz )
			layout.startx, layout.starty = wx, wy
			layout.posx, layout.posy = wx, wy

			-- UITR: Keep a small area clear around the target circle for this item.
			if self._tuning.staticIceRadius then
				table.insert(self._statics, { posx = wx, posy = wy, radius = self._tuning.staticIceRadius })
			end

			-- UITR: Instead of radiating the offset away from a center point on the selected agent,
			--       Use a fixed offset as the base offset.
			local ox, oy = -18, -59
			local radius = mathutil.dist2d( 0, 0, ox, oy )
			layout.posx, layout.posy = layout.posx + ox, layout.posy + oy

			-- UITR: Track layouts that start on the exact same coordinate.
			local positionKey = tostring(layout.posx) .. "|" .. tostring(layout.posy)
			if layoutsByPosition[positionKey] then
				table.insert( layoutsByPosition[positionKey], layout )
			else
				layoutsByPosition[positionKey] = { layout }
			end

			-- UITR: We'll be drawing our own arm, thank you very much.
			if hasArm(widget) then
				widget.binder.arm:setVisible(false)
			end

			-- Mark...
			layout.active = true
		end
	end

	-- ...and Sweep
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

	-- UITR: Vary overlapping positions so that they are able to separate in the later calculations.
	--       Unlike base layout, only do this when there's an exact match, so that otherwise colinear items can remain colinear.
	for _,layouts in pairs(layoutsByPosition) do
		if #layouts > 1 then
			for i, layout in ipairs(layouts) do
				local dx, dy = 4 * math.cos( 2*math.pi * (i / #layouts) ), 4 * math.sin( 2*math.pi * (i / #layouts ))
				layout.posx, layout.posy = layout.posx + dx, layout.posy + dy
			end
		end
	end

	local iters = 0
	while iters < self._tuning.maxIters and self:hasOverlaps( self._layout, self._statics ) do
		self:doPass( self._layout, self._statics )
		iters = iters + 1
	end
end

function mainframe_layout:setPosition( widget )
	if not widget.layoutID then
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

	-- UITR: Line goes from the target circle to near the bottom-center of the button, then stays there.
	--       Instead of from target unit, to one side of an underline, to the other side of the underline.
	layout.leaderWidget:setPosition( startx, starty )
	local BUTTON_OFFSET_Y = ((36/2 - 4) / H)
	local x1, y1 = x - startx, y - BUTTON_OFFSET_Y - starty
	local wndDist = mathutil.dist2d( layout.startx, layout.starty, layout.posx, layout.posy - (36/2 - 4) )
	local t0 = 8 / wndDist -- target circle is 16x16
	layout.leaderWidget.binder.line:setTarget( t0, x1, y1 )
	return true
end

-- ===
-- Calculation tweaks
-- ===

function mainframe_layout:getCircle( layoutID, index )

	local OFFSET_X = self._tuning.itemSpacing
	local ll = self._layout[ layoutID ]
	return ll.posx + OFFSET_X * (index-1), ll.posy, (ll.widgets[index].layoutRadius or self._tuning.itemRadius)
end

function mainframe_layout:getStaticCircle( static )
	return static.posx, static.posy, static.radius
end

function mainframe_layout:hasOverlaps( layout, statics )
	local overlaps = 0
	for layoutID, l in pairs( layout ) do
		for i = 1, #l.widgets do
			local x0, y0, r0 = self:getCircle( layoutID, i )
			for w2, ll in pairs(layout) do
				if w2 ~= layoutID then
					for j = 1, #ll.widgets do
						local x1, y1, r1 = self:getCircle( w2, j )
						if mathutil.dist2d( x0, y0, x1, y1 ) <= r0+r1 then
							return true
						end
					end
				end
			end
			for i, static in pairs(statics) do
				local x1, y1, r1 = self:getStaticCircle( static )
				if mathutil.dist2d( x0, y0, x1, y1 ) <= r0+r1 then
					return true
				end
			end
		end
	end

	return false
end

function mainframe_layout:updateForce( fx, fy, dx, dy, radius )
	local mag = self._tuning.repulseMagnitude
	if mag then
		local SCALE_DIST = radius * self._tuning.repulseScaleCap
		local MAX_DIST = radius + self._tuning.repulseMaxSep
		local d = math.sqrt( dx*dx + dy*dy )
		if d < 1 then
			mag = 0
		elseif d > MAX_DIST then
			-- Far enough apart.
			mag = 0
		else
			mag = mag * math.min( 1, (SCALE_DIST * SCALE_DIST) / (d*d)) -- inverse sqr mag.
			dx, dy = dx / d, dy / d
		end

		fx, fy = fx + mag * dx, fy + mag * dy
	end
	return fx, fy
end

function mainframe_layout:calculateForce( layoutID, layout, statics )
	local fx, fy = 0, 0
	local l = layout[ layoutID ]
	for i = 1, #l.widgets do
		local x0, y0, r0 = self:getCircle( layoutID, i )
		for w2, ll in pairs(layout) do
			if w2 ~= layoutID then
				for j = 1, #ll.widgets do
					local x1, y1, r1 = self:getCircle( w2, j )
					fx, fy = self:updateForce( fx, fy, x0 - x1, y0 - y1, r0 + r1 )
				end
			end
		end
		for i, ll in pairs(statics) do
			local x1, y1, r1 = self:getStaticCircle( ll )
			fx, fy = self:updateForce( fx, fy, x0 - x1, y0 - y1, r0 + r1 )
		end
	end

    return fx, fy
end

return mainframe_layout
