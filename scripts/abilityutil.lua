local cdefs = include( "client_defs" )
local util = include("client_util")
local mui_tooltip = include("mui/mui_tooltip")
local mui_util = include("mui/mui_util")
local array = include("modules/array")
local abilityutil = include("sim/abilities/abilityutil")
local simquery = include("sim/simquery")

-- ===

-- Extract a local variable from the given function's upvalues
local function extractUpvalue( fn, name )
	local i = 1
	while true do
		local n, v = debug.getupvalue(fn, i)
		assert(n, string.format( "Could not find upvalue: %s", name ) )
		if n == name then
			return v, i
		end
		i = i + 1
	end
end

-- Overwrite a class' base class to force method-override/-append propagation to subclasses.
-- Call from :init, obtaining the current class via getmetatable
local function overwriteInheritance(c, oldBaseClass, newBaseClass, sentinelKey, logName)
	if c and not c[sentinelKey] then
		logName = logName or tostring(c)
		simlog("LOG_UITRMETA", "%s init for ", logName, sentinelKey)
		c[sentinelKey] = true

		if c._base == oldBaseClass then
			c._base = newBaseClass
		end

		for i,v in pairs(newBaseClass) do
			if not type(i) == "string" or i == "_base" or i == "__index" or i == "is_a" or i == "init" or i == sentinelKey then
				-- skip core/meta fields
			elseif c[i] == oldBaseClass[i] and c[i] ~= newBaseClass[i] then
				if c[i] then
					simlog("LOG_UITRMETA", "%s replacing %s %s-%s", logName, tostring(i), tostring(c[i]), tostring(newBaseClass[i]))
				else
					simlog("LOG_UITRMETA", "%s adding %s", logName, tostring(i))
				end
				c[i] = newBaseClass[i]
			else
				simlog("LOG_UITRMETA", "%s keeping %s", logName, tostring(i))
			end
		end
	end
end

if not util.tooltip_section then
	util.tooltip_section = extractUpvalue(util.tooltip.addSection, "tooltip_section")
end

-- ===
-- Tooltip section that replicates the appearance of a vanilla abilityutil.hotkey_tooltip/mui_tooltip
-- ===

-- Vanilla tooltip uses a single memoized object. Doing the same here to minimize load.
-- This prevents adding multiple mui_tooltip_sections to a single tooltip, but that seems acceptable.
local DEFAULT_TOOLTIP = nil

local mui_tooltip_section = class() -- ducktypes like util.tooltip_section for being a tooltip's child but shares no inheritance
abilityutil.mui_tooltip_section = mui_tooltip_section

function mui_tooltip_section:init( tooltip, header, body, hotkey )
	self._tooltip = tooltip
	self._tooltipWidget = nil

	self._headerTxt = header
	self._bodyTxt = body
    self._hotkey = hotkey
end

function mui_tooltip_section:activate( screen )
	if DEFAULT_TOOLTIP == nil then
		DEFAULT_TOOLTIP = screen:createFromSkin("tooltip")
	end
	self._screen = screen
	self._tooltipWidget = DEFAULT_TOOLTIP
	self._screen:addWidget(self._tooltipWidget)
	self._tooltipWidget:updatePriority(mui_tooltip.TOOLTIP_PRIORITY)

	-- ===
	-- Most of the implementation from mui_tooltip for preparing the skin's elements
	-- ===

	local tooltipLabel = self._tooltipWidget.binder.label
	if self._headerTxt then
		tooltipLabel:setText( string.format( "<ttheader>%s</>\n%s", self._headerTxt, self._bodyTxt or "" ))
	else
		tooltipLabel:setText( self._bodyTxt )
	end

	local hotkeyLabel = self._tooltipWidget.binder.hotkey
	if self._hotkey then
        local binding = util.getKeyBinding( self._hotkey )
        if binding then
            local hotkeyName = mui_util.getBindingName( binding )
		    hotkeyLabel:setText( string.format( "%s: <tthotkey>[ %s ]</>", STRINGS.UI.HUD_HOTKEY, hotkeyName ))
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
	--tooltipBg:setPosition( 0,0 )

	local footer = self._tooltipWidget.binder.border
	if #hotkeyLabel:getText() > 0 then
		footer:setVisible(true)
		th = th + 2 * (ymax_hotkey - ymin_hotkey)
		footer:setSize( W * tw, H * (ymax_hotkey - ymin_hotkey)+ 8 )
		footer:setPosition(W * tw / 2, H * (-th + math.abs(ymax_hotkey - ymin_hotkey))  )
		hotkeyLabel:setPosition( nil, H * (-th + math.abs(ymax_hotkey - ymin_hotkey)) )
	else
		footer:setVisible(false)
	end

	self._w, self._h = tw, th
end

function mui_tooltip_section:deactivate( )
	self._screen:removeWidget(self._tooltipWidget)
	self._screen = nil
end

function mui_tooltip_section:getSize()
	return self._w, self._h
end

function mui_tooltip_section:setPosition( tx, ty )
	self._tooltipWidget:setPosition( tx, ty )
