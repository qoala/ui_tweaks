local array = include("modules/array")

local preciseApMods = {
    {
        "hud.lua",
        {"skins", 1, "children"}, -- TeamItem (left-side agent list)
        {
            -- Shift AP elements right for Precise AP
            [4] = { -- apNum
                x = -10 + 5,
            },
            [5] = { -- apTxt
                x = 12 + 5,
            },
        },
    },
}

local modifications = {}
array.concat(modifications, preciseApMods)
return modifications
