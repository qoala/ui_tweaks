local simplayer = include("sim/simplayer")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

-- ===

local OLD_FN_MAPPING = {markSeen = simplayer.markSeen, glimpseUnit = simplayer.glimpseUnit}
local NEW_KEYS = {"getUITRKnownBounds", "_updateUITRKnownBounds"}
simplayer._uitrmeta_simplayerKnownBounds = true

local oldInit = simplayer.init
function simplayer:init(...)
    uitr_util.propagateSuperclass(
            getmetatable(self), simplayer, OLD_FN_MAPPING, NEW_KEYS,
            "_uitrmeta_simplayerKnownBounds")

    oldInit(self, ...)
end

function simplayer:getUITRKnownBounds()
    return self._uitr_minKnownX, self._uitr_minKnownY, self._uitr_maxKnownX, self._uitr_maxKnownY
end

function simplayer:_updateUITRKnownBounds(cellx, celly)
    -- Track min/max known cell coordinates.
    if not self._uitr_minKnownX and cellx then
        self._uitr_minKnownX = cellx
        self._uitr_maxKnownX = cellx
        self._uitr_minKnownY = celly
        self._uitr_maxKnownY = celly
    elseif cellx then
        self._uitr_minKnownX = math.min(self._uitr_minKnownX, cellx)
        self._uitr_maxKnownX = math.max(self._uitr_maxKnownX, cellx)
        self._uitr_minKnownY = math.min(self._uitr_minKnownY, celly)
        self._uitr_maxKnownY = math.max(self._uitr_maxKnownY, celly)
    end
end

local oldMarkSeen = simplayer.markSeen
function simplayer:markSeen(sim, cellx, celly, ...)
    self:_updateUITRKnownBounds(cellx, celly)
    return oldMarkSeen(self, sim, cellx, celly, ...)
end

local oldGlimpseUnit = simplayer.glimpseUnit
function simplayer:glimpseUnit(sim, unitID, ...)
    local unit = sim:getUnit(unitID)
    if unit and unit:getLocation() then
        self:_updateUITRKnownBounds(unit:getLocation())
    end

    return oldGlimpseUnit(self, sim, unitID, ...)
end
