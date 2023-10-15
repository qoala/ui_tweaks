local pcplayer = include("sim/pcplayer")

local track_colors = include(SCRIPT_PATHS.qed_uitr .. "/features/track_colors")

local oldAddSeenUnit = pcplayer.addSeenUnit
function pcplayer:addSeenUnit(unit, ...)
    oldAddSeenUnit(self, unit, ...)

    -- Initialize UI track color on sight.
    track_colors.ensureUnitHasColor(unit)
end
