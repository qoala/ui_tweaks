-- init will be called once
local function init( modApi )
	include( modApi:getScriptPath() .. "/monkey_patch" )

	modApi:addGenerationOption("precise_ap", STRINGS.MOD_UI_TWEAKS.OPTIONS.PRECISE_AP, STRINGS.MOD_UI_TWEAKS.OPTIONS.PRECISE_AP_TIP)
	modApi:addGenerationOption("empty_pockets", STRINGS.MOD_UI_TWEAKS.OPTIONS.EMPTY_POCKETS, STRINGS.MOD_UI_TWEAKS.OPTIONS.EMPTY_POCKETS_TIP)
	modApi:addGenerationOption("inv_drag_drop", STRINGS.MOD_UI_TWEAKS.OPTIONS.INV_DRAGDROP, STRINGS.MOD_UI_TWEAKS.OPTIONS.INV_DRAGDROP_TIP)
	modApi:addGenerationOption("precise_icons", STRINGS.MOD_UI_TWEAKS.OPTIONS.PRECISE_ICONS, STRINGS.MOD_UI_TWEAKS.OPTIONS.PRECISE_ICONS_TIP)
	modApi:addGenerationOption("door_while_dragging", STRINGS.MOD_UI_TWEAKS.OPTIONS.DOORS_WHILE_DRAGGING, STRINGS.MOD_UI_TWEAKS.OPTIONS.DOORS_WHILE_DRAGGING_TIP)
	modApi:addGenerationOption("colored_tracks", STRINGS.MOD_UI_TWEAKS.OPTIONS.COLORED_TRACKS, STRINGS.MOD_UI_TWEAKS.OPTIONS.COLORED_TRACKS_TIP)
	modApi:addGenerationOption("step_carefully", STRINGS.MOD_UI_TWEAKS.OPTIONS.STEP_CAREFULLY, STRINGS.MOD_UI_TWEAKS.OPTIONS.STEP_CAREFULLY_TIP)

	local dataPath = modApi:getDataPath()
	KLEIResourceMgr.MountPackage( dataPath .. "/gui.kwad", "data" )
end

-- if older version of ui-tweaks was installed, auto-enable functions for which we
-- have no user state.
local function autoEnable( options, option )
	if not options[option] then
		options[option] = { enabled = true }
	end
end

-- load may be called multiple times with different options enabled
-- params is present iff Sim Constructor is installed and this is a new campaign.
local function load( modApi, options, params )
	local precise_ap = include( modApi:getScriptPath() .. "/precise_ap" )
	local i_need_a_dollar = include( modApi:getScriptPath() .. "/need_a_dollar" )
	local empty_pockets = include( modApi:getScriptPath() .. "/empty_pockets" )
	local item_dragdrop = include( modApi:getScriptPath() .. "/item_dragdrop" )
	local precise_icons = include( modApi:getScriptPath() .. "/precise_icons" )
	local doors_while_dragging = include( modApi:getScriptPath() .. "/doors_while_dragging" )
	local tracks = include( modApi:getScriptPath() .. "/tracks" )
	local step_carefully = include( modApi:getScriptPath() .. "/step_carefully" )


	autoEnable(options, "empty_pockets")
	autoEnable(options, "inv_drag_drop")
	autoEnable(options, "precise_icons")
	autoEnable(options, "doors_while_dragging")
	autoEnable(options, "colored_tracks")
	autoEnable(options, "step_carefully")

	-- On new campaign, clear `need_a_dollar` in case Generation Presets preserved it from an earlier version.
	if params and options["need_a_dollar"] then
		options["need_a_dollar"] = nil
	end
	-- `need_a_dollar` changes the sim state, so retain behavior for existing saves.
	i_need_a_dollar( options["need_a_dollar"] and options["need_a_dollar"].enabled )

	empty_pockets( options["empty_pockets"].enabled )
	precise_icons( options["precise_icons"].enabled )
	item_dragdrop( options["inv_drag_drop"].enabled )
	doors_while_dragging( options["doors_while_dragging"].enabled )
	precise_ap( options["precise_ap"].enabled )
	tracks( options["colored_tracks"].enabled )
	step_carefully( options["step_carefully"].enabled )
end

function _reload_tweaks()
	package.loaded[ 'workshop-581951281/tracks' ] = nil
	return mod_manager:mountContentMod('workshop-581951281')
end

-- gets called before localization occurs and before content is loaded
local function initStrings( modApi )
	local scriptPath = modApi:getScriptPath()

	local strings = include( scriptPath .. "/strings" )
	modApi:addStrings( modApi:getDataPath(), "MOD_UI_TWEAKS", strings )
end

return {
	init = init,
	load = load,
	initStrings = initStrings,
}
