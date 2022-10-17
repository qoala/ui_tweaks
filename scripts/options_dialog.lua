local mui_defs = include( "mui/mui_defs")
local mui_tooltip = include( "mui/mui_tooltip")
local util = include( "client_util" )
local array = include( "modules/array" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local options_dialog = include( "hud/options_dialog" )

-- ===

local UITR_OPTIONS = {
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
		id = "preciseAp",
		name = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS,
		tip = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS_TIP,
		values={ false, 0.5 },
		value=0.5,
		strings={ STRINGS.UITWEAKSR.OPTIONS.VANILLA, STRINGS.UITWEAKSR.OPTIONS.PRECISE_AP_HALF },
	},
	{
		id = "preciseIcons",
		name = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS,
		tip = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS_TIP,
		check = true,
	},
	{
		id = "doorsWhileDragging",
		name = STRINGS.UITWEAKSR.OPTIONS.DOORS_WHILE_DRAGGING,
		tip = STRINGS.UITWEAKSR.OPTIONS.DOORS_WHILE_DRAGGING_TIP,
		check = true,
	},
	{
		id = "coloredTracks",
		name = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS,
		tip = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS_TIP,
		values = { false, 1 },
		value = 1,
		strings = { STRINGS.UITWEAKSR.OPTIONS.VANILLA, STRINGS.UITWEAKSR.OPTIONS.COLORED_TRACKS_A },
	},
	{
		id = "stepCarefully",
		name = STRINGS.UITWEAKSR.OPTIONS.STEP_CAREFULLY,
		tip = STRINGS.UITWEAKSR.OPTIONS.STEP_CAREFULLY_TIP,
		check = true,
	},
	{
		id = "xuShank",
		name = STRINGS.UITWEAKSR.OPTIONS.XU_SHANK,
		tip = STRINGS.UITWEAKSR.OPTIONS.XU_SHANK_TIP,
		check = true,
	},

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

local function getValue( uitrSettings, optionDef )
	local value = uitrSettings[optionDef.id]
	if value ~= nil then
		return value
	-- Otherwise return the default value
	elseif optionDef.value ~= nil then
		return optionDef.value
	elseif optionDef.check then
		return true
	end
end

local function initUitrSettings( settings )
	if not settings.uitr then settings.uitr = {} end

	for _,optionDef in ipairs( UITR_OPTIONS ) do
		if settings.uitr[optionDef.id] == nil then
			settings.uitr[optionDef.id] = getValue(settings.uitr, optionDef)
		end
	end
end

local function onClickUitrResetOptions( dialog )
	dialog:refreshUitrSettings( {} )
end

-- ===

local function checkOptionApply( self, uitrSettings, value )
	uitrSettings[self.id] = value
end
local function checkOptionRetrieve( self, uitrSettings )
	return getValue(uitrSettings, self)
end
local function comboOptionApply( self, uitrSettings, index )
	uitrSettings[self.id] = self.values[index]
end
local function comboOptionRetrieve( self, uitrSettings )
	if self.strings then
		return self.strings[array.find(self.values, getValue(uitrSettings, self))]
	else
		return tostring(getValue(uitrSettings, self))
	end
end

-- ===

local oldInit = options_dialog.init
function options_dialog:init(...)
	oldInit(self, ...)

	local oldOnClick = self._screen.binder.acceptBtn.binder.btn.onClick._fn
	local oldRetrieveSettings

	local i = 1
	while true do
		local n, v = debug.getupvalue(oldOnClick, i)
		assert(n)
		if n == "retrieveSettings" then
			oldRetrieveSettings = v
			break
		end
		i = i + 1
	end

	local retrieveSettings = function(dialog)
		local settings = oldRetrieveSettings(dialog)

		if not settings.uitr then settings.uitr = {} end
		dialog:retrieveUitrSettings( settings.uitr )

		return settings
	end

	debug.setupvalue(oldOnClick, i, retrieveSettings)
end

local oldShow = options_dialog.show
function options_dialog:show(...)
	oldShow(self, ...)

	local uitrResetBtn = self._screen.binder.uitrResetOptionsBtn
	uitrResetBtn:setText( STRINGS.UITWEAKSR.UI.BTN_RESET_OPTIONS )
	uitrResetBtn.onClick = util.makeDelegate(nil, onClickUitrResetOptions, self)

	if not self._appliedSettings.uitr then self._appliedSettings.uitr = {} end
	self:refreshUitrSettings( self._appliedSettings.uitr )
end

function options_dialog:refreshUitrSettings( uitrSettings )
	local list = self._screen.binder.uitrOptionsList
	list:clearItems()

	for _,optionDef in ipairs( UITR_OPTIONS ) do
		local setting = util.tdupe(optionDef)
		local widget
		if setting.check then
			widget = list:addItem( setting, "CheckOption" )
			widget.binder.widget:setText( setting.name )

			setting.apply = checkOptionApply
			setting.retrieve = checkOptionRetrieve
			widget.binder.widget:setValue( setting:retrieve(uitrSettings) )
		elseif setting.values then
			widget = list:addItem( setting, "ComboOption" )
			widget.binder.dropTxt:setText( setting.name )
			for i, item in ipairs(setting.values) do
				widget.binder.widget:addItem( setting.strings and setting.strings[i] or item )
			end
			setting.apply = comboOptionApply
			setting.retrieve = comboOptionRetrieve
			widget.binder.widget:setValue( setting:retrieve(uitrSettings) )
		elseif setting.spacer then
			widget = list:addItem( setting, "OptionSpacer" )
		end
		widget:setTooltip( setting.tip )

		setting.list_index = list:getItemCount()
		assert(setting.list_index > 0)
	end
end

function options_dialog:retrieveUitrSettings( uitrSettings )
	local items = self._screen.binder.uitrOptionsList:getItems()

	for _,item in ipairs(items) do
		local setting = item.user_data
		if setting and setting.apply then
			local widget = item.widget.binder.widget
			if setting.check then
				setting:apply(uitrSettings, widget:getValue())
			elseif setting.values then
				setting:apply(uitrSettings, widget:getIndex())
			end
		end
	end
end
