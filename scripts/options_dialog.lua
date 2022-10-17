local mui_defs = include( "mui/mui_defs")
local mui_tooltip = include( "mui/mui_tooltip")
local util = include( "client_util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local options_dialog = include( "hud/options_dialog" )

-- ===

local UITR_OPTIONS = {
	{
		id = "empty_pockets",
		name = STRINGS.UITWEAKSR.OPTIONS.EMPTY_POCKETS,
		tip = STRINGS.UITWEAKSR.OPTIONS.EMPTY_POCKETS_TIP,
		check = true,
	},
	{
		id = "inv_drag_drop",
		name = STRINGS.UITWEAKSR.OPTIONS.INV_DRAGDROP,
		tip = STRINGS.UITWEAKSR.OPTIONS.INV_DRAGDROP_TIP,
		check = true,
	},
	{
		id = "precise_icons",
		name = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS,
		tip = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS_TIP,
		check = true,
	},
	{
		id = "doors_while_dragging",
		name = STRINGS.UITWEAKSR.OPTIONS.DOORS_WHILE_DRAGGING,
		tip = STRINGS.UITWEAKSR.OPTIONS.DOORS_WHILE_DRAGGING_TIP,
		check = true,
	},
	{
		id = "colored_tracks",
		name = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS,
		tip = STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS_TIP,
		values = { false, 1 },
		value = 1,
		strings = { STRINGS.UITWEAKSR.OPTIONS.VANILLA, STRINGS.UITWEAKSR.OPTIONS.COLORED_TRACKS_A },
	},
	{
		id = "step_carefully",
		name = STRINGS.UITWEAKSR.OPTIONS.STEP_CAREFULLY,
		tip = STRINGS.UITWEAKSR.OPTIONS.STEP_CAREFULLY_TIP,
		check = true,
	},
	{
		id = "xu_shank",
		name = STRINGS.UITWEAKSR.OPTIONS.XU_SHANK,
		tip = STRINGS.UITWEAKSR.OPTIONS.XU_SHANK_TIP,
		check = true,
	},

	{
		spacer = true,
	},
	{
		id = "selection_filter_agent",
		name = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_AGENT,
		tip = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_AGENT_TIP,
		values = { false, "CYAN_SHADE", "BLUE_SHADE", "GREEN_SHADE", "PURPLE_SHADE", "CYAN_HILITE", "BLUE_HILITE", "GREEN_HILITE", "PURPLE_HILITE", },
		value = "BLUE_SHADE",
		strings = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_AGENT_COLORS,
	},
	{
		id = "selection_filter_agent_tactical",
		name = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_AGENT_TACTICAL,
		tip = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_AGENT_TACTICAL_TIP,
		check = true,
	},
	{
		id = "selection_filter_tile",
		name = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_TILE,
		tip = STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_TILE_TIP,
		values={ false, "WHITE_SHADE", "CYAN_SHADE", "BLUE_SHADE", },
		value="CYAN_SHADE",
		strings= STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_TILE_COLORS,
	},
}

-- ===

local function onClickUitrResetOptions( dialog )
end

-- ===

local oldShow = options_dialog.show
function options_dialog:show(...)
	oldShow(self, ...)

	local uitrResetBtn = self._screen.binder.uitrResetOptionsBtn
	uitrResetBtn:setText( STRINGS.UITWEAKSR.UI.BTN_RESET_OPTIONS )
	uitrResetBtn.onClick = util.makeDelegate(nil, onClickUitrResetOptions, self)

	self:refreshUitrOptions()
end

function options_dialog:refreshUitrOptions()
	local list = self._screen.binder.uitrOptionsList
	list:clearItems()

	for _,setting in ipairs( UITR_OPTIONS ) do
		local widget
		if setting.check then
			widget = list:addItem( setting, "CheckOption" )
			widget.binder.widget:setText( setting.name )
		elseif setting.values then
			widget = list:addItem( setting, "ComboOption" )
			widget.binder.dropTxt:setText( setting.name )
			for i, item in ipairs(setting.values) do
				widget.binder.widget:addItem( setting.strings and setting.strings[i] or item )
			end
		elseif setting.spacer then
			widget = list:addItem( setting, "OptionSpacer" )
		end
		widget:setTooltip( setting.tip )

		setting.list_index = list:getItemCount()
		assert(setting.list_index > 0)
	end
end
