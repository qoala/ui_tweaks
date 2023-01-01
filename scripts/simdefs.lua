local simdefs = include("sim/simdefs")

-- Modes for area targeting handlers. Determines how 'range' is applied to calculate affected cells.
simdefs.TARGETAREA_GEOMETRIC = 1 -- Standard (raster) circle using geometric distance. (Default)
simdefs.TARGETAREA_FLOOD_GEOMETRIC = 2 -- Flood-fill area using geometric distance.
simdefs.TARGETAREA_FLOOD_MANHATTAN = 3 -- Flood-fill area using Manhattan distance.
