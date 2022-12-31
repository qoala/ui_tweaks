local itemdefs = include("sim/unitdefs/itemdefs")
local util = include("modules/util")

-- A library of the base item names, iterated through when swapping icons
local itemNames = {
    -- Vanilla/DLC Weapons
    "item_tazer",
    "item_tazer_2",
    "item_tazer_3",
    "item_tazer_4",
    "item_power_tazer_1",
    "item_power_tazer_2",
    "item_power_tazer_3",
    "item_power_tazer_4", -- T1 of this actually gets a "_1" for some reason
    "item_armor_tazer_1",
    "item_armor_tazer_1_17_15",
    "item_armor_tazer_2",
    "item_armor_tazer_3",
    "item_armor_tazer_4", -- T1 of this actually gets a "_1" for some reason
    "item_dartgun",
    "item_dartgun_ammo",
    "item_bio_dartgun", -- neural DART, RIOT DART, biogenic DART (this awful gun naming inconsistency)
    "item_dartgun_dam",
    "item_dartgun_ultra", -- drilling dart, mono molecular rail gun
    "item_light_pistol",
    "item_light_pistol_KO",
    "item_light_pistol_ammo", -- plasma gun, K&O pistol, hand cannon (p, pk, pa)
    "item_light_pistol_dam",
    "item_rifle_ultra", -- cooker, K&O lance rifle
    -- Vanilla/DLC Items
    "item_stim",
    "item_stim_2",
    "item_stim_3",
    "item_stim_4",
    "item_paralyzer",
    "item_paralyzer_2",
    "item_paralyzer_3",
    "item_paralyzer_4",
    "item_portabledrive",
    "item_portabledrive_2",
    "item_portabledrive_3",
    "item_icebreaker",
    "item_icebreaker_2",
    "item_icebreaker_3",
    "item_icebreaker_4",
    "item_emp_pack",
    "item_emp_pack_2",
    "item_emp_pack_3",
    "item_emp_pack_4",
    "item_shocktrap",
    "item_shocktrap_2",
    "item_shocktrap_3",
    "item_shocktrap_3_17_9",
    "item_laptop",
    "item_laptop_2",
    "item_laptop_3",
    "item_cloakingrig_1",
    "item_cloakingrig_2",
    "item_cloakingrig_3",
    "item_cloakingrig_3_17_5", -- T1 of this actually gets a "_1" for some reason

    -- NIAA items
    "item_baton",
    "W93_weapon_baton_2",
    "W93_weapon_baton_3",
    "W93_weapon_baton_4",
    "W93_weapon_pwr_baton",
    "W93_weapon_pwr_baton_2",
    "W93_weapon_pwr_baton_3",
    "W93_weapon_pwr_baton_4",
}

-- Used to denote items that get a new icon name
local itemNameReplacements = {
    item_armor_tazer_1_17_15 = "item_armor_tazer_1",
    item_dartgun = "item_dart_pistol",
    item_dartgun_ammo = "item_dart_pistol_2",
    item_bio_dartgun = "item_dart_pistol_3",
    item_dartgun_dam = "item_dart_rifle",
    item_dartgun_ultra = "item_dart_rifle_2",
    item_light_pistol = "item_pistol",
    item_light_pistol_KO = "item_pistol_2",
    item_light_pistol_ammo = "item_pistol_3",
    item_light_pistol_dam = "item_rifle",
    item_rifle_ultra = "item_rifle_2",
    item_shocktrap_3_17_9 = "item_shocktrap_3",
    item_cloakingrig_3_17_5 = "item_cloakingrig_3",
}

-- Provides compatibility for saves that lack NIAA (hold back our NIAA baton icons for these saves, basically)
local exclusiveItemNamesNIAA = {
    "item_baton",
    "W93_weapon_baton_2",
    "W93_weapon_baton_3",
    "W93_weapon_baton_4",
    "W93_weapon_pwr_baton",
    "W93_weapon_pwr_baton_2",
    "W93_weapon_pwr_baton_3",
    "W93_weapon_pwr_baton_4",
}

-- Detects item category, for use in determining NIAA category's option setting
local function getCategory(item)
    if item.abilities["installAugment"] then
        return "AUGMENTS"
    elseif item.traits.slot == "melee" or item.traits.slot == "gun" then
        return "WEAPONS"
    else
        return "ITEMS"
    end
end

