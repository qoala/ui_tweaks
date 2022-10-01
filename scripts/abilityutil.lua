local util = include("client_util")
local mui_tooltip = include("mui/mui_tooltip")
local mui_util = include("mui/mui_util")
local abilityutil = include("sim/abilities/abilityutil")

-- TODO: On abilities with createTooltip, need to hide that, and add onTooltip that creates one of our tooltips with (nil, generateTooltipReason(...), nil)

-- local function generateTooltipReason( tooltip, reason )
-- 	if reason then
-- 		return tooltip .. "\n<c:ff0000>" .. reason .. "</>"
-- 	else
-- 		return tooltip
-- 	end
-- end

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
