local Senses = include("sim/btree/senses")

local track_colors = include(SCRIPT_PATHS.qed_uitr .. "/features/track_colors")

local oldAddInterest = Senses.addInterest
function Senses:addInterest(...)
    local interest = oldAddInterest(self, ...)

    if interest and interest.alwaysDraw then
        track_colors.ensureUnitHasColor(self.unit)
    end

    return interest
end