end

-- ===
-- Tooltip section that delays all its calls until activate.
-- Because util.tooltip_section expects its parent to have a screen at init time, but hotkey_tooltip doesn't have a screen until activate.
-- ===

local delayed_tooltip_section = class( util.tooltip_section )
abilityutil.delayed_tooltip_section = delayed_tooltip_section

function delayed_tooltip_section:init( tooltip, ... )
	-- Cannot call base init, because it tries to create the widget immediately.
	self._tooltip = tooltip
	self._widget = nil
	self._children = {}
	self._activateQueue = {}
end

function delayed_tooltip_section:activate( screen, ... )
	if not self._widget then
		self._widget = screen:createFromSkin( "tooltip_section" )
	end

	local queue = self._activateQueue
	self._activateQueue = nil -- Parent tooltip will have a screen.
	if queue then
		-- Apply all the delayed 'add' calls, in order, now that a screen is available.
		for _,entry in ipairs(queue) do
			entry.fn(self, unpack(entry.args))
		end
	end

	util.tooltip_section.activate(self, screen, ...)
end

function delayed_tooltip_section:deactivate( ... )
	util.tooltip_section.deactivate(self, ...)
	self._activateQueue = {}
end

function delayed_tooltip_section:addLine( ... )
	if self._activateQueue then
		table.insert(self._activateQueue, {fn=util.tooltip_section.addLine, args={...}})
	else
		util.tooltip_section.addLine(self, ...)
	end
end

function delayed_tooltip_section:addDesc( ... )
	if self._activateQueue then
		table.insert(self._activateQueue, {fn=util.tooltip_section.addDesc, args={...}})
	else
		util.tooltip_section.addDesc(self, ...)
	end
end

function delayed_tooltip_section:addFooter( ... )
	if self._activateQueue then
		table.insert(self._activateQueue, {fn=util.tooltip_section.addFooter, args={...}})
	else
		util.tooltip_section.addFooter(self, ...)
	end
end

function delayed_tooltip_section:addAbility( ... )
	if self._activateQueue then
		table.insert(self._activateQueue, {fn=util.tooltip_section.addAbility, args={...}})
	else
		util.tooltip_section.addAbility(self, ...)
	end
end

function delayed_tooltip_section:addWarning( ... )
	if self._activateQueue then
		table.insert(self._activateQueue, {fn=util.tooltip_section.addWarning, args={...}})
	else
		util.tooltip_section.addWarning(self, ...)
	end
end

-- ===
-- Customize tooltip_section's addWarning to apply effects whenever the overwatch warning string is used.
-- ===

-- Blink effect on the warning's border
local function warningBlinkFn( widget, baseColor, brightColor )
	local frame = 0
	local base = 1*cdefs.SECONDS
	local key1 = math.floor(cdefs.SECONDS / 6)
	local key2 = 2 * key1
	local key3 = 3 * key1
	while true do
		if frame == 0 or frame == key2 then
			widget.binder.bg:setColor(brightColor:unpack())
		elseif frame == key1 or frame == key3 then
			widget.binder.bg:setColor(baseColor:unpack())
		end

		coroutine.yield()
		frame = (frame + 1) % base
	end
end

