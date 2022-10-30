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
	-- Max iterations to figure out a layout placement. (button_layout: 10)
	maxIters = 10,
	debugViz = false,

	-- Magnitude at which buttons push away from each other/static regions (button_layout: 5)
	repulseMagnitude = 5,
	repulseStaticMagnitude = 2,
	-- Magnitude starts falling off with inverse-squared distance past this fraction of the radii. (button_layout: 40 ~ 1.0)
	repulseScaleCap = 0.4,
	repulseStaticScaleCap = 0.6,
	-- Repulsion is applied up to this amount of separation + bounding radii.
	repulseMaxSep = 20,
	-- Limit for additional force on horizontally-overlapping wide regions.
	repulseOverlapLimit = 2,

	-- Overlap radius of layout items.
	itemRadius = 21,  -- (button_layout: 42)
	itemStateRadius = {
		["daemonKnown"] = 35,
		["daemonUnknown"] = 35,
	},
	-- Distance between horizontal centers of a wide rounded-rectangle bounding box.
	itemStateWidth = {
		-- Approx. difference in width between daemonKnown(234x60px) and daemonUnknown(61x61px)
		["daemonKnown"] = 170,
	},

	-- Overlap radius of the static bubble at the target circle for a layout item.
	staticIceRadius = false,
	-- Overlap radius of the static bubble around fixed widgets, by skin name.
	staticRadius = {
		["Activate"] = 31,
		["Target"] = 21,
	},
	-- Activate's label is scaled, but at 1920x1080 is approx. 384x32px.
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
		self._tuning.debugViz = uitrSettings.mainframeLayoutDebug

		self._tuning.repulseMagnitude = uitrSettings.mainframeLayoutMagnitude
		self._tuning.repulseStaticMagnitude = uitrSettings.mainframeLayoutStaticMagnitude
		self._tuning.repulseScaleCap = uitrSettings.mainframeLayoutScaleLimit
		self._tuning.repulseStaticScaleCap = uitrSettings.mainframeLayoutStaticScaleLimit
		self._tuning.repulseMaxSep = uitrSettings.mainframeLayoutMaxSeparation
		self._tuning.repulseOverlapLimit = uitrSettings.mainframeLayoutOverlapLimit

		self._tuning.staticIceRadius = uitrSettings.mainframeLayoutStaticIceRadius
		self._tuning.staticRadius["Activate"] = uitrSettings.mainframeLayoutStaticActivateRadius
		self._tuning.staticRadius["Target"] = uitrSettings.mainframeLayoutStaticTargetRadius

		self._lastSettingsID = uitrSettings._tempID
		self._dirty = true
	end
end

function mainframe_layout:dirtyLayout()
	self._dirty = true
end

function mainframe_layout:_destroyLayoutWidget( screen, l )
	screen:removeWidget( l.leaderWidget )
	if l.debugRings then
		for _, ring in ipairs( l.debugRings ) do
			screen:removeWidget( ring )
		end
	end
end

function mainframe_layout:_destroyAllStatics( screen )
	if self._debugViz then
		for _, l in ipairs( self._statics ) do
			if l.debugRings then
				for _, ring in ipairs( l.debugRings ) do
					screen:removeWidget( ring )
				end
			end
		end
	end
end

function mainframe_layout:destroy( screen )
	for _, l in pairs( self._layout ) do
		self:_destroyLayoutWidget( screen, l )
	end
	self:_destroyAllStatics( screen )

	self._layout = nil
end

local function hasArm( widget )
	if widget.getName and widget:getName() == "BreakIce" then
		return widget.binder and widget.binder.arm and not widget.binder.arm.isnull
	end
end

-- Restore modified widgets if we're destroyed by a settings change.
function mainframe_layout.restoreWidgets( widgets )
	for _, widget in ipairs( widgets ) do
		if hasArm(widget) then
			widget.binder.arm:setVisible(true)
		end
	end
end

