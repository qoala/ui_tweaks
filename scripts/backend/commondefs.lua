local commondefs = include("sim/unitdefs/commondefs")
local util = include("modules/util")
local simquery = include("sim/simquery")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

-- True if searching will produce lootable goods (similar to simquery._uit_searchIsValuable), but independent of agent skills.
function corpseHasLoot(targetUnit)
    local sim = targetUnit:getSim()
    local inventoryCount = targetUnit:getInventoryCount()
    local searchedAnarchy5 = targetUnit:getTraits().searchedAnarchy5
    for i, child in ipairs(targetUnit:getChildren()) do
        local traits = child:getTraits()
        if ((traits.anarchySpecialItem and not searchedAnarchy5) or traits.largeSafeMapIntel) and
                child:hasAbility("carryable") then
            inventoryCount = inventoryCount - 1
        end
    end
    return (simquery.calculateCashOnHand(sim, targetUnit) > 0 or
                   simquery.calculatePWROnHand(sim, targetUnit) > 0 or inventoryCount > 0)
end

-- Overwrite corpse_template.onWorldTooltip
-- UITR: Show 'loot corpse' tooltip only if the Steal action would be available.
--       Assumes no anarchy5, because the tooltip doesn't vary based on the selected unit.
-- UITR: Add 'searched' tooltips from onGuardTooltip.
commondefs.uitr_oldOnCorpseTooltip = commondefs.corpse_template.onWorldTooltip
function commondefs.corpse_template.onWorldTooltip(tooltip, unit)
    if not uitr_util.checkOption("corpsePockets") then
        return commondefs.uitr_oldOnCorpseTooltip(tooltip, unit)
    end

    tooltip:addLine(unit:getName())
    local traits = unit:getTraits()

    if corpseHasLoot(unit) then
        tooltip:addAbility(
                STRINGS.UI.ACTIONS.LOOT_CORPSE.NAME, STRINGS.UI.ACTIONS.LOOT_CORPSE.TOOLTIP,
                "gui/icons/arrow_small.png")
    end

    if unit:getTraits().neural_scanned then
        tooltip:addAbility(
                string.format(STRINGS.UI.TOOLTIPS.NEURAL_SCANNED),
                string.format(STRINGS.UI.TOOLTIPS.NEURAL_SCANNED_DESC), "gui/icons/arrow_small.png")
    end

    -- Searched tooltips from onGuardTooltip
    if traits.searchedAnarchy5 then
        tooltip:addAbility(
                string.format(STRINGS.UI.TOOLTIPS.SEARCHED_ADVANCED),
                util.sformat(STRINGS.UI.TOOLTIPS.SEARCHED_ADVANCED_DESC),
                "gui/icons/arrow_small.png")
    elseif traits.searched then
        tooltip:addAbility(
                string.format(STRINGS.UI.TOOLTIPS.SEARCHED),
                util.sformat(STRINGS.UI.TOOLTIPS.SEARCHED_DESC), "gui/icons/arrow_small.png")
    end
end
