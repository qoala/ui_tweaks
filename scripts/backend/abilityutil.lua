local cdefs = include( "client_defs" )
local util = include("client_util")
local mui_util = include("mui/mui_util")
local mui_tooltip = include("mui/mui_tooltip")
local mui_util = include("mui/mui_util")
local array = include("modules/array")
local abilityutil = include("sim/abilities/abilityutil")
local simquery = include("sim/simquery")

local uitr_util = include( SCRIPT_PATHS.qed_uitr .. "/uitr_util" )

-- ===
-- Common triggersOverwatch implementations
-- ===

-- An ability that only triggers overwatch on the abilityOwner, so don't trigger if the ability is on a held item (example: prototype chip)
function abilityutil.triggersOverwatchOnOwnerOnly(self, sim, abilityOwner, abilityUser)
	return abilityOwner == abilityUser
end

local function playerKnowsUnit(player, unit)
	if array.find(player:getSeenUnits(), unit) then
		return true
	end
	local ghost = player._ghost_units[unit:getID()]
	if ghost then
		local gx,gy = ghost:getLocation()
		local x,y = unit:getLocation()
		return x==gx and y==gy
	end
end

-- An ability that triggers overwatch after making the user invisible. Unlike most triggersOverwatch checks, checks for detect-cloak on observers, to limit false positives.
function abilityutil.triggersOverwatchAfterCloaking(self, sim, abilityOwner)
	local userUnit
	if simquery.isAgent(abilityOwner) then
		userUnit = abilityOwner
	else
		userUnit = abilityOwner:getUnitOwner()
	end

	if not userUnit then return end

	local player = userUnit:getPlayerOwner()

	-- Technically triggers overwatch broadly, but it only matters if one of them can see invisible.
	-- Check for that to reduce false positives.
	local seers = sim:generateSeers( userUnit )
	for i,seer in ipairs(seers) do
		local seerUnit = sim:getUnit(seer)
		if (seerUnit and seerUnit:getTraits().detect_cloak
			and simquery.couldUnitSee(sim, seerUnit, userUnit)
			and simquery.isEnemyAgent(player, seerUnit)
			and playerKnowsUnit(player, seerUnit)
		) then
			return true
		end
	end
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

mui_tooltip_section.__concat = function( a, b )
	if type(b) == "string" and a.is_a and a:is_a(mui_tooltip_section) then
		if util.getControllerBindingImage and b == STRINGS.UI.HUD_CANCEL_TT then
			-- Track that we're displaying a 'Right Click' binding.
			a._qedctrl_pseudoBindingTxt = STRINGS.UI.HUD_RIGHT_CLICK
			-- Strip the previously-added newline and store the text separately.
			a._bodyTxt = string.sub(a._bodyTxt, 1, -2)
			a._pseudoHotkeyTxt = b
		else
			a._bodyTxt = (a._bodyTxt or "") .. b
		end
		return a
	elseif type(a) == "string" and b.is_a and b:is_a(mui_tooltip_section) then
		b._bodyTxt = a .. (b._bodyTxt or "")
		return b
	else
		assert(nil, "Invalid attempt to concat mui_tooltip_section between '"..type(a).."' and '"..type(b).."'\n"..debug.traceback())
	end
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
	local hasHotkey = false
	local hasPseudoHotkey = false
	local controllerHotkeyImg = self._tooltipWidget.binder.controllerHotkey
	local hasControllerHotkey = false
	if self._pseudoHotkeyTxt then
		hotkeyLabel:setText( self._pseudoHotkeyTxt )
		hasPseudoHotkey = true

		local ctrlBinding = (self._qedctrl_pseudoBindingTxt and util.getControllerBindingImage
				and util.getControllerBindingImage(self._qedctrl_pseudoBindingTxt))
		if ctrlBinding and not controllerHotkeyImg.isnull then
			controllerHotkeyImg:setImage(ctrlBinding)
			hasControllerHotkey = true
		end
	elseif self._hotkey then
        local binding = util.getKeyBinding( self._hotkey )
        if binding then
            local hotkeyName = mui_util.getBindingName( binding )
		    hotkeyLabel:setText( string.format( "%s: <tthotkey>[ %s ]</>", STRINGS.UI.HUD_HOTKEY, hotkeyName ))
			hasHotkey = true

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
	--tooltipBg:setPosition( 0,0 )

	local footer = self._tooltipWidget.binder.border
	if hasHotkey or hasPseudoHotkey then
		local footerH = ymax_hotkey - ymin_hotkey
		local footerY
		if hasControllerHotkey then
			footerH = math.max(footerH, 25/H * (footerH >= 0 and 1 or -1))
			controllerHotkeyImg:setVisible(true)
		elseif not controllerHotkeyImg.isnull then
			controllerHotkeyImg:setVisible(false)
		end

		if hasHotkey then
			th = th + 2 * footerH
			footerY = H * (-th + math.abs(footerH))

			footer:setVisible(true)
			footer:setSize( W * tw, H * footerH + 8 )
			footer:setPosition(W * tw / 2, footerY)
		else -- hasPseudoHotkey
			th = th + footerH + 2 * 4/H
			footerY = H * (-th + math.abs(footerH) / 2) + 4

			footer:setVisible(false)
			-- Resize the main background to cover both lines of text.
			tooltipBg:setSize( W * tw, H * th )
			tooltipBg:setPosition( (W * tw) / 2, H * -th / 2 )
		end
		hotkeyLabel:setPosition(nil, footerY)
		if hasControllerHotkey then
			controllerHotkeyImg:setPosition(W * tw - 12 - 4, footerY)
		end
	else
		footer:setVisible(false)
		if not controllerHotkeyImg.isnull then
			controllerHotkeyImg:setVisible(false)
		end
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
-- Tooltip container for delayed tooltip sections
-- Also supports a custom primary section. Concatenation will be proxied to the primary section.
-- ===

