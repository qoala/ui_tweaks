local DEBUG_ANIMS = config.UITR and config.UITR.DEBUG_ANIMS

local function earlyInit(modApi)
    modApi.requirements = {
        -- step_carefully must wrap the frost grenade astar_handler changes.
        "Neptune Corporation",
        -- RRNI (precise icons) overrides NIAA icons when available.
        "New Items And Augments",
        -- Disable Action Camera overwrites client/gameplay/boardrig.
        "Disable Action Camera",
        -- Extract upvalues from mission_scoring, so must load before any other appends.
        "Community Bug Fixes",
        "Escorts Fixed",
    }
end

local function forceClientUtilPackageLoad()
    -- Some mods incorrectly load client/client_util, which messes up appends.
    include("client_util")
    include("client/client_util")
end

local function init(modApi)
    -- (This mod doesn't set its own script path, but relies on checking if other mods have done so)
    rawset(_G, "SCRIPT_PATHS", rawget(_G, "SCRIPT_PATHS") or {})
    SCRIPT_PATHS.qed_uitr = modApi:getScriptPath()

    local dataPath = modApi:getDataPath()
    KLEIResourceMgr.MountPackage(dataPath .. "/anims.kwad", "data")
    KLEIResourceMgr.MountPackage(dataPath .. "/gui.kwad", "data")
    KLEIResourceMgr.MountPackage(dataPath .. "/images.kwad", "data")
    KLEIResourceMgr.MountPackage(dataPath .. "/rrni_gui.kwad", "data")
    KLEIResourceMgr.MountPackage(dataPath .. "/tlv_anims.kwad", "data")

    forceClientUtilPackageLoad()

    include(modApi:getScriptPath() .. "/resources").initUitrResources()
    include(modApi:getScriptPath() .. "/uitr_util")
    include(modApi:getScriptPath() .. "/client_defs")
    include(modApi:getScriptPath() .. "/simdefs")

    -- mui (low-level graphical primitives)
    include(modApi:getScriptPath() .. "/mui/mui")
    include(modApi:getScriptPath() .. "/mui/mui_group")
    include(modApi:getScriptPath() .. "/mui/mui_texture")
    include(modApi:getScriptPath() .. "/mui/mui_tooltip") -- Must be before abilityutil.

    include(modApi:getScriptPath() .. "/client_util") -- After mui_tooltip, before abilityutil.

    -- Features using the old pattern of "all changes for this feature in one file."
    include(modApi:getScriptPath() .. "/features/doors_while_dragging")
    include(modApi:getScriptPath() .. "/features/empty_pockets")
    include(modApi:getScriptPath() .. "/features/item_dragdrop")
    include(modApi:getScriptPath() .. "/features/precise_ap")
    include(modApi:getScriptPath() .. "/features/step_carefully")
    include(modApi:getScriptPath() .. "/features/xu_shank")

    -- sim-layer
    include(modApi:getScriptPath() .. "/backend/abilityutil")
    include(modApi:getScriptPath() .. "/backend/commondefs")
    include(modApi:getScriptPath() .. "/backend/engine")
    include(modApi:getScriptPath() .. "/backend/mission_util")
    include(modApi:getScriptPath() .. "/backend/pcplayer")
    include(modApi:getScriptPath() .. "/backend/senses")
    include(modApi:getScriptPath() .. "/backend/simability")
    include(modApi:getScriptPath() .. "/backend/simplayer")
    include(modApi:getScriptPath() .. "/backend/simquery")
    -- inter-mission data layer
    include(modApi:getScriptPath() .. "/backend/mission_scoring")

    -- hud & gameplay (high-level graphical controllers)
    include(modApi:getScriptPath() .. "/hud/agent_actions")
    include(modApi:getScriptPath() .. "/hud/agent_panel")
    include(modApi:getScriptPath() .. "/hud/agentrig")
    include(modApi:getScriptPath() .. "/hud/boardrig")
    include(modApi:getScriptPath() .. "/hud/button_layout")
    include(modApi:getScriptPath() .. "/hud/hud")
    include(modApi:getScriptPath() .. "/hud/mainframe_panel")
    include(modApi:getScriptPath() .. "/hud/options_dialog")
    include(modApi:getScriptPath() .. "/hud/pathrig")
    include(modApi:getScriptPath() .. "/hud/smokerig")
    include(modApi:getScriptPath() .. "/hud/targeting")
    include(modApi:getScriptPath() .. "/hud/viz_manager")
    include(modApi:getScriptPath() .. "/hud/world_hud")
    include(modApi:getScriptPath() .. "/hud/viz/reveal_path")

    include(modApi:getScriptPath() .. "/hud/state-map-screen")

    if config.DEV then
        local debugDecoRig = include(modApi:getScriptPath() .. "/hud/uitrdebug_decorig")
        package.loaded["gameplay/uitrdebug_decorig"] = debugDecoRig
    end
end

--[[
local function lateInit(modApi)
    local scriptPath = modApi:getScriptPath()
end
--]]

-- Apply changes on both unload and load. We're controlled by the settings file, not campaign options.
local function unload(modApi)
    local scriptPath = modApi:getScriptPath()
    local uitr_util = include(scriptPath .. "/uitr_util")

    -- Initialize fields in the settings file
    uitr_util.initOptions()

    modApi:insertUIElements(include(scriptPath .. "/screens/base_screen_inserts"))
    modApi:modifyUIElements(include(scriptPath .. "/screens/base_screen_modifications"))

    if uitr_util.checkEnabled() then
        modApi:insertUIElements(include(scriptPath .. "/screens/screen_inserts"))
    end
end

local function load(modApi, options, params)
    unload(modApi)
    if params then
        params.uiTweaks = {}
    end
end

-- Apply changes on both lateUnload and lateLoad. We're controlled by the settings file, not campaign options.
local function lateUnload(modApi, mod_options)
    local scriptPath = modApi:getScriptPath()
    local uitr_util = include(scriptPath .. "/uitr_util")

    -- "Precise Icons" uses RolandJ's Roman Numeral Icons
    do
        -- Check our options and NIAA options, to determine which icons to replace
        -- If precise icons is disabled, still need to execute to undo any prior changes.
        local RRNI_OPTIONS = {
            RRNI_ENABLED = uitr_util.checkOption("preciseIcons"),
            RRNI_DART_RIFLE_ICON = false,
            RRNI_RANGED_TIERS = false,
        }
        local niaa = mod_manager.findModByName and
                             mod_manager:findModByName("New Items And Augments")
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

        local rrni_itemdefs = include(scriptPath .. "/patches/rrni_itemdefs")
        rrni_itemdefs.swapIcons(RRNI_OPTIONS)
    end

    local modAnimdefs = include(scriptPath .. "/patches/animdefs")
    if uitr_util.checkOption("tacticalLampView") then
        for name, animDef in pairs(modAnimdefs.animdefsFixup) do
            modApi:addAnimDef(name, animDef)
        end
        for name, animDef in pairs(modAnimdefs.animdefsTactical) do
            modApi:addAnimDef(name, animDef)
        end
    end
    if DEBUG_ANIMS then
        for name, animDef in pairs(modAnimdefs.animdefsCoverTest) do
            modApi:addAnimDef(name, animDef)
        end
        local modPropDefs = include(scriptPath .. "/patches/propdefs")
        for name, propDef in pairs(modPropDefs.propdefsCoverTest) do
            modApi:addPropDef(name, propDef, false)
        end
    end

    local modAbilitydefs = include(scriptPath .. "/patches/abilitydefs")
    modAbilitydefs.patchOverwatchFlag()
    modAbilitydefs.patchObservePath()

    if SCRIPT_PATHS.corp_neptune then
        local modPrefabs = include(scriptPath .. "/patches/prefabs_neptune")
        modPrefabs.patchNeptunePrefabs()
    end
end

local function lateLoad(modApi, options, params, mod_options)
    lateUnload(modApi, mod_options)
    local scriptPath = modApi:getScriptPath()
end

-- gets called before localization occurs and before content is loaded
local function initStrings(modApi)
    local scriptPath = modApi:getScriptPath()

    local strings = include(scriptPath .. "/strings")
    modApi:addStrings(modApi:getDataPath(), "UITWEAKSR", strings)
end

return {
    earlyInit = earlyInit,
    init = init,
    load = load,
    -- lateInit = lateInit,
    unload = unload,
    lateLoad = lateLoad,
    lateUnload = lateUnload,
    initStrings = initStrings,
}
