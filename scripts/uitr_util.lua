
local UITR_OPTIONS = {
	{
		id = "enabled",
		name = STRINGS.UITWEAKSR.OPTIONS.MOD_ENABLED,
		check = true,
		needsReload = true,
		maskFn = function(self, value)
			return { [true] = value }
		end
	},

	-- Additional interface detail.
	{
		sectionHeader = true,

		id = "preciseAp",
		name = STRINGS.UITWEAKSR.OPTIONS.PRECISE_AP,
		tip = STRINGS.UITWEAKSR.OPTIONS.PRECISE_AP_TIP,
		values={ false, 0.5 },
		value=0.5,
		strings={ STRINGS.UITWEAKSR.OPTIONS.VANILLA, STRINGS.UITWEAKSR.OPTIONS.PRECISE_AP_HALF },
	},
	{
		id = "preciseIcons",
		name = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS,
		tip = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS_TIP,
		check = true,
		needsReload = true,
	},
	{
		id = "tacticalLampView",
		name = STRINGS.UITWEAKSR.OPTIONS.TACTICAL_LAMP_VIEW,
		tip = STRINGS.UITWEAKSR.OPTIONS.TACTICAL_LAMP_VIEW_TIP,
		check = true,
		needsReload = true,
	},
	{
		id = "coloredTracks",
		name = STRINGS.UITWEAKSR.OPTIONS.COLORED_TRACKS,
		tip = STRINGS.UITWEAKSR.OPTIONS.COLORED_TRACKS_TIP,
		values = { false, 1 },
		value = 1,
		strings = { STRINGS.UITWEAKSR.OPTIONS.VANILLA, STRINGS.UITWEAKSR.OPTIONS.COLORED_TRACKS_A },
		needsReload = true,
	},
	{
		id = "cleanShift",
		name = STRINGS.UITWEAKSR.OPTIONS.CLEAN_SHIFT,
		tip = STRINGS.UITWEAKSR.OPTIONS.CLEAN_SHIFT_TIP,
		check = true,
	},
	{
		id = "mainframeLayout",
		name = STRINGS.UITWEAKSR.OPTIONS.MAINFRAME_LAYOUT,
		tip = STRINGS.UITWEAKSR.OPTIONS.MAINFRAME_LAYOUT_TIP,
		check = true,
	},

	-- TODO: Remove parameters
	{
		sectionHeader = true,

		id = "mainframeLayoutDebug",
		name = "  Layout Debug Visualization",
		check = true,
		value = false,
	},
	{
		id = "mainframeLayoutMagnitude",
		name = "  Repulse Magnitude",
		values={ 2, 3, 4, 5, 6, 7, 8, 9, 10 },
		value=5,
	},
	{
		id = "mainframeLayoutScaleLimit",
		name = "  Repulse Scaling Limit",
		values={ 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0 },
		value=0.4,
	},
	{
		id = "mainframeLayoutMaxSeparation",
		name = "  Max Repulse Separation",
		values={ 5, 7, 10, 12, 15, 17, 20, 25, 30, 35, 40, 45, 50, 55, 60 },
		value=20,
	},
	{
		id = "mainframeLayoutOverlapLimit",
		name = "  Horizontal overlap forcing",
		values={ false, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
		value=2,
	},
	{
		id = "mainframeLayoutItemRadius",
		name = "  Boundary radius of firewall widgets",
		values={ 9,11,13,15,17,19,21,23,25, 31, 35, 41, 45, 51,  },
		value = 21,
	},
	{
		id = "mainframeLayoutStaticIceRadius",
		name = "  Static boundary for mainframe devices",
		values={ false, 1,3,5,7,9,11,13,15,17,19,21,23,25 },
		value = false,
	},
	{
		id = "mainframeLayoutStaticActivateRadius",
		name = "  Static boundary for activatables",
		values={ false, 9,11,13,15,17,19,21,23,25, 31, 35, 41, 45, 51,  },
		value = 31,
	},
	{
		id = "mainframeLayoutStaticTargetRadius",
		name = "  Static boundary for ability targets",
		values={ false, 9,11,13,15,17,19,21,23,25 },
		value = 21
	},

	-- QoL interface.
	{
		sectionHeader = true,

		id = "emptyPockets",
		name = STRINGS.UITWEAKSR.OPTIONS.EMPTY_POCKETS,
		tip = STRINGS.UITWEAKSR.OPTIONS.EMPTY_POCKETS_TIP,
		check = true,
	},
	{
		id = "invDragDrop",
		name = STRINGS.UITWEAKSR.OPTIONS.INV_DRAGDROP,
		tip = STRINGS.UITWEAKSR.OPTIONS.INV_DRAGDROP_TIP,
		check = true,
	},
	{
		id = "doorsWhileDragging",
		name = STRINGS.UITWEAKSR.OPTIONS.DOORS_WHILE_DRAGGING,
		tip = STRINGS.UITWEAKSR.OPTIONS.DOORS_WHILE_DRAGGING_TIP,
		check = true,
		needsCampaign = true,
	},
	{
		id = "stepCarefully",
		name = STRINGS.UITWEAKSR.OPTIONS.STEP_CAREFULLY,
		tip = STRINGS.UITWEAKSR.OPTIONS.STEP_CAREFULLY_TIP,
		check = true,
	},

	-- Overwatch warnings.
	{
		sectionHeader = true,

		id = "overwatchMovement",
		name = STRINGS.UITWEAKSR.OPTIONS.OVERWATCH_MOVEMENT_WARNINGS,
		tip = STRINGS.UITWEAKSR.OPTIONS.OVERWATCH_MOVEMENT_WARNINGS_TIP,
		check = true,
	},
	{
		id = "overwatchAbilities",
		name = STRINGS.UITWEAKSR.OPTIONS.OVERWATCH_ABILITY_WARNINGS,
		tip = STRINGS.UITWEAKSR.OPTIONS.OVERWATCH_ABILITY_WARNINGS_TIP,
		check = true,
	},

	-- Selection highlight.
	{
		sectionHeader = true,

		id = "selectionFilterAgentColor",
		name = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_AGENT,
		tip = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_AGENT_TIP,
		values = { false, "CYAN_SHADE", "BLUE_SHADE", "GREEN_SHADE", "PURPLE_SHADE", "CYAN_HILITE", "BLUE_HILITE", "GREEN_HILITE", "PURPLE_HILITE", },
		value = "BLUE_SHADE",
		strings = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_AGENT_COLORS,
		maskFn = function(self, value)
			return { selectionFilterAgentTacticalOnly = (value ~= false) }
		end
	},
	{
		id = "selectionFilterAgentTacticalOnly",
		name = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_AGENT_TACTICAL,
		tip = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_AGENT_TACTICAL_TIP,
		check = true,
	},
	{
		id = "selectionFilterTileColor",
		name = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_TILE,
		tip = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_TILE_TIP,
		values={ false, "WHITE_SHADE", "CYAN_SHADE", "BLUE_SHADE", },
		value="CYAN_SHADE",
		strings= STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_TILE_COLORS,
	},
}

for _,setting in ipairs( UITR_OPTIONS ) do
	setting.canRefresh = not setting.needsReload and not setting.needsCampaign

	if setting.values then
		if not setting.strings then
			setting.strings = {}
			for i,v in ipairs(setting.values) do
				setting.strings[i] = tostring(v)
			end
		end
		if setting.value == nil then
			setting.value = setting.values[1]
		end
	end
end

-- ===

-- Mutable container for temporary options
local _M = {
	tempOptions = nil,
}

local function checkEnabled( )
	if _M.tempOptions then
		return _M.tempOptions["enabled"]
	end
	local settingsFile = savefiles.getSettings( "settings" )
	local uitr = settingsFile.data.uitr
	return uitr and uitr["enabled"]
end

local function checkOption( optionId )
	if _M.tempOptions then
		return _M.tempOptions["enabled"] and _M.tempOptions[optionId]
	end
	local settingsFile = savefiles.getSettings( "settings" )
	local uitr = settingsFile.data.uitr
	return uitr and uitr["enabled"] and uitr[optionId]
end

local function getOptions( )
	if _M.tempOptions then
		return _M.tempOptions
	end
	local settingsFile = savefiles.getSettings( "settings" )
	local uitr = settingsFile.data.uitr
	if uitr and uitr["enabled"] then
		return uitr
	else
		return {}
	end
end

local function _setTempOptions( tempOptions )
	_M.tempOptions = tempOptions
end

local function initOptions( )
	local array = include( "modules/array" )
	local settingsFile = savefiles.getSettings( "settings" )
	if not settingsFile.data.uitr then settingsFile.data.uitr = {} end

	local uitr = settingsFile.data.uitr
	for _,optionDef in ipairs( UITR_OPTIONS ) do
		if uitr[optionDef.id] == nil or (optionDef.values and not array.find(optionDef.values, uitr[optionDef.id])) then
			if optionDef.value ~= nil then
				uitr[optionDef.id] = optionDef.value
			elseif optionDef.check then
				uitr[optionDef.id] = true
			end
		end
	end
end

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
-- oldFnMapping is a table of function names to the old function implementations. If the given class has the old function, it's replaced with the current superclass function.
-- If the given class already overrode it from the old function, it's assumed to either internally call the superclass method or have a good reason not to.
-- Call from :init, obtaining the current class via getmetatable
local function propagateSuperclass(c, superClass, oldFnMapping, sentinelKey, logName)
	if c and not c[sentinelKey] then
		logName = logName or tostring(c)
		simlog("LOG_UITRMETA", "%s init for %s", logName, sentinelKey)
		c[sentinelKey] = true

		for fnName, oldFn in pairs(oldFnMapping) do
			if (c[fnName] == oldFn) then
				simlog("LOG_UITRMETA", "%s replacing %s", logName, fnName)
				c[fnName] = superClass[fnName]
			end
		end
	end
end

-- Overwrite a class' base class to force method-override/-append propagation to subclasses.
-- (More invasive than propagateSuperclassMethods)
-- For each symbol in oldBaseClass, if it is unchanged in the given class and different in the new base class, it's replaced with the one from then new base class.
-- If the given class already overrode it from the old base class, it's assumed to either internally call the superclass method or have a good reason not to.
-- Call from :init, obtaining the current class via getmetatable
local function overwriteInheritance(c, oldBaseClass, newBaseClass, sentinelKey, logName)
	if c and not c[sentinelKey] then
		logName = logName or tostring(c)
		simlog("LOG_UITRMETA", "%s init for %s", logName, sentinelKey)
		c[sentinelKey] = true

		do
			local m = c
			while m do
				if m._base == oldBaseClass then
					m._base = newBaseClass
					break
				end
				m = m._base
			end
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


-- ===

return {
	UITR_OPTIONS = UITR_OPTIONS,
	checkEnabled = checkEnabled,
	checkOption = checkOption,
	getOptions = getOptions,
	_setTempOptions = _setTempOptions,
	initOptions = initOptions,

	extractUpvalue = extractUpvalue,
	propagateSuperclass = propagateSuperclass,
	overwriteInheritance = overwriteInheritance,
}