local oldSectionAddWarning = util.tooltip_section.addWarning
function util.tooltip_section:addWarning(title, line, icon, color, ...)
	local isOverwatchWarning = false
	if title == STRINGS.UI.DOOR_TRACKED and line == STRINGS.UI.DOOR_TRACKED_TT then
		isOverwatchWarning = true
	end

	oldSectionAddWarning(self, title, line, icon, color, ...)

	if isOverwatchWarning then
		-- Reorder this warning section to appear first.
		array.removeElement(self._tooltip._sections, self)
		table.insert(self._tooltip._sections, 1, self)

		-- New warning is the last widget.
		local widget = self._children[#self._children]

		-- Blink the border and icon
		local oldActivate = widget.activate
		function widget:activate( screen, ... )
			if oldActivate then oldActivate(self, screen, ...) end
			widget:onUpdate(warningBlinkFn, color, util.color.WHITE)
		end
	end
	if color == cdefs.COLOR_WATCHED_BOLD then
		local widget = self._children[#self._children]

		-- Make the body text brighter, for legibility
		widget.binder.desc:setColor(util.color.WHITE:unpack()) -- This is apparently necessary for format codes to modify color.
		widget.binder.desc:setText( string.format( "<font1_16_r><c:FF0101>%s</c></>\n<c:FFF0F0>%s</c>", util.toupper(title), line ))
	end
end

local oldSectionActivate = util.tooltip_section.activate
function util.tooltip_section:activate( screen, ... )
	local W,H = screen:getResolution()
	local vanillaActivatedChildren = (self._w == nil or self._W ~= W or self._H ~= H)

	oldSectionActivate( self, screen, ... )

	if not vanillaActivatedChildren then
		-- Vanilla implementation skipped activating children.
		for _,child in ipairs(self._children) do
			if child.activate then
				child:activate( screen )
			end
		end
	end
end


-- ===
-- Sectioned tooltip for abilityutil.hotkey_tooltip
-- ===

-- Overwrite base abilityutil.hotkey_tooltip (derived from mui_tooltip) with a new class derived from util.tooltip, to support adding sections.
local hotkey_tooltip = class( util.tooltip )
local old_hotkey_tooltip = abilityutil.hotkey_tooltip
abilityutil.hotkey_tooltip = hotkey_tooltip

hotkey_tooltip._uitr_mergedTooltip = true

function hotkey_tooltip:init( ability, sim, abilityOwner, tooltip )
	-- Meta shenanigans: override the cached base class on any hotkey_tooltip subclasses.
	overwriteInheritance(getmetatable(self), old_hotkey_tooltip, hotkey_tooltip, "_uitr_mergedTooltip", ability.name)

	-- ===
	-- Initialize self
	-- ===

	util.tooltip.init(self, nil, nil) -- screen is not available, can only use delayed-impl sections.

	-- ===
	-- Prepare the vanilla content as the first section of this tooltip
	-- ===

	local enabled, reason = ability:canUseAbility( sim, abilityOwner )
	local section
	if reason then
		section = mui_tooltip_section( self, util.toupper( ability.name ), string.format( "%s\n<tthotkey><c:FF0000>%s</>", tooltip, reason ), ability.hotkey )
	else
		section = mui_tooltip_section( self, util.toupper( ability.name ), tooltip, ability.hotkey )
	end
	table.insert(self._sections, section)
end

function hotkey_tooltip:activate( screen, ... )
	self._screen = screen
	util.tooltip.activate(self, screen, ...)
end

function hotkey_tooltip:addSection()
	local section = delayed_tooltip_section(self)
	table.insert(self._sections, section)
	return section
end

-- ===
-- Wrapped onTooltip for abilities that injects our custom warnings (installed by simability.create)
-- ===

local function wrappedCreateToolTip( self, sim, abilityOwner, abilityUser, ... )
	-- Replicate how agent_panel calls createToolTip.
	local _, reason = abilityUser:canUseAbility( sim, self, abilityOwner, ...)
	local tooltip = self:_uitr_oldCreateToolTip( sim, abilityOwner, abilityUser, ... )
	if reason then
		return tooltip .. "\n<c:ff0000>" .. reason .. "</>"
	else
		return tooltip
	end
end

local function wrapTooltip( tooltip, hud )
	if type(tooltip) == "string" then
		local wrapped = util.tooltip(hud._screen)
		local section = mui_tooltip_section(wrapped, nil, tooltip, nil)
		table.insert(wrapped._sections, section)
		return wrapped
	end
	return tooltip
end

function abilityutil.wrappedOnTooltip( self, hud, sim, abilityOwner, abilityUser, ... )
	-- Call the appropriate underlying tooltip fn.
	local tooltip
	local args = {...}
	if not abilityUser then
		-- We've patched something other than a normal ability and have been called by a different hud element.
		return self._uitr_oldOnTooltip and self:_uitr_oldOnTooltip(hud, sim, abilityOwner, abilityUser, ...)
	elseif args[1] then
		-- agent_panel.updateButtonFromAbilityTarget provides additional target args and prefers onTooltip over createToolTip if both exist
		if self._uitr_oldOnTooltip then
			tooltip = self:_uitr_oldOnTooltip(hud, sim, abilityOwner, abilityUser, ...)
		elseif self._uitr_oldCreateToolTip then
			tooltip = wrappedCreateToolTip(self, sim, abilityOwner, abilityUser, ...)
		else
			return nil
		end
	else
		-- agent_panel.updateButtonFromAbility stops at abilityUser and prefers onCreateToolTip over onTooltip if both exist
		if self._uitr_oldCreateToolTip then
			tooltip = wrappedCreateToolTip(self, sim, abilityOwner, abilityUser, ...)
		elseif self._uitr_oldOnTooltip then
			tooltip = self:_uitr_oldOnTooltip(hud, sim, abilityOwner, abilityUser, ...)
		else
			return nil
		end
	end

	local uiTweaks = sim:getParams().difficultyOptions.uiTweaks
	if not uiTweaks or not tooltip then
		return tooltip
	end

	-- Wrap tooltips such that they support addSection.
	tooltip = wrapTooltip(tooltip, hud)
	if not tooltip.addSection then
		-- oldOnTooltip constructed a mui_tooltip through some other path.
		return tooltip
	end

	-- Overwatch warnings
	local triggersOverwatch = self.triggersOverwatch == true or (type(self.triggersOverwatch) == "function" and self:triggersOverwatch(sim, abilityOwner, abilityUser, ...))
	local dangerousOverwatch = triggersOverwatch and abilityUser and simquery.isUnitUnderOverwatch(abilityUser)
	if dangerousOverwatch then
		tooltip:addSection():addWarning(STRINGS.UI.DOOR_TRACKED, STRINGS.UI.DOOR_TRACKED_TT, "gui/hud3/hud3_tracking_icon_sm.png", cdefs.COLOR_WATCHED_BOLD)
	end

	return tooltip
end
