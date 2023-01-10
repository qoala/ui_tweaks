local simdefs = include("sim/simdefs")

-- Modes for area targeting handlers. Determines how 'range' is applied to calculate affected cells.
simdefs.TARGETAREA_GEOMETRIC = 1 -- Standard (raster) circle using geometric distance. (Default)
simdefs.TARGETAREA_FLOOD_GEOMETRIC = 2 -- Flood-fill area using geometric distance.
simdefs.TARGETAREA_FLOOD_MANHATTAN = 3 -- Flood-fill area using Manhattan distance.

-- Fallback definitions if CBF is not present.
simdefs.DIRMASK_E = rawget(simdefs, "DIRMASK_E") or 1
simdefs.DIRMASK_NE = rawget(simdefs, "DIRMASK_NE") or 2
simdefs.DIRMASK_N = rawget(simdefs, "DIRMASK_N") or 4
simdefs.DIRMASK_NW = rawget(simdefs, "DIRMASK_NW") or 8
simdefs.DIRMASK_W = rawget(simdefs, "DIRMASK_W") or 16
simdefs.DIRMASK_SW = rawget(simdefs, "DIRMASK_SW") or 32
simdefs.DIRMASK_S = rawget(simdefs, "DIRMASK_S") or 64
simdefs.DIRMASK_SE = rawget(simdefs, "DIRMASK_SE") or 128
simdefs._DIRMASK_MAP = rawget(simdefs, "_DIRMASK_MAP") or {
    [simdefs.DIR_E] = simdefs.DIRMASK_E,
    [simdefs.DIR_NE] = simdefs.DIRMASK_NE,
    [simdefs.DIR_N] = simdefs.DIRMASK_N,
    [simdefs.DIR_NW] = simdefs.DIRMASK_NW,
    [simdefs.DIR_W] = simdefs.DIRMASK_W,
    [simdefs.DIR_SW] = simdefs.DIRMASK_SW,
    [simdefs.DIR_S] = simdefs.DIRMASK_S,
    [simdefs.DIR_SE] = simdefs.DIRMASK_SE,
}
if not rawget(simdefs, "maskFromDir") then
    function simdefs:maskFromDir(dir)
        return self._DIRMASK_MAP[dir]
    end
end
