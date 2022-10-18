
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
		spacer = true,
	},
	{
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

	-- QoL interface.
	{
		spacer = true,
	},
	{
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
		spacer = true,
	},
	{
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
		spacer = true,
	},
	{
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

-- ===

local function checkEnabled( )
	local settingsFile = savefiles.getSettings( "settings" )
	local uitr = settingsFile.data.uitr
	return uitr and uitr["enabled"]
end

local function checkOption( optionId )
	local settingsFile = savefiles.getSettings( "settings" )
	local uitr = settingsFile.data.uitr
	return uitr and uitr["enabled"] and uitr[optionId]
end

local function getOptions( )
	local settingsFile = savefiles.getSettings( "settings" )
	local uitr = settingsFile.data.uitr
	if uitr and uitr["enabled"] then
		return uitr
	else
		return {}
	end
end

local function initOptions( )
	local settingsFile = savefiles.getSettings( "settings" )
	if not settingsFile.data.uitr then settingsFile.data.uitr = {} end

	local uitr = settingsFile.data.uitr
	for _,optionDef in ipairs( UITR_OPTIONS ) do
		if uitr[optionDef.id] == nil then
			if optionDef.value ~= nil then
				uitr[optionDef.id] = optionDef.value
			elseif optionDef.check then
				uitr[optionDef.id] = true
			end
		end
	end
end

return {
	UITR_OPTIONS = UITR_OPTIONS,
	checkEnabled = checkEnabled,
	checkOption = checkOption,
	getOptions = getOptions,
	initOptions = initOptions,
}
