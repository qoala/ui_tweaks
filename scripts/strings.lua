local UI_TWEAKS_STRINGS = {
    OPTIONS = {
        MOD_ENABLED = "Enabled",
        VANILLA = "OFF/VANILLA",

        RECENT_FOOTPRINTS = "Guard Trails",
        RECENT_FOOTPRINTS_TIP = ("Trail footprints behind guards that you see or otherwise sense walking.\n" ..
                "SEEN ONLY: Only show seen or otherwise directly observed (TAG, etc) tracks.\n" ..
                "FULL: Also show the location of heard tracks. Camera/Pulse drones do NOT make movement noise."),
        RECENT_FOOTPRINTS_OPTIONS = { --
            "OFF/VANILLA",
            "SEEN ONLY",
            "FULL",
        },
        RECENT_FOOTPRINTS_MODE = "    Trail Visibility Mode",
        RECENT_FOOTPRINTS_MODE_TIP = ("When should footprints be shown? " ..
                "Visibility can be temporarily toggled from buttons near the Info Mode toggle.\n" ..
                "ENEMY TURN (AUTO): Normally only shown during the enemy turn, resetting on End Turn.\n" ..
                "SHOW/HIDE (AUTO): Normally shown or hidden, resetting on End Turn.\n" ..
                "SHOW/HIDE (STICKY): Shown or hidden at start of mission. Does not reset automatically."),
        RECENT_FOOTPRINTS_MODE_OPTIONS = { --
            "ENEMY TURN (AUTO)",
            "HIDE (AUTO)",
            "SHOW (AUTO)",
            "HIDE (STICKY)",
            "SHOW (STICKY)",
        },
        COLORED_TRACKS = "Colored Guard Paths",
        COLORED_TRACKS_TIP = "Guards get uniquely colored paths and interest points",
        COLORED_TRACKS_A = "PALETTE A",

        MAP_DISTANCES = "Map Distances",
        MAP_DISTANCES_TIP = "On the world map, show travel times to each location. On hover, values reflect distance from the hovered location.",

        GRID_COORDS = "Grid Coordinates",
        GRID_COORDS_TIP = "Show an overlay of grid coordinates.",
        GRID_COORDS_OPTIONS = { --
            "OFF/VANILLA",
            "AGENT-RELATIVE",
        },
        PRECISE_AP = "Precise AP",
        PRECISE_AP_TIP = "Round AP to .5 instead of whole number",
        PRECISE_AP_HALF = "0.5",
        PRECISE_ICONS = "Precise Icons",
        PRECISE_ICONS_TIP = "Label stim, paralyzer, cloak, etc with the different level of item.\nCREDIT: RolandJ",
        TACTICAL_LAMP_VIEW = "Tactical Lamp View",
        TACTICAL_LAMP_VIEW_TIP = "Distinct graphics for tall cover (book cases, etc) and non-cover (some lamps, etc) items.\nCREDIT: Benjamin C. Lewis, Hekateras",
        TACTICAL_CLOUDS = "Tactical Cloud Effects",
        TACTICAL_CLOUDS_TIP = "Less-obscuring graphics for clouds in tactical view. Can also be enabled for in-world view if so desired.",
        TACTICAL_CLOUD_OPTIONS = { --
            "OFF/VANILLA",
            "ON",
            "ALWAYS",
        },
        CLEAN_SHIFT = "SHIFT Hides Context Actions.",
        CLEAN_SHIFT_TIP = "Holding SHIFT hides targeted action icons, making it easier to select or move agents in crowded areas.\nThis is in addition to the vanilla keybinding where holding SHIFT highlights tiles watched by units under the cursor.",
        SPRINT_NOISE_PREVIEW = "Sprint Noise Preview",
        SPRINT_NOISE_PREVIEW_TIP = "While previewing sprint movement, highlights units that would hear the agent and/or the floor radius.",
        SPRINT_NOISE_PREVIEW_OPTIONS = { --
            "OFF",
            "UNITS",
            "RADIUS",
            "UNITS+RADIUS",
        },
        MAINFRAME_LAYOUT = "Mainframe Firewall Layout",
        MAINFRAME_LAYOUT_TIP = "If active, mainframe firewall indicators will shift to avoid overlap.",

        EMPTY_POCKETS = "Steal/Search: Enable Empty Pockets",
        EMPTY_POCKETS_TIP = "Agents can attempt to steal if it would newly reveal that the target isn't carrying anything.\nAllows marking targets as Searched and Expertly Searched.",
        CORPSE_POCKETS = "Steal/Search: Track Searched Corpses",
        CORPSE_POCKETS_TIP = "Guard & drone corpses also show 'searched' tooltips.",
        INV_DRAGDROP = "Inventory Drag/Drop Reordering",
        INV_DRAGDROP_TIP = "Allow drag & drop to reorder an agent's inventory (between missions)",
        DOORS_WHILE_DRAGGING = "Doors While Dragging",
        DOORS_WHILE_DRAGGING_TIP = "Allow door manipulation while dragging bodies. Only works if it is possible to drop the body, so does not alter gameplay.",
        STEP_CAREFULLY = "Careful Pathing",
        STEP_CAREFULLY_TIP = "Agents prefer to avoid watched/noticed tiles, while still choosing a path with the shortest distance",

        OVERWATCH_MOVEMENT_WARNINGS = "Overwatch Movement Warnings",
        OVERWATCH_MOVEMENT_WARNINGS_TIP = "Warning tiles appear on the floor if movement will trigger overwatch.",
        OVERWATCH_ABILITY_WARNINGS = "Overwatch Ability Warnings",
        OVERWATCH_ABILITY_WARNINGS_TIP = "Ability tooltips warn if the ability can trigger overwatch.",

        SELECTION_FILTER_AGENT = "Highlight Selected Agent",
        SELECTION_FILTER_AGENT_TIP = "Selected agent is highlighted in a bright color of your choice.",
        SELECTION_FILTER_AGENT_COLORS = { --
            "OFF/VANILLA",
            "CYAN",
            "BLUE",
            "GREEN",
            "PURPLE",
            "SOLID CYAN",
            "SOLID BLUE",
            "SOLID GREEN",
            "SOLID PURPLE",
        },
        SELECTION_FILTER_INWORLD = "    In-World",
        SELECTION_FILTER_INWORLD_TIP = "Selected agent highlighting is applied in normal view.",
        SELECTION_FILTER_TACTICAL = "    Tactical",
        SELECTION_FILTER_TACTICAL_TIP = "Selected agent highlighting is applied in tactical view.",
        SELECTION_FILTER_TILE = "Highlight Selected Agent Tile",
        SELECTION_FILTER_TILE_TIP = "Selected agent's tile is highlighted in a bright color of your choice.",
        SELECTION_FILTER_TILE_COLORS = { --
            "OFF/VANILLA",
            "WHITE",
            "CYAN",
            "BLUE",
        },
    },

    UI = {
        NO_LOOT = "NO LOOT",

        BTN_VISIONMODE_HEADER = "INFO MODE",
        BTN_VISIONMODE_ENABLE_TXT = "Enable info mode.",
        BTN_VISIONMODE_DISABLE_TXT = "Disable info mode.",
        BTN_GLOBAL_PT_HIDE_HEADER = "HIDE PATHS/FOOTPRINTS",
        BTN_GLOBAL_PT_HIDE_TXT = "Click to hide all paths and footprints until the enemy turn.",
        BTN_GLOBAL_PT_CYCLE_HEADER = "CYCLE PATH/FOOTPRINT VISIBILITY",
        BTN_GLOBAL_PT_CYCLE_TXT = "Cycle between showing:\nPaths > Footprints > Both",
        BTN_GLOBAL_PT_CYCLE_P_TXT = "Cycle between showing:\n<ttheader>Paths</> > Footprints > Both",
        BTN_GLOBAL_PT_CYCLE_T_TXT = "Cycle between showing:\nPaths > <ttheader>Footprints</> > Both",
        BTN_GLOBAL_PT_CYCLE_BOTH_TXT = "Cycle between showing:\nPaths > Footprints > <ttheader>Both</>",
        BTN_UNITVISION_HEADER = "TOGGLE VISION: {1}",
        BTN_UNITVISION_SHOW_TXT = "Show this unit's vision.",
        BTN_UNITVISION_HIDE_TXT = "Hide this unit's vision.",
        BTN_UNIT_PATH_HEADER = "TOGGLE PATH: {1}",
        BTN_UNIT_PATH_SHOW_TXT = "Show this unit's intended path.",
        BTN_UNIT_PATH_HIDE_TXT = "Hide this unit's intended path.",
        BTN_UNIT_TRACKS_HEADER = "TOGGLE FOOTPRINTS: {1}",
        BTN_UNIT_TRACKS_SHOW_TXT = "Show this unit's recent footprints.",
        BTN_UNIT_TRACKS_HIDE_TXT = "Hide this unit's footprints path.",
        HOVER_VISION = "VISION: {1}",
        HOVER_EFFECT = "EFFECT: {1}",
        PULSE_EFFECT = "PULSE SCANNER: {1}",
        HOVER_INTEREST = "INTEREST: {1}",

        MAP_TRAVEL_TIME = "{1}{1:h|h}",

        OPTIONS_KEYBIND_CATEGORY = "MOD - UI TWEAKS RELOADED",
        OPTIONS_KEYBIND_VISIONMODE = "TOGGLE INFO MODE",
        OPTIONS_KEYBIND_CYCLE_PATH_FOOTPRINT = "CYCLE PATH/TRAIL VISIBILITY",
        BTN_RESET_OPTIONS = "RESET TO DEFAULTS",
        CAMPAIGN_WARNING = "Requires a new campaign.",
        RELOAD_WARNING = "Some options may require reloading\nfrom the main menu to apply.",

        OVERWATCH_WARNING_CLOAK_TT = "Cloak-piercing guards may react.",
    },
}

return UI_TWEAKS_STRINGS
