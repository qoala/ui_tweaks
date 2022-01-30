local function earlyInit( modApi )
	modApi.requirements =
	{
		-- step_carefully must wrap the frost grenade astar_handler changes.
		"Neptune Corporation",
		-- RRNI (precise icons) overrides NIAA icons when available.
		"New Items And Augments",
	}
end

-- init will be called once
local function init( modApi )
	include( modApi:getScriptPath() .. "/monkey_patch" )

	modApi:addGenerationOption("precise_ap", STRINGS.MOD_UI_TWEAKS.OPTIONS.PRECISE_AP, STRINGS.MOD_UI_TWEAKS.OPTIONS.PRECISE_AP_TIP, {
		noUpdate=true,
		values={ false, 0.5 },
		value=0.5,
		strings={ STRINGS.MOD_UI_TWEAKS.OPTIONS.VANILLA, STRINGS.MOD_UI_TWEAKS.OPTIONS.PRECISE_AP_HALF },
	})
	modApi:addGenerationOption("empty_pockets", STRINGS.MOD_UI_TWEAKS.OPTIONS.EMPTY_POCKETS, STRINGS.MOD_UI_TWEAKS.OPTIONS.EMPTY_POCKETS_TIP, { noUpdate=true })
	modApi:addGenerationOption("inv_drag_drop", STRINGS.MOD_UI_TWEAKS.OPTIONS.INV_DRAGDROP, STRINGS.MOD_UI_TWEAKS.OPTIONS.INV_DRAGDROP_TIP, { noUpdate=true })
	modApi:addGenerationOption("precise_icons", STRINGS.MOD_UI_TWEAKS.OPTIONS.PRECISE_ICONS, STRINGS.MOD_UI_TWEAKS.OPTIONS.PRECISE_ICONS_TIP, { noUpdate=true })
	modApi:addGenerationOption("doors_while_dragging", STRINGS.MOD_UI_TWEAKS.OPTIONS.DOORS_WHILE_DRAGGING, STRINGS.MOD_UI_TWEAKS.OPTIONS.DOORS_WHILE_DRAGGING_TIP, { noUpdate=true })
	modApi:addGenerationOption("colored_tracks", STRINGS.MOD_UI_TWEAKS.OPTIONS.COLORED_TRACKS, STRINGS.MOD_UI_TWEAKS.OPTIONS.COLORED_TRACKS_TIP, {
		noUpdate=true,
		values={ false, 1 },
		value=1,
		strings={ STRINGS.MOD_UI_TWEAKS.OPTIONS.VANILLA, STRINGS.MOD_UI_TWEAKS.OPTIONS.COLORED_TRACKS_A },
	})
	modApi:addGenerationOption("step_carefully", STRINGS.MOD_UI_TWEAKS.OPTIONS.STEP_CAREFULLY, STRINGS.MOD_UI_TWEAKS.OPTIONS.STEP_CAREFULLY_TIP, { noUpdate=true })
	modApi:addGenerationOption("xu_shank", STRINGS.MOD_UI_TWEAKS.OPTIONS.XU_SHANK, STRINGS.MOD_UI_TWEAKS.OPTIONS.XU_SHANK_TIP, { noUpdate=true })

	local dataPath = modApi:getDataPath()
	KLEIResourceMgr.MountPackage( dataPath .. "/rrni_gui.kwad", "data" )

	include( modApi:getScriptPath() .. "/doors_while_dragging" )
	include( modApi:getScriptPath() .. "/empty_pockets" )
	include( modApi:getScriptPath() .. "/item_dragdrop" )
	include( modApi:getScriptPath() .. "/precise_ap" )
	include( modApi:getScriptPath() .. "/step_carefully" )
	include( modApi:getScriptPath() .. "/tracks" )
	include( modApi:getScriptPath() .. "/xu_shank" )
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
	end
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
end

-- gets called before localization occurs and before content is loaded
local function initStrings( modApi )
	local scriptPath = modApi:getScriptPath()

	local strings = include( scriptPath .. "/strings" )
	modApi:addStrings( modApi:getDataPath(), "MOD_UI_TWEAKS", strings )
end

return {
	earlyInit = earlyInit,
	init = init,
	load = load,
	lateLoad = lateLoad,
	lateUnload = lateUnload,
	initStrings = initStrings,
}