-- Provides compatibility with NIAA's de-tiered items
local detieredItemsByCategoryNIAA = {
    ITEMS = {
        "item_stim",
        "item_stim_2",
        "item_stim_3",
        "item_stim_4",
        "item_paralyzer",
        "item_paralyzer_2",
        "item_paralyzer_3",
        "item_paralyzer_4",
        "item_portabledrive",
        "item_portabledrive_2",
        "item_portabledrive_3",
        "item_icebreaker",
        "item_icebreaker_2",
        "item_icebreaker_3",
        "item_icebreaker_4",
        "item_emp_pack",
        "item_emp_pack_2",
        "item_emp_pack_3",
        "item_emp_pack_4",
        "item_shocktrap",
        "item_shocktrap_2",
        "item_shocktrap_3",
        "item_shocktrap_3_17_9",
        "item_laptop",
        "item_laptop_2",
        "item_laptop_3",
        "item_cloakingrig_1",
        "item_cloakingrig_2",
        "item_cloakingrig_3",
        "item_cloakingrig_3_17_5",
    },
    WEAPONS = {
        -- making sure my RANGED_TIERS option does not integrate with NIAA's unique guns
        "item_dartgun",
        "item_dartgun_ammo",
        "item_bio_dartgun",
        "item_dartgun_dam",
        "item_dartgun_ultra",
        "item_light_pistol",
        "item_light_pistol_KO",
        "item_light_pistol_ammo",
        "item_light_pistol_dam",
        "item_rifle_ultra",
    },
    AUGMENTS = {},
}

