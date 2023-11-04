local array = include("modules/array")

local function patchNeptunePrefabs()
    -- The 1x2 couch anim was encoded with only 1 tile of impass+cover.
    -- Shirsh Mod Combo uses the same anim but with the correct tiles.
    -- Replace the anim in Neptune with a corresponding 1x1 anim to match the tile.
    local hall3x4 = include(SCRIPT_PATHS.corp_neptune .. [[/prefabs/neptune/decor_hall_int_3x4]])
    local couchDeco = array.findIf(
            hall3x4.decos, function(d)
                return d.x == 1 and d.y == 3 and d.facing == 6 and d.kanim == [[ftm_hall_couch1]]
            end)
    local nextTile = array.findIf(
            hall3x4.tiles, function(t)
                return t.x == 2 and t.y == 3
            end)
    if couchDeco and nextTile and not nextTile.impass then
        couchDeco.kanim = [[ftm_hall_chair1]]
    end
end

return { --
    patchNeptunePrefabs = patchNeptunePrefabs,
}
