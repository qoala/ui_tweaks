local util = include( "client_util" )
local button_layout = include( "hud/button_layout" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local mui = include("mui/mui")
local mui_defs = include( "mui/mui_defs")
local cdefs = include( "client_defs" )

local uitr_util = include( SCRIPT_PATHS.qed_uitr .. "/uitr_util" )

-- ===

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
		["Activate"] = 6,
	},
	staticSpacerRadius = {
		["Activate"] = 21,
	},
}

-- Extra elements for layout widget-lists to make the layout entry wider.
-- Left: Horizontal forcing cannot push right.
-- Mid: Horizontal forcing is halved.
-- Right: Horizontal forcing cannot push left.
local MIDDLE_SPACER = { _layoutMid = true }
local LEFT_SPACER = { _layoutLeft = true }
local LEFTMID_SPACER = { _layoutLeft = true, _layoutMid = true }
local RIGHT_SPACER = { _layoutRight = true }
local RIGHTMID_SPACER = { _layoutRight = true, _layoutMid = true }


local mainframe_layout = class( button_layout )

-- This manages static avoidance points very differently.
mainframe_layout.addStaticLayout = nil

function mainframe_layout:init()
	button_layout.init( self, 0, 0 ) -- Target lines vary around a semi-fixed offset, instead of radiating away from the current agent.
	self._tuning = util.tcopy(TUNING)

	self._lastSettingsID = -1
	self:refreshTuningSettings()
	self._dirty = true
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
		self._dirty = true
	end
end

function mainframe_layout:dirtyLayout()
	self._dirty = true
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

function mainframe_layout:_refreshWidgets( screen, game, widgets )
	-- UITR: Populate the list of statics from static widgets each time we calculate.
	self._statics = {}

	-- Mark and Sweep
	-- Unlike meatspace buttons, mainframe widgets are retained across refreshes.
	-- So this layout is also retained and needs to cleanup layout elements for any widgets that disappeared.
	local oldIDs = util.tkeys(self._layout)

	for i, widget in ipairs( widgets ) do
        assert( widget.worldx )

		local layoutID
		if widget.ownerID and widget.getName and hasArm(widget) then
			-- Use the ownerID (target unit ID) + skin name as the layout ID.
			-- Only perform layout on the widget if the widget has an ownerID and "arm" childWidget.
			layoutID = tostring(widget.ownerID) .. ":" .. widget:getName()
			widget._layoutID = layoutID
		else
			-- UITR: other widgets should be drawn directly on their coordinates.
			widget._layoutID = nil

			if widget.getName and self._tuning.staticRadius[widget:getName()] then
				-- UITR: Insert into the static forcing coordinates list to keep clear around this button.
				local radius = self._tuning.staticRadius[widget:getName()]
				table.insert(self._statics, {
					worldx = widget.worldx,
					worldy = widget.worldy,
					worldz = widget.worldz,
					radius = radius,
				})
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
				layout = {
					widgets = { widget },
					leaderWidget = leaderWidget
				}
				self._layout[ layoutID ] = layout
			else
				array.removeElement(oldIDs, layoutID)
			end

			-- UITR: Keep a small area clear around the target circle for this item.
			if self._tuning.staticIceRadius then
				table.insert(self._statics, {
					worldx = widget.worldx,
					worldy = widget.worldy,
					worldz = widget.layoutWorldz or widget.worldz,
					radius = self._tuning.staticIceRadius,
				})
			end

			-- UITR: Each layout entry only gets a single widget, unlike the meatspace button layout.
			--       If the widget is extra-wide, add some dummy entries for the spacing calculations.
			if widget.layoutWide then
				 -- Layout treats each widget as 40px wide.
				 -- program.daemonKnown.bg is 234px wide, including borders.
				layout.widgets = { widget, LEFTMID_SPACER, MIDDLE_SPACER, RIGHTMID_SPACER, RIGHT_SPACER }
				widget._layoutLeft = true
			else
				layout.widgets = { widget }
				widget._layoutLeft = nil
			end

			-- UITR: We'll be drawing our own arm, thank you very much.
			if hasArm(widget) then
				widget.binder.arm:setVisible(false)
			end
		end
	end

	for i,oldID in ipairs(oldIDs) do
		local layout = self._layout[oldID]
		screen:removeWidget(layout.leaderWidget)
		self._layout[oldID] = nil
	end
end

function mainframe_layout:calculateLayout( screen, game, widgets )
	if self._dirty then
		-- UITR: Handle new item creation/destruction only when needed.
		self:_refreshWidgets(screen, game, widgets)
		self._dirty = false
	end

	-- Initial positions of layout-positioned elements.
	local layoutsByPosition = {}
	for _, layout in pairs( self._layout ) do
		local widget = layout.widgets[1]

		local wx, wy = game:worldToWnd( widget.worldx, widget.worldy, widget.layoutWorldz or widget.worldz )
		layout.startx, layout.starty = wx, wy
		layout.posx, layout.posy = wx, wy

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

	-- Positions of static barrier elements.
	for _,static in ipairs(self._statics) do
		static.posx, static.posy = game:worldToWnd( static.worldx, static.worldy, static.worldz )
	end

	-- Now, shift positions to reduce overlap.
	local iters = 0
	while iters < self._tuning.maxIters and self:hasOverlaps( self._layout, self._statics ) do
		self:doPass( self._layout, self._statics )
		iters = iters + 1
	end
end

function mainframe_layout:setPosition( widget )
	if not widget._layoutID then
		-- UITR: This is a non-targeting widget, such as the 'rebooting' floater. Let the HUD draw it directly.
		return false
	end

	local layout = self._layout[ widget._layoutID ]
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

function mainframe_layout:updateForce( fx, fy, dx, dy, radius, left, mid, right )
	local mag = self._tuning.repulseMagnitude
	if mag then
		local SCALE_DIST = radius * self._tuning.repulseScaleCap
		local MAX_DIST = radius + self._tuning.repulseMaxSep
		local d = math.sqrt( dx*dx + dy*dy )
		if d < 1 then
			return fx, fy
		elseif d > MAX_DIST then
			-- Far enough apart.
			return fx, fy
		else
			mag = mag * math.min( 1, (SCALE_DIST * SCALE_DIST) / (d*d)) -- inverse sqr mag.
			dx, dy = dx / d, dy / d
		end

		if left and dx > 0 then
			dx = 0
		elseif right and dx < 0 then
			dx = 0
		elseif mid then
			dx = dx * 3 / 4
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
				for j, widget in ipairs(ll.widgets) do
					local x1, y1, r1 = self:getCircle( w2, j )
					fx, fy = self:updateForce( fx, fy, x0 - x1, y0 - y1, r0 + r1, widget._layoutLeft, widget._layoutMid, widget._layoutRight )
				end
			end
		end
		for i, ll in pairs(statics) do
			local x1, y1, r1 = self:getStaticCircle( ll )
			fx, fy = self:updateForce( fx, fy, x0 - x1, y0 - y1, r0 + r1, ll._layoutLeft, ll._layoutMid, ll._layoutRight )
		end
	end

    return fx, fy
end

return mainframe_layout
