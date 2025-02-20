local simquery = include("sim/simquery")
local simactions = include("sim/simactions")
local moveBody = include("sim/abilities/moveBody")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

local oldCanModifyExit = simquery.canModifyExit

function simquery.canModifyExit(unit, exitop, cell, dir)
    local canModify, reason = oldCanModifyExit(unit, exitop, cell, dir)

    -- doorsWhileDragging is sim-incompatible if reloaded in a play session without UITR installed.
    -- Require that the mod be enabled in the save file.
    local uiTweaks = unit:getSim():getParams().difficultyOptions.uiTweaks
    if not (uiTweaks and uitr_util.checkOption("doorsWhileDragging")) then
        return canModify, reason
    end

    if canModify == false and reason == STRINGS.UI.DOORS.DROP_BODY then
        if moveBody:canUseAbility(unit._sim, unit, unit, unit:getTraits().movingBody:getID()) then
            local body = unit:getTraits().movingBody
            unit:getTraits().movingBody = nil
            canModify, reason = oldCanModifyExit(unit, exitop, cell, dir)
            unit:getTraits().movingBody = body
        end
    end

    return canModify, reason
end

local oldUseDoorAction = simactions.useDoorAction

function simactions.useDoorAction(sim, exitOp, unitID, x0, y0, facing)
    -- Always attempt body-handling if the campaign has UITR enabled.
    -- This allows toggling doorsWhileDragging off mid-mission while still preserving a valid simhistory.
    local uiTweaks = sim:getParams().difficultyOptions.uiTweaks
    if not uiTweaks then
        return oldUseDoorAction(sim, exitOp, unitID, x0, y0, facing)
    end

    local unit = sim:getUnit(unitID)
    local body = unit:getTraits().movingBody

    if body then
        -- drop body
        moveBody:executeAbility(sim, unit, unit, body:getID())
    end

    -- open door
    local retVal = oldUseDoorAction(sim, exitOp, unitID, x0, y0, facing)

    if body and unit and body:isValid() and moveBody:canUseAbility(sim, unit, unit, body:getID()) then
        -- pick up again
        moveBody:executeAbility(sim, unit, unit, body:getID())
    end

    return retVal
end
