local simengine = include("sim/engine")

function simengine:uitr_resetAllUnitVision()
    -- Stop highlighting a single unit's vision (from hovering vision-mode abilities).
    self:getTags().uitr_oneVision = nil

    -- Clear all temporarily hidden visions (from clicking vision-mode abilities).
    for unitID, unit in pairs(self:getAllUnits()) do
        unit:getTraits().uitr_hideVision = nil
    end
end
