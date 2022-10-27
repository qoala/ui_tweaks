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

local function init( modApi )
	-- (This mod doesn't set its own script path, but relies on checking if other mods have done so)
	rawset(_G,"SCRIPT_PATHS",rawget(_G,"SCRIPT_PATHS") or {})
	SCRIPT_PATHS.qed_uitr = modApi:getScriptPath()

	local dataPath = modApi:getDataPath()
	KLEIResourceMgr.MountPackage( dataPath .. "/gui.kwad", "data" )
	KLEIResourceMgr.MountPackage( dataPath .. "/images.kwad", "data" )
	KLEIResourceMgr.MountPackage( dataPath .. "/rrni_gui.kwad", "data" )
	KLEIResourceMgr.MountPackage( dataPath .. "/tlv_anims.kwad", "data" )

	include( modApi:getScriptPath() .. "/resources" ).initUitrResources()
	include( modApi:getScriptPath() .. "/uitr_util" )

	include( modApi:getScriptPath() .. "/mui_tooltip" ) -- Must be before abilityutil.

	include( modApi:getScriptPath() .. "/doors_while_dragging" )
	include( modApi:getScriptPath() .. "/empty_pockets" )
	include( modApi:getScriptPath() .. "/item_dragdrop" )
	include( modApi:getScriptPath() .. "/precise_ap" )
	include( modApi:getScriptPath() .. "/step_carefully" )
	include( modApi:getScriptPath() .. "/tracks" )
	include( modApi:getScriptPath() .. "/xu_shank" )

	include( modApi:getScriptPath() .. "/client_defs" )
	include( modApi:getScriptPath() .. "/abilityutil" )
	include( modApi:getScriptPath() .. "/agent_actions" )
	include( modApi:getScriptPath() .. "/agent_panel" )
	include( modApi:getScriptPath() .. "/agentrig" )
	include( modApi:getScriptPath() .. "/board_rig" )
	include( modApi:getScriptPath() .. "/hud" )
	include( modApi:getScriptPath() .. "/engine" )
	include( modApi:getScriptPath() .. "/mission_scoring" )
	include( modApi:getScriptPath() .. "/options_dialog" )
	include( modApi:getScriptPath() .. "/simability" )
	include( modApi:getScriptPath() .. "/simquery" )
	include( modApi:getScriptPath() .. "/targeting" )
	include( modApi:getScriptPath() .. "/world_hud" )
end

local function lateInit( modApi )
	local scriptPath = modApi:getScriptPath()

	-- More Archived Agents has a copy of the same "Rescued agent status" fix, but doesn't guard against being applied a second time.
	include( scriptPath .. "/mission_scoring_lateinit" )
end

-- Apply changes on both unload and load. We're controlled by the settings file, not campaign options.
local function unload( modApi )
	local scriptPath = modApi:getScriptPath()
	local uitr_util = include( scriptPath .. "/uitr_util" )

	-- Initialize fields in the settings file
	uitr_util.initOptions()

	modApi:insertUIElements( include( scriptPath.."/base_screen_inserts" ) )
	modApi:modifyUIElements( include( scriptPath.."/base_screen_modifications" ) )

	if uitr_util.checkEnabled() then
		modApi:insertUIElements( include( scriptPath.."/screen_inserts" ) )
	end
end

local function load( modApi, options, params )
	unload( modApi )
	if params then
		params.uiTweaks = {}
	end
end

-- Apply changes on both lateUnload and lateLoad. We're controlled by the settings file, not campaign options.
local function lateUnload( modApi, mod_options )
	local scriptPath = modApi:getScriptPath()
	local uitr_util = include( scriptPath .. "/uitr_util" )

	-- "Precise Icons" uses RolandJ's Roman Numeral Icons
	do
		-- Check our options and NIAA options, to determine which icons to replace
		-- If precise icons is disabled, still need to execute to undo any prior changes.
		local RRNI_OPTIONS = {
			RRNI_ENABLED = uitr_util.checkOption("preciseIcons") ,
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

		local rrni_itemdefs = include( scriptPath .. "/rrni_itemdefs" )
		rrni_itemdefs.swapIcons(RRNI_OPTIONS)
	end

	if uitr_util.checkOption("tacticalLampView") then
		for name, animDef in pairs(include( scriptPath .. "/animdefs_tactical" )) do
			modApi:addAnimDef( name, animDef )
		end
	end

	local patch_abilities = include( scriptPath .. "/patch_abilities" )
	patch_abilities.applyOverwatchFlag()
end

local function lateLoad( modApi, options, params, mod_options )
	lateUnload( modApi, mod_options )
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
	lateInit = lateInit,
	unload = unload,
	lateLoad = lateLoad,
	lateUnload = lateUnload,
	initStrings = initStrings,
}