-- Use the library of base item names to swap out icons
local function swapIcons(options)
    simlog(
            "(RRNI Debug) Beginning to " .. (options.RRNI_ENABLED and "load" or "unload") ..
                    " Roland's Roman Numeral Icons (RRNI) item icons...")

    -- log out the campaign options
    -- for cat, options in pairs(options) do
    -- 	local summary = "(RRNI Debug)  - "..cat..":"
    -- 	for option, value in pairs(options) do summary = summary .. (summary:find(":",summary:len()) and " " or " / ") .. option .. "=" .. tostring(value) end
    -- 	simlog("LOG_UITR", summary)
    -- end

    -- prepare variables used for the final debug summary
    local swapCount = 0
    local skipCount = 0
    local preloadCount = 0
    local unfoundCount = 0
    local NIAA_skips = 0
    local NIAA_detiers = 0

    -- loop through my library of itemNames
    for _, itemName in ipairs(itemNames) do
        local item = itemdefs[itemName]

        -- LOAD RRNI ICONS PORTION
        if options.RRNI_ENABLED then
            -- log:write("itemName: "..itemName)
            if not item then
                skipCount = skipCount + 1
                if util.indexOf(exclusiveItemNamesNIAA, itemName) then
                    -- log:write("(RRNI Debug)   NIAA SKIP: Item \"" .. itemName .. "\" (Reason: NIAA exclusive item whose related NIAA option is disabled)")
                    NIAA_skips = NIAA_skips + 1
                else
                    -- log:write("(RRNI Debug)   NOTICE: Item \"" .. itemName .. "\" not found in itemdefs")
                    unfoundCount = unfoundCount + 1
                end
            else
                -- determine the initial RRNI icon name, adding T1 "_1" suffix where needed, when names don't end with a digit
                local RRNIIconName = itemNameReplacements[itemName] or itemName
                if not RRNIIconName:match("_%d") then
                    RRNIIconName = RRNIIconName .. "_1"
                end

                -- add ranged tweaks for icon names
                local isRanged = item.traits.weaponType and
                                         (item.traits.weaponType == "pistol" or
                                                 item.traits.weaponType == "rifle")
                if isRanged then
                    -- for dart rifles, add new/fix flag depending on NEW_DART_RIFLE_ICON option (new modern-rifle vs fix old icon's ammo)
                    if itemName:find("dartgun") and (itemName:find("dam") or itemName:find("ultra")) then
                        local dartRifleFlag
                        if options.RRNI_DART_RIFLE_ICON then
                            dartRifleFlag = "_new"
                        else
                            dartRifleFlag = "_fix"
                        end
                        RRNIIconName = RRNIIconName:gsub("(_%d)", dartRifleFlag .. "%1") -- thank you moss for explaining capture groups
                    end

                    -- remove roman numerals if RANGED_TIERS option is off
                    if not options.RRNI_RANGED_TIERS then
                        RRNIIconName = RRNIIconName:gsub("_%d", "")
                    end
                end

                -- generate final RRNI filenames (post-RANGED_TIERS check)
                local profile_100_filename = "gui/icons/item_icons/RRNI-icon-" .. RRNIIconName ..
                                                     ".png"
                local profile_filename = "gui/icons/item_icons/items_icon_small/RRNI-icon-" ..
                                                 RRNIIconName .. "_small.png"

                -- generate item category, for use in NIAA compatibility checks
                local category = getCategory(item)
                local exclusiveToNIAA = util.indexOf(exclusiveItemNamesNIAA, itemName)
                local detieredByNIAA = util.indexOf(detieredItemsByCategoryNIAA[category], itemName)

                -- load icon
                if item.profile_icon_100 == profile_100_filename then -- PRELOADED ICONS
                    -- log:write("(RRNI Debug)   PRELOADED: Item \"" .. itemName .. "\" (RRNI-icon-" .. RRNIIconName .. ") (Reason: Already loaded \""..item.profile_icon_100.."\")")
                    skipCount = skipCount + 1
                    preloadCount = preloadCount + 1
                elseif detieredByNIAA and options.NIAA[category] then -- This gear is detiered by NIAA AND its NIAA category is enabled
                    -- log:write("(RRNI Debug)   NIAA SKIP: Item \"" .. itemName .. "\" (Reason: NIAA detiered item whose related NIAA option is enabled)")
                    skipCount = skipCount + 1
                    NIAA_detiers = NIAA_detiers + 1
                elseif exclusiveToNIAA and (not options.NIAA[category]) then -- This is NIAA-exclusive gear, yet its NIAA category is disabled
                    -- log:write("(RRNI Debug)   NIAA SKIP: Item \"" .. itemName .. "\" (Reason: NIAA exclusive item whose related NIAA option is disabled)")
                    skipCount = skipCount + 1
                    NIAA_skips = NIAA_skips + 1
                else
                    -- log the data
                    swapCount = swapCount + 1
                    -- log:write("(RRNI Debug)   " .. swapCount .. ". Item \"" .. itemName .. "\" (RRNI-icon-" .. RRNIIconName .. ")")

                    -- store old icons
                    item.RRNI_old_profile_icon_100 = item.profile_icon_100
                    item.RRNI_old_profile_icon = item.profile_icon

                    -- set new icons
                    item.profile_icon_100 = profile_100_filename
                    item.profile_icon = profile_filename
                end
            end
        else
            -- UNLOAD RRNI ICONS PORTION
            -- determine if item is in RRNI state
            if item and item.RRNI_old_profile_icon_100 and item.RRNI_old_profile_icon then
                -- log the data
                swapCount = swapCount + 1
                -- log:write("(RRNI Debug)   " .. swapCount .. ". Item: \"" .. itemName .. "\"")

                -- unload profile icons
                item.profile_icon_100 = item.RRNI_old_profile_icon_100
                item.profile_icon = item.RRNI_old_profile_icon
                item.RRNI_old_profile_icon_100 = nil
                item.RRNI_old_profile_icon = nil
            else
                -- log:write("(RRNI Debug)   SKIP: Item \"" .. itemName .. "\" (profile_icon: " .. (item and "\"" .. item.profile_icon .. "\"" or "(empty)") .. " (Reason: item has no RRNI_old_profile_icon)")
            end
        end
    end

    -- prepare final debug summary
    local summary
    if not (skipCount == 0) then
        summary = ", skipped " .. skipCount .. " items ("
        if not (unfoundCount == 0) then
            summary = summary .. (summary:find("%(", summary:len()) and " " or " / ") ..
                              unfoundCount .. " unfound itemdefs"
        end
        if not (preloadCount == 0) then
            summary = summary .. (summary:find("%(", summary:len()) and " " or " / ") ..
                              preloadCount .. " preloaded icons"
        end
        if not (NIAA_detiers == 0) then
            summary = summary .. (summary:find("%(", summary:len()) and " " or " / ") ..
                              NIAA_detiers .. " NIAA detiered items"
        end
        if not (NIAA_skips == 0) then
            summary =
                    summary .. (summary:find("%(", summary:len()) and " " or " / ") .. NIAA_skips ..
                            " disabled NIAA items"
        end
        summary = summary .. " )"
    end

    -- print final debug
    simlog(
            "(RRNI Debug) DONE: " .. (options.RRNI_ENABLED and "Loaded" or "Unloaded") ..
                    " icons for " .. swapCount .. " items" .. (summary and summary or ""))
end

return {swapIcons = swapIcons}
