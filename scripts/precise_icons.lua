
local itemdefs = include ( "sim/unitdefs/itemdefs" )

local function patchItem(item, icon_prefix, enabled)
	icon_prefix = icon_prefix or item
	if not itemdefs[item] then
		error("tried to patch non-existant item " .. item)
	end
	if enabled then
		if not itemdefs[item].old_profile_icon_100 then
			itemdefs[item].old_profile_icon_100 = itemdefs[item].profile_icon_100
			itemdefs[item].old_profile_icon = itemdefs[item].profile_icon
		end
		itemdefs[item].profile_icon_100 = 'gui/icons/icon-' .. icon_prefix .. ".png"
		itemdefs[item].profile_icon = 'gui/icons/small/icon-' .. icon_prefix .. ".png"
	elseif (not enabled) and itemdefs[item].old_profile_icon_100 then
		itemdefs[item].profile_icon_100 = itemdefs[item].old_profile_icon_100
		itemdefs[item].profile_icon = itemdefs[item].old_profile_icon
	end
end

local patches = {
	'item_cloakingrig_1', 'item_cloakingrig_2', 'item_cloakingrig_3',
	'item_emp_pack', 'item_emp_pack_2', 'item_emp_pack_3',
	'item_icebreaker', 'item_icebreaker_2', 'item_icebreaker_3',
	'item_laptop', 'item_laptop_2', 'item_laptop_3',
	'item_paralyzer', 'item_paralyzer_2', 'item_paralyzer_3',
	'item_power_tazer_1', 'item_power_tazer_2', 'item_power_tazer_3',
	'item_shocktrap', 'item_shocktrap_2', 'item_shocktrap_3',
	'item_stim', 'item_stim_2', 'item_stim_3',
	'item_tazer', 'item_tazer_2', 'item_tazer_3'
}

local function patchItems(enabled)
	for i, p in ipairs(patches) do
		patchItem(p, nil, enabled)
	end

	patchItem('item_cloakingrig_3_17_5', 'item_cloakingrig_3', enabled)
	patchItem('item_shocktrap_3_17_9', 'item_shocktrap_3', enabled)
end

return {
	patchItems = patchItems,
}