local delayed_tooltip = class( util.tooltip )
abilityutil.delayed_tooltip = delayed_tooltip

function delayed_tooltip:init( ... )
	util.tooltip.init(self, ...)
	self._primary_section = nil
end

delayed_tooltip.__concat = function( a, b )
	if type(b) == "string" and a.is_a and a:is_a(delayed_tooltip) and a._primary_section and a._primary_section.__concat then
		a._primary_section = a._primary_section .. b
		return a
	elseif type(a) == "string" and b.is_a and b:is_a(delayed_tooltip) and b._primary_section and b._primary_section.__concat then
		b._primary_section = a .. b._primary_section
		return b
	else
		assert(nil, "Invalid attempt to concat delayed_tooltip between '"..type(a).."' and '"..type(b).."'\n"..debug.traceback())
	end
end

function delayed_tooltip:activate( screen, ... )
	self._screen = screen
	util.tooltip.activate(self, screen, ...)
end
function delayed_tooltip:deactivate( ... )
	util.tooltip.deactivate( self, ... )
end

function delayed_tooltip:addSection()
	local section = delayed_tooltip_section(self)
	table.insert(self._sections, section)
	return section
end

function delayed_tooltip:addPrimarySection( section )
	table.insert(self._sections, section)
	self._primary_section = section
end

-- ===
-- Sectioned tooltip for abilityutil.hotkey_tooltip
-- ===

-- Overwrite base abilityutil.hotkey_tooltip (derived from mui_tooltip) with a new class derived from util.tooltip, to support adding sections.
local hotkey_tooltip = class( delayed_tooltip )
local old_hotkey_tooltip = abilityutil.hotkey_tooltip
abilityutil.hotkey_tooltip = hotkey_tooltip

hotkey_tooltip._uitrmeta_hotkeyTooltipBase = true

function hotkey_tooltip:init( ability, sim, abilityOwner, tooltip )
	-- Meta shenanigans: override the cached base class on any hotkey_tooltip subclasses.
	uitr_util.overwriteInheritance(getmetatable(self), old_hotkey_tooltip, hotkey_tooltip, "_uitrmeta_hotkeyTooltipBase", ability.name)

	-- ===
	-- Initialize self
	-- ===

	delayed_tooltip.init(self, nil, nil) -- screen is not available, can only use delayed-impl sections.

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
	self:addPrimarySection(section)
end

-- ===
-- Wrapped onTooltip and acquireTargets for abilities that injects our custom tooltip warnings (installed by simability.create)
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
		local wrapped = delayed_tooltip(hud._screen)
		wrapped:addPrimarySection(mui_tooltip_section(wrapped, nil, tooltip, nil))
		return wrapped
	end
	return tooltip
end

function abilityutil.uitr_wrappedOnTooltip( self, hud, sim, abilityOwner, abilityUser, ... )
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

	-- Wrap if either overwatchAbilities is enabled or Controller Bindings is present.
	if not tooltip or (not uitr_util.checkOption("overwatchAbilities") and not util.getControllerBindingImage) then
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

function wrappedTargetingGenerateTooltip( self, x, y, ... )
	local result = self:_uitr_oldGenerateTooltip( x, y, ... )
	if not type(result) == "string" then
		return result
	end
	local tooltip = delayed_tooltip()
	tooltip:addPrimarySection(mui_tooltip_section(tooltip, nil, result, nil))

	if self._dangerousOverwatch then
		tooltip:addSection():addWarning(STRINGS.UI.DOOR_TRACKED, STRINGS.UI.DOOR_TRACKED_TT, "gui/hud3/hud3_tracking_icon_sm.png", cdefs.COLOR_WATCHED_BOLD)
	end

	return tooltip
end

function abilityutil.uitr_wrappedAcquireTargets( self, targets, game, sim, abilityOwner, abilityUser, ... )
	local target = self:_uitr_oldAcquireTargets(targets, game, sim, abilityOwner, abilityUser, ... )


	if not target or not target.is_a or not target:is_a(targets.throwTarget) then
		return target
	end

	local dangerousOverwatch = false
	if uitr_util.checkOption("overwatchAbilities") then
		local triggersOverwatch = self.triggersOverwatch == true or (type(self.triggersOverwatch) == "function" and self:triggersOverwatch(sim, abilityOwner, abilityUser, ...))
		dangerousOverwatch = triggersOverwatch and abilityUser and simquery.isUnitUnderOverwatch(abilityUser)
	end
	-- TODO: This only wraps targeters generated by abilities. Controller Bindings wants this wrapper on non-ability targeter tooltips as well.
	if dangerousOverwatch or util.getControllerBindingImage then -- Wrap is also needed for Controller Bindings.
		target._dangerousOverwatch = dangerousOverwatch
		target._uitr_oldGenerateTooltip = target.generateTooltip
		target.generateTooltip = wrappedTargetingGenerateTooltip
	end
	return target
end