function mainframe_layout:_refreshDirtyWidgets( screen, game, widgets )
	-- UITR: Populate the list of statics from static widgets each time we calculate.
	self:_destroyAllStatics( screen )
	self._statics = {}
	self._debugViz = self._tuning.debugViz

	-- Mark and Sweep
	-- Unlike meatspace buttons, mainframe widgets are retained across refreshes.
	-- So this layout is also retained and needs to cleanup layout elements for any widgets that disappeared.
	local oldIDs = util.tkeys(self._layout)

	for i, widget in ipairs( widgets ) do
        assert( widget.worldx )

		local layoutID
		if widget.ownerID and hasArm(widget) then
			-- Use the ownerID (target unit ID) as the layout ID.
			-- Only perform layout on the widget if the widget has an ownerID and "arm" childWidget.
			layoutID = widget.ownerID
			widget._layoutID = layoutID
		else
			-- UITR: other widgets should be drawn directly on their coordinates.
			widget._layoutID = nil

			if widget.getName then
				local radius = self._tuning.staticRadius[widget:getName()]
				if radius and radius > 0 then
					-- UITR: Insert into the static forcing coordinates list to keep clear around this button.
					table.insert(self._statics, {
						worldx = widget.worldx,
						worldy = widget.worldy,
						worldz = widget.worldz,
						radius = radius,
					})

					if self._debugViz then
						local l = self._statics[#self._statics]
						l.debugRings = {
							screen:createFromSkin( "MainframeLayoutDebug" ),
						}
						screen:addWidget( l.debugRings[1] )
						l.debugRings[1]:setScale( radius, radius )
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

				layout = {
					widget = widget,
					leaderWidget = leaderWidget
				}
				self._layout[ layoutID ] = layout
			else
				-- Mark layout as in use.
				array.removeElement(oldIDs, layoutID)

				layout.widget = widget
			end

			-- UITR: Keep a small area clear around the target circle for this item.
			if self._tuning.staticIceRadius and self._tuning.staticIceRadius > 0 then
				table.insert(self._statics, {
					worldx = widget.worldx,
					worldy = widget.worldy,
					worldz = widget.layoutWorldz or widget.worldz,
					radius = self._tuning.staticIceRadius,
				})
			end

			-- UITR: Select radius based on widget state.
			layout.radius = self._tuning.itemStateRadius[widget.layoutState] or self._tuning.itemRadius
			layout.width = self._tuning.itemStateWidth[widget.layoutState]

			-- UITR: We'll be drawing our own arm, thank you very much.
			if hasArm(widget) then
				widget.binder.arm:setVisible(false)
			end

			if self._debugViz and not layout.debugRings then
				layout.debugRings = {
					screen:createFromSkin( "MainframeLayoutDebug" ),
					screen:createFromSkin( "MainframeLayoutDebug" ),
					screen:createFromSkin( "MainframeLayoutDebug" )
				}
				screen:addWidget( layout.debugRings[1] )
				screen:addWidget( layout.debugRings[2] )
				screen:addWidget( layout.debugRings[3] )
			elseif not self._debugViz and layout.debugRings then
				for _, ring in ipairs( layout.debugRings ) do
					screen:removeWidget( ring )
				end
				layout.debugRings = nil
			end
			if layout.debugRings then
				layout.debugRings[1].binder.ring:setScale( layout.radius, layout.radius )
				layout.debugRings[2].binder.ring:setScale( layout.radius, layout.radius )
				layout.debugRings[3].binder.ring:setScale( layout.radius, layout.radius )
			end
		end
	end

	for i,oldID in ipairs(oldIDs) do
		self:_destroyLayoutWidget( screen, self._layout[oldID] )
		self._layout[oldID] = nil
	end
end

function mainframe_layout:calculateLayout( screen, game, widgets )
	if self._dirty then
		-- UITR: Handle new item creation/destruction only when needed.
		self:_refreshDirtyWidgets(screen, game, widgets)
		self._dirty = false
	end

	-- Initial positions of layout-positioned elements.
	local layoutsByPosition = {}
	for _, layout in pairs( self._layout ) do
		local widget = layout.widget

		local wx, wy = game:worldToWnd( widget.worldx, widget.worldy, widget.layoutWorldz or widget.worldz )
		layout.startx, layout.starty = wx, wy
		layout.posxMin, layout.posy = wx, wy

		-- UITR: Instead of radiating the offset away from a center point on the selected agent,
		--       Use a fixed offset as the base offset.
		local ox, oy = -18, -59
		layout.posxMin, layout.posy = layout.posxMin + ox, layout.posy + oy

		if layout.width then
			-- Above is the left-most center, where the number is centered.
			-- Calculate true center of the box and right-most center.
			layout.posxMid, layout.posxMax = layout.posxMin + layout.width / 2, layout.posxMin + layout.width
		else
			layout.posxMid, layout.posxMax = layout.posxMin, layout.posxMin
		end

		-- UITR: Track layouts that start on the exact same coordinate.
		local positionKey = tostring(layout.posxMid) .. "|" .. tostring(layout.posy)
		if layoutsByPosition[positionKey] then
			table.insert( layoutsByPosition[positionKey], layout )
		else
			layoutsByPosition[positionKey] = { layout }
		end
	end
	-- UITR: Vary identical positions so that they are able to separate in the later calculations.
	--       Unlike base layout, only do this when there's an exact match, so that otherwise colinear items can remain colinear.
	for _,layouts in pairs(layoutsByPosition) do
		if #layouts > 1 then
			for i, l in ipairs(layouts) do
				local dx, dy = 8 * math.cos( 2*math.pi * (i / #layouts) ), 8 * math.sin( 2*math.pi * (i / #layouts ))
				l.posxMin, l.posy = l.posxMin + dx, l.posy + dy
				l.posxMid, l.posxMax = l.posxMid + dx, l.posxMax + dx
			end
		end
	end

	-- Positions of static barrier elements.
	for _,static in ipairs(self._statics) do
		static.posxMin, static.posy = game:worldToWnd( static.worldx, static.worldy, static.worldz )
		static.posxMid, static.posxMax = static.posxMin, static.posxMin

		if static.debugRings then
			local x, y = screen:wndToUI( static.posxMin, static.posy )
			static.debugRings[1]:setPosition( x, y )
		end
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
	local x, y = widget:getScreen():wndToUI( layout.posxMin, layout.posy )
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
	local wndDist = mathutil.dist2d( layout.startx, layout.starty, layout.posxMin, layout.posy - (36/2 - 4) )
	local t0 = 8 / wndDist -- target circle is 16x16
	layout.leaderWidget.binder.line:setTarget( t0, x1, y1 )

	if layout.debugRings then
		layout.debugRings[1]:setPosition( x, y )
		if layout.width then
			local xMid, yMid = widget:getScreen():wndToUI( layout.posxMid, layout.posy )
			local xMax, yMax = widget:getScreen():wndToUI( layout.posxMax, layout.posy )
			layout.debugRings[2]:setPosition( xMid, yMid )
			layout.debugRings[3]:setPosition( xMax, yMax )
			layout.debugRings[2]:setVisible( true )
			layout.debugRings[3]:setVisible( true )
		else
			layout.debugRings[2]:setVisible( false )
			layout.debugRings[3]:setVisible( false )
		end
	end

	return true
end

-- ===
-- Calculation tweaks
-- ===

-- Nearest separation between two horizontal lines defined by rounded-rectangle centers
function mainframe_layout:_getSeparationDist( l0, l1 )
	if l0.posxMin > l1.posxMax then
		-- l0 fully right of l1: Compare endpoint centers.
		return mathutil.dist2d( l0.posxMin, l0.posy, l1.posxMax, l1.posy )
	elseif l1.posxMin > l0.posxMax then
		-- l1 fully right of l0: Compare endpoint centers.
		return mathutil.dist2d( l0.posxMax, l0.posy, l1.posxMin, l1.posy )
	else
		-- Overlapping: Compare y-only.
		return math.abs(l0.posy - l1.posy)
	end
end

-- Nearest separation vector between two horizontal lines defined by rounded-rectangle centers
function mainframe_layout:_getSeparationVector( l0, l1 )
	local dxForce
	if (l0.width or l1.width) and self._tuning.repulseOverlapLimit then
		-- Additional horizontal forcing to force the true centers away from each other.
		-- Up to diameter, the force is limited to +/- repulsion magnitude.
		-- Cap at [-limit, limit]
		local limit = self._tuning.repulseOverlapLimit
		local diameter = l0.radius + l1.radius
		dxForce = (l1.posxMid - l0.posxMid) / diameter
		dxForce = math.max( -limit, math.min( limit, dxForce ) )
	end

	if l0.posxMin > l1.posxMax then
		-- l0 fully right of l1: Compare endpoint centers.
		return l1.posxMax - l0.posxMin, l1.posy - l0.posy, dxForce
	elseif l1.posxMin > l0.posxMax then
		-- l1 fully right of l0: Compare endpoint centers.
		return l1.posxMin - l0.posxMax, l1.posy - l0.posy, dxForce
	else
		-- Horizontal overlap: Compare y-only.
		return 0, l1.posy - l0.posy, dxForce
	end
end

function mainframe_layout:hasOverlaps( layouts, statics )
	for id0, l0 in pairs( layouts ) do
		for id1, l1 in pairs(layouts) do
			if id0 ~= id1 and self:_getSeparationDist( l0, l1 ) <= l0.radius + l1.radius then
				return true
			end
		end
		for _, l1 in ipairs(statics) do
			if self:_getSeparationDist( l0, l1 ) <= l0.radius + l1.radius then
				return true
			end
		end
	end

	return false
end

function mainframe_layout:updateForce( fx, fy, mag, scaleCap, dx, dy, radius, dxForce, id0, id1 )
	local MAX_DIST = radius + self._tuning.repulseMaxSep
	local SCALE_DIST = scaleCap * radius

	local d = math.sqrt( dx*dx + dy*dy )
	if d > MAX_DIST then
		-- Far enough apart.
		return fx, fy
	elseif d < 1 then
		-- Too close, but attempting to separate based on dx,dy leads to jumping.
		if id0 == id1 then
			dx, dy = 0, 0
		elseif id1 > id0 then
			dx, dy = math.cos( 2*math.pi * (id1-id0 / 100) ), math.sin( 2*math.pi * (id1-id0 / 100 ))
		else
			dx, dy = -math.cos( 2*math.pi * (id0-id1 / 100) ), -math.sin( 2*math.pi * (id0-id1 / 100 ))
		end
	else
		-- Inverse-square decrease to the magnitude when beyond SCALE_DIST
		mag = mag * math.min( 1, (SCALE_DIST * SCALE_DIST) / (d*d) )
		-- Unit vector
		dx, dy = dx / d, dy / d
	end

	if dxForce then
		dx = dx/2 + dxForce
	end

	fx, fy = fx + mag * dx, fy + mag * dy
	return fx, fy
end

function mainframe_layout:calculateForce( id0, l0, layouts, statics )
	local fx, fy = 0, 0
	local mag = self._tuning.repulseMagnitude
	local scaleCap = self._tuning.repulseScaleCap
	for id1, l1 in pairs(layouts) do
		if id0 ~= id1 then
			local dx, dy, dxForce = self:_getSeparationVector( l1, l0 )
			fx, fy = self:updateForce( fx, fy, mag, scaleCap, dx, dy, l0.radius + l1.radius, dxForce, id0,id1 )
		end
	end
	mag = self._tuning.repulseStaticMagnitude
	scaleCap = self._tuning.repulseStaticScaleCap
	for _, l1 in ipairs(statics) do
		local dx, dy, dxForce = self:_getSeparationVector( l1, l0 )
		fx, fy = self:updateForce( fx, fy, mag, scaleCap, dx, dy, l0.radius + l1.radius, dxForce )
	end

    return fx, fy
end

function mainframe_layout:doPass( layouts, statics )
	for layoutID, l in pairs(layouts) do
		-- Get the force on this widget.
		l.fx, l.fy = self:calculateForce( layoutID, l, layouts, statics )
	end

	-- Apply forces
	for _, l in pairs(layouts) do
		l.posxMin, l.posy = l.posxMin + l.fx, l.posy + l.fy
		l.posxMid, l.posxMax = l.posxMid + l.fx, l.posxMax + l.fx
	end
end

return mainframe_layout
