local function earlyInit( modApi )
	modApi.requirements =
	{
		-- step_carefully must wrap the frost grenade astar_handler changes.
		"Neptune Corporation",
		-- RRNI (precise icons) overrides NIAA icons when available.
		"New Items And Augments",
		-- Disable Action Camera overwrites client/gameplay/boardrig.
		"Disable Action Camera",
	}
end

-- init will be called once
local function init( modApi )
	-- (This mod doesn't set its own script path, but relies on checking if other mods have done so)
	rawset(_G,"SCRIPT_PATHS",rawget(_G,"SCRIPT_PATHS") or {})

	modApi:addGenerationOption("precise_ap", STRINGS.UITWEAKSR.OPTIONS.PRECISE_AP, STRINGS.UITWEAKSR.OPTIONS.PRECISE_AP_TIP, {
		noUpdate=true,
		values={ false, 0.5 },
		value=0.5,
		strings={ STRINGS.UITWEAKSR.OPTIONS.VANILLA, STRINGS.UITWEAKSR.OPTIONS.PRECISE_AP_HALF },
	})
	modApi:addGenerationOption("empty_pockets", STRINGS.UITWEAKSR.OPTIONS.EMPTY_POCKETS, STRINGS.UITWEAKSR.OPTIONS.EMPTY_POCKETS_TIP, { noUpdate=true })
	modApi:addGenerationOption("inv_drag_drop", STRINGS.UITWEAKSR.OPTIONS.INV_DRAGDROP, STRINGS.UITWEAKSR.OPTIONS.INV_DRAGDROP_TIP, { noUpdate=true })
	modApi:addGenerationOption("precise_icons", STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS, STRINGS.UITWEAKSR.OPTIONS.PRECISE_ICONS_TIP, { noUpdate=true })
	modApi:addGenerationOption("doors_while_dragging", STRINGS.UITWEAKSR.OPTIONS.DOORS_WHILE_DRAGGING, STRINGS.UITWEAKSR.OPTIONS.DOORS_WHILE_DRAGGING_TIP, { noUpdate=true })
	modApi:addGenerationOption("colored_tracks", STRINGS.UITWEAKSR.OPTIONS.COLORED_TRACKS, STRINGS.UITWEAKSR.OPTIONS.COLORED_TRACKS_TIP, {
		noUpdate=true,
		values={ false, 1 },
		value=1,
		strings={ STRINGS.UITWEAKSR.OPTIONS.VANILLA, STRINGS.UITWEAKSR.OPTIONS.COLORED_TRACKS_A },
	})
	modApi:addGenerationOption("step_carefully", STRINGS.UITWEAKSR.OPTIONS.STEP_CAREFULLY, STRINGS.UITWEAKSR.OPTIONS.STEP_CAREFULLY_TIP, { noUpdate=true })
	modApi:addGenerationOption("xu_shank", STRINGS.UITWEAKSR.OPTIONS.XU_SHANK, STRINGS.UITWEAKSR.OPTIONS.XU_SHANK_TIP, { noUpdate=true })
	
	-- OLD: for agent filtering
	-- modApi:addGenerationOption("selection_filter", STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER, STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_TIP, {
		-- noUpdate=true,
		-- values={ false, "CYAN_SHADE", "CYAN_HILITE", "BLUE_SHADE", "BLUE_HILITE", },
		-- value="CYAN_SHADE",
		-- strings= STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_COLORS,
	-- })	
	
	-- NEW: for ring filtering
	modApi:addGenerationOption("selection_filter", STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER, STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_TIP, {
		noUpdate=true,
		values={ false, "WHITE_SHADE", "CYAN_SHADE", "BLUE_SHADE",},
		value="WHITE_SHADE",
		strings= STRINGS.UITWEAKSR.OPTIONS.SELECTION_FILTER_COLORS,
	})		

	local dataPath = modApi:getDataPath()
	KLEIResourceMgr.MountPackage( dataPath .. "/gui.kwad", "data" )
	KLEIResourceMgr.MountPackage( dataPath .. "/images.kwad", "data" )
	KLEIResourceMgr.MountPackage( dataPath .. "/rrni_gui.kwad", "data" )

	include( modApi:getScriptPath() .. "/resources" ).initUitrResources()

	include( modApi:getScriptPath() .. "/doors_while_dragging" )
	include( modApi:getScriptPath() .. "/empty_pockets" )
	include( modApi:getScriptPath() .. "/item_dragdrop" )
	include( modApi:getScriptPath() .. "/precise_ap" )
	include( modApi:getScriptPath() .. "/step_carefully" )
	include( modApi:getScriptPath() .. "/tracks" )
	include( modApi:getScriptPath() .. "/xu_shank" )

	include( modApi:getScriptPath() .. "/client_defs" )
	include( modApi:getScriptPath() .. "/board_rig" )
	include( modApi:getScriptPath() .. "/agent_actions" )
	include( modApi:getScriptPath() .. "/hud" )
	include( modApi:getScriptPath() .. "/engine" )
	include( modApi:getScriptPath() .. "/simquery" )
	include( modApi:getScriptPath() .. "/agentrig" )
end

-- load may be called multiple times with different options enabled
-- params is present iff Sim Constructor is installed and this is a new campaign.
local function load( modApi, options, params )

	if params then
		params.uiTweaks = {}

		params.uiTweaks.coloredTracks = options["colored_tracks"] and options["colored_tracks"].value
		params.uiTweaks.doorsWhileDragging = options["doors_while_dragging"] and options["doors_while_dragging"].enabled
		params.uiTweaks.emptyPockets = options["empty_pockets"] and options["empty_pockets"].enabled
		params.uiTweaks.invDragDrop = options["inv_drag_drop"] and options["inv_drag_drop"].enabled
		params.uiTweaks.preciseAp = options["precise_ap"] and options["precise_ap"].value
		params.uiTweaks.stepCarefully = options["step_carefully"] and options["step_carefully"].enabled
        params.uiTweaks.xuShank = options["xu_shank"] and options["xu_shank"].enabled
		params.uiTweaks.selectionFilter = options["selection_filter"] and options["selection_filter"].value

		-- Save a fake option, in case this gets a campaign toggle later
		options["vision_mode"] = { enabled=true }
	end

	local scriptPath = modApi:getScriptPath()
	modApi:insertUIElements( include( scriptPath.."/screen_inserts" ) )
end

local function lateLoad( modApi, options, params, mod_options )

	-- "Precise Icons" uses RolandJ's Roman Numeral Icons
	-- Check our options and NIAA options, to determine which icons to replace
	local RRNI_OPTIONS = {
		RRNI_ENABLED = options["precise_icons"] and options["precise_icons"].enabled ,
		RRNI_DART_RIFLE_ICON = false,
		RRNI_RANGED_TIERS = false,
	}
	local niaa = mod_manager.findModByName and mod_manager:findModByName( "New Items And Augments" )
	if niaa and mod_options[niaa.id] and mod_options[niaa.id].enabled then
		local niaaOptions = mod_options[niaa.id].options
		RRNI_OPTIONS.NIAA = {
			AUGMENTS = niaaOptions["enable_augments"] and niaaOptions["enable_augments"].enabled,
			ITEMS = niaaOptions["enable_items"] and niaaOptions["enable_items"].enabled,
			WEAPONS = niaaOptions["enable_weapons"] and niaaOptions["enable_weapons"].enabled,
		}
	else
		RRNI_OPTIONS.NIAA = {}
	end

	local scriptPath = modApi:getScriptPath()
	local rrni_itemdefs = include( scriptPath .. "/rrni_itemdefs" )
	rrni_itemdefs.swapIcons(RRNI_OPTIONS)
end

local function lateUnload( modApi, options )
	local scriptPath = modApi:getScriptPath()
	local rrni_itemdefs = include( scriptPath .. "/rrni_itemdefs" )
	rrni_itemdefs.swapIcons({ RRNI_ENABLED = false })
end

-- gets called before localization occurs and before content is loaded
local function initStrings( modApi )
	local scriptPath = modApi:getScriptPath()

	local strings = include( scriptPath .. "/strings" )
	modApi:addStrings( modApi:getDataPath(), "UITWEAKSR", strings )
end

return {
	earlyInit = earlyInit,
	init = init,
	load = load,
	lateLoad = lateLoad,
	lateUnload = lateUnload,
	initStrings = initStrings,
}
