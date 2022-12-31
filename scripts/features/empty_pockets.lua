local array = include("modules/array")
local util = include("modules/util")
local simactions = include("sim/simactions")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

-- ==============
-- sim/simactions
-- ==============

local oldSearch = simactions.search

function simactions.search(sim, unitID, searchTypeAnarchy5, ...)
    oldSearch(sim, unitID, searchTypeAnarchy5, ...)

    if uitr_util.checkOption("emptyPockets") then
        local unit = sim:getUnit(unitID)

        -- Repeat the check for stealable items
        local inventoryCount = unit:getInventoryCount()
        if searchTypeAnarchy5 then
            for i, child in ipairs(unit:getChildren()) do
                if child:getTraits().anarchySpecialItem and child:hasAbility("carryable") then
                    inventoryCount = inventoryCount - 1
                end
            end
        end
        local hasLoot = (simquery.calculateCashOnHand(sim, unit) > 0 or
                                simquery.calculatePWROnHand(sim, unit) > 0 or inventoryCount > 0)

        if not hasLoot then
            sim:dispatchEvent(
                    simdefs.EV_UNIT_FLOAT_TXT, {
                        txt = STRINGS.UITWEAKSR.UI.NO_LOOT,
                        unit = unit,
                        color = {r = 1, g = 1, b = 1, a = 1},
                    })
        end
    end
end

-- ============
-- sim/simquery
-- ============

-- Searching the target will either produce lootable goods or new information on its absence.
function simquery._uit_searchIsValuable(sim, unit, targetUnit)
    if (simquery.isAgent(targetUnit) or targetUnit:getTraits().iscorpse) and
            not targetUnit:getTraits().MM_unsearchable then
        -- Player expects the target to potentially have an inventory.
        -- Has target never been searched?
        if not targetUnit:getTraits().searched then
            return true
        end
        -- Has target never been expertly searched?
        if unit:getTraits().anarchyItemBonus and not targetUnit:getTraits().searchedAnarchy5 then
            return true
        end
    end

    -- Does target have something we can steal?
    -- (UIT: vanilla check from canLoot starts here)
    local inventoryCount = targetUnit:getInventoryCount()
    if not unit:getTraits().anarchyItemBonus then
        for i, child in ipairs(targetUnit:getChildren()) do
            if child:getTraits().anarchySpecialItem and child:hasAbility("carryable") then
                inventoryCount = inventoryCount - 1
            end
        end
    end

    if not unit:getTraits().largeSafeMapIntel then
        for i, child in ipairs(targetUnit:getChildren()) do
            if child:getTraits().largeSafeMapIntel and child:hasAbility("carryable") then
                inventoryCount = inventoryCount - 1
            end
        end
    end
    return (simquery.calculateCashOnHand(sim, targetUnit) > 0 or
                   simquery.calculatePWROnHand(sim, targetUnit) > 0 or inventoryCount > 0)
end

local oldCanLoot = simquery.canLoot

-- Modified copy of vanilla simquery.canLoot
-- Changes at 'UIT:'
function simquery.canLoot(sim, unit, targetUnit, ...)
    if not uitr_util.checkOption("emptyPockets") then
        return oldCanLoot(sim, unit, targetUnit, ...)
    end

    if unit:getTraits().isDrone then
        return false
    end

    if targetUnit == nil or targetUnit:isGhost() then
        return false
    end

    if not unit:canAct() then
        return false
    end

    if unit:getTraits().movingBody == targetUnit then
        return false
    end

    if not targetUnit:getTraits().iscorpse then
        if simquery.isEnemyTarget(unit:getPlayerOwner(), targetUnit) then
            if not targetUnit:isKO() and not unit:hasSkill("anarchy", 2) then
                return false
            end

            if not targetUnit:isKO() and sim:canUnitSeeUnit(targetUnit, unit) then
                return false
            end
        else
            if not targetUnit:isKO() then
                return false
            end
        end
    end

    -- UIT: Extracted method. Considers additional factors valuable to search.
    if not simquery._uit_searchIsValuable(sim, unit, targetUnit) then
        return false
    end

    local cell = sim:getCell(unit:getLocation())
    local found = (cell == sim:getCell(targetUnit:getLocation()))
    for simdir, exit in pairs(cell.exits) do
        if simquery.isOpenExit(exit) then
            found = found or array.find(exit.cell.units, targetUnit) ~= nil
        end
    end
    if not found then
        return false, STRINGS.UI.REASON.CANT_REACH
    end

    return true
end
