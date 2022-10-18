local UI_TWEAKS_STRINGS =
{
	OPTIONS = {
		VANILLA = "OFF/VANILLA",

		PRECISE_AP = "Precise AP",
		PRECISE_AP_TIP = "Round AP to .5 instead of whole number",
		PRECISE_AP_HALF = "0.5",
		PRECISE_ICONS = "Precise Icons",
		PRECISE_ICONS_TIP = "Label stim, paralyzer, cloak, etc with the different level of item",
		COLORED_TRACKS = "Yes, We Are All Individuals!",
		COLORED_TRACKS_TIP = "Guards get uniquely colored tracks and interest points",
		COLORED_TRACKS_A = "PALETTE A",

		EMPTY_POCKETS = "Their Pockets Were Empty",
		EMPTY_POCKETS_TIP = "Agents can attempt to steal if it would newly reveal that the target isn't carrying anything.\nAllows marking targets as Searched and Expertly Searched.",
		INV_DRAGDROP = "Inventory Drag/Drop Reordering",
		INV_DRAGDROP_TIP = "Allow drag & drop to reorder an agent's inventory\n  (between missions)",
		DOORS_WHILE_DRAGGING = "Lay That Body Down, Boy",
		DOORS_WHILE_DRAGGING_TIP = "Allow door manipulation while dragging bodies",
		STEP_CAREFULLY = "Step Carefully, Now",
		STEP_CAREFULLY_TIP = "Agents prefer to avoid watched/noticed tiles, while still choosing a path with the shortest distance",

		OVERWATCH_MOVEMENT_WARNINGS = "Overwatch movement warnings",
		OVERWATCH_MOVEMENT_WARNINGS_TIP = "Warning tiles appear on the floor if movement will trigger overwatch.",
		OVERWATCH_ABILITY_WARNINGS = "Overwatch ability warnings",
		OVERWATCH_ABILITY_WARNINGS_TIP = "Ability tooltips warn if the ability can trigger overwatch.",

		SELECTION_FILTER_AGENT = "Selected Agent Highlight",
		SELECTION_FILTER_AGENT_TIP = "Selected agent is highlighted in a bright color of your choice.",
		SELECTION_FILTER_AGENT_COLORS = {"OFF/VANILLA", "CYAN", "BLUE","GREEN", "PURPLE", "SOLID CYAN", "SOLID BLUE","SOLID GREEN", "SOLID PURPLE"},
		SELECTION_FILTER_AGENT_TACTICAL = "    Tactical Only",
		SELECTION_FILTER_AGENT_TACTICAL_TIP = "Selected agent highlight is only applied in tactical view.",
		SELECTION_FILTER_TILE = "Selected Agent Floor Highlight",
		SELECTION_FILTER_TILE_TIP = "Selected agent's tile is highlighted in a bright color of your choice.",
		SELECTION_FILTER_TILE_COLORS = {"OFF/VANILLA", "WHITE", "CYAN", "BLUE"},
	},

	UI =
	{
		NO_LOOT = "NO LOOT",

		BTN_VISIONMODE_HEADER = "VISION MODE",
		BTN_VISIONMODE_ENABLE_TXT = "Enable vision mode.",
		BTN_VISIONMODE_DISABLE_TXT = "Disable vision mode.",
		BTN_UNITVISION_HEADER = "TOGGLE VISION: {1}",
		BTN_UNITVISION_SHOW_TXT = "Show this unit's vision.",
		BTN_UNITVISION_HIDE_TXT = "Hide this unit's vision.",
		HOVER_VISION = "VISION: {1}",
		HOVER_EFFECT = "EFFECT: {1}",
		PULSE_EFFECT = "PULSE SCANNER: {1}",

		OPTIONS_KEYBIND_CATEGORY = "MOD - UI TWEAKS RELOADED",
		OPTIONS_KEYBIND_VISIONMODE = "TOGGLE VISION MODE",
		BTN_RESET_OPTIONS = "RESET TO DEFAULTS",
		RELOAD_WARNING = "Some options may require reloading\nfrom the main menu to apply.",
	},
}

return UI_TWEAKS_STRINGS
