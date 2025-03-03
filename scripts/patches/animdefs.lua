local commondefs = include("sim/unitdefs/commondefs")

local Layer = commondefs.Layer
local BoundType = commondefs.BoundType

local function abld(file)
    return file .. ".abld"
end
local function adef(file)
    return file .. ".adef"
end

-------------------------------------------------------------------
-- Data for anim definitions.
--
-- For items that do not in fact provide cover, or block sight, custom anims are substituted for tactical view.

-- Pure graphical fixes (does not use tall/non-cover anims)
local animdefsFixup = {
    -- Remove incorrect 1x1 cover anim.
    publicterminal_glasswall1 = {
        build = {"data/anims/Unique_publicterminal/publicterminal_glasswall1.abld"},
        anims = {"data/anims/Unique_publicterminal/publicterminal_glasswall1.adef"},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.Wall,
    },

    -- Remove incorrect 1x1 cover anim.
    holdingcell_1x1_celldoor1 = {
        build = {"data/anims/Unique_holdingcell/holdingcell_1x1_celldoor1.abld"},
        anims = {"data/anims/Unique_holdingcell/holdingcell_1x1_celldoor1.adef"},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.Wall,
    },

    -- ===
    -- OMNI
    -- ===

    -- Fix BoundType.Wall2 on 1-tile prop.
    decor_holostorage_1x1_wallgear2 = {
        build = {"data/anims/Final_holostorage/holostorage_1x1_wallgear2.abld"},
        anims = {"data/anims/Final_holostorage/holostorage_1x1_wallgear2.adef"},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.Wall,
        filterSymbols = {{symbol = "light", filter = "default"}},
    },

    decor_holostorage_1x1_wallgear3 = {
        build = {"data/anims/Final_holostorage/holostorage_1x1_wallgear3.abld"},
        anims = {"data/anims/Final_holostorage/holostorage_1x1_wallgear3.adef"},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.Wall,
        filterSymbols = {{symbol = "light", filter = "default"}},
    },

    -- ===
    -- Mod-only (not used by vanilla game)
    -- ===

    -- Tall-cover, missing its tactical anim. Fixed below in the tactical list.
    -- ftm_hall_bookshelf =
    -- {
    -- 	build = { "data/anims/FTM_hall/ftm_hall_object_2x1bookshelf.abld", "data/anims/general/mf_coverpieces_1x2.abld" },
    -- 	anims = { "data/anims/FTM_hall/ftm_hall_object_2x1bookshelf.adef", "data/anims/general/mf_coverpieces_1x2.adef" },
    -- 	symbol = "character",
    -- 	scale = 0.25,
    -- 	layer = Layer.Object,
    -- 	boundType = BoundType.bound_2x1_med_med,
    -- 	filterSymbols = {{symbol="icon",filter="default"},{symbol="light",filter="default"}},
    -- },

    -- Normal cover, missing its tactical anim.
    ftm_hall_couch1 = {
        build = {
            "data/anims/FTM_hall/ftm_hall_object_2x1couch1.abld",
            "data/anims/general/mf_coverpieces_1x2.abld",
        },
        anims = {
            "data/anims/FTM_hall/ftm_hall_object_2x1couch1.adef",
            "data/anims/general/mf_coverpieces_1x2.adef",
        },
        symbol = "character",
        scale = 0.25,
        layer = Layer.Object,
        boundType = BoundType.bound_2x1_med_med,
        filterSymbols = {
            {symbol = "icon", filter = "default"},
            {symbol = "light", filter = "default"},
        },
    },
}

-- Non-cover and Sightblock tactical DECOR --
local NONCOVER_1_1 = "data/anims/uitr/cover/mf_noncover_1x1"
local NONCOVER_1_2 = "data/anims/uitr/cover/mf_noncover_1x2"
local NONCOVER_2_3 = "data/anims/uitr/cover/mf_noncover_2x3"
local TALL_1_1 = "data/anims/uitr/cover/mf_tallcoverpieces_1x1"
local TALL_1_2 = "data/anims/uitr/cover/mf_tallcoverpieces_1x2"
local TALL_NONCOVER_1_1 = "data/anims/uitr/cover/mf_tallnoncover_1x1"
local animdefsTactical = {

    -- FTM OFFICE --------------------------------------------------------------------------------------------

    ftm_hall_plant1 = {
        build = {"data/anims/FTM_hall/ftm_hall_object_1x1plant1.abld", abld(TALL_1_1)},
        anims = {"data/anims/FTM_hall/ftm_hall_object_1x1plant1.adef", adef(TALL_1_1)},
        symbol = "character",
        scale = 0.25,
        layer = Layer.Object,
        boundType = BoundType.bound_1x1_med_med,
        filterSymbols = {{symbol = "icon", filter = "default"}},
    },

    ftm_hall_plant2 = {
        build = {"data/anims/FTM_hall/ftm_hall_object_1x1plant2.abld", abld(TALL_1_1)},
        anims = {"data/anims/FTM_hall/ftm_hall_object_1x1plant2.adef", adef(TALL_1_1)},
        symbol = "character",
        scale = 0.25,
        layer = Layer.Object,
        boundType = BoundType.bound_1x1_med_med,
        filterSymbols = {{symbol = "icon", filter = "default"}},
    },

    -- FTM LAB -----------------------------------------------------------------------------------------------

    ftm_lab_closet1 = {
        build = {"data/anims/FTM_lab/ftm_lab_object_1x1closet1.abld", abld(TALL_1_1)},
        anims = {"data/anims/FTM_lab/ftm_lab_object_1x1closet1.adef", adef(TALL_1_1)},
        symbol = "character",
        scale = 0.25,
        layer = Layer.Object,
        boundType = BoundType.bound_1x1_med_med,
        filterSymbols = {{symbol = "icon", filter = "default"}},
    },

    -- FTM SECURITY ------------------------------------------------------------------------------------------

    ftm_security_1x1locker = {
        build = {"data/anims/FTM_security/ftm_security_object_1x1locker.abld", abld(TALL_1_1)},
        anims = {"data/anims/FTM_security/ftm_security_object_1x1locker.adef", adef(TALL_1_1)},
        symbol = "character",
        scale = 0.25,
        layer = Layer.Object,
        boundType = BoundType.bound_1x1_tall_med,
        filterSymbols = {{symbol = "icon", filter = "default"}},
    },

    -- KO OFFICE ---------------------------------------------------------------------------------------------

    decor_ko_office_flag1 = {
        build = {"data/anims/KO_office/ko_office_decor_flag1.abld", abld(NONCOVER_1_1)},
        anims = {"data/anims/KO_office/ko_office_decor_flag1.adef", adef(NONCOVER_1_1)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_med_med,
    },

    decor_ko_office_lamp = {
        build = {"data/anims/KO_office/ko_office_decor_lamp1.abld", abld(NONCOVER_1_1)},
        anims = {"data/anims/KO_office/ko_office_decor_lamp1.adef", adef(NONCOVER_1_1)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_tall_med,
    },

    decor_ko_office_bookshelf1 = {
        build = {"data/anims/KO_office/ko_office_object_2x1bookshelf1.abld", abld(TALL_1_2)},
        anims = {"data/anims/KO_office/ko_office_object_2x1bookshelf1.adef", adef(TALL_1_2)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_2x1_tall_med,
    },

    decor_ko_office_bookshelf2 = {
        build = {"data/anims/KO_office/ko_office_object_2x1bookshelf2.abld", abld(TALL_1_2)},
        anims = {"data/anims/KO_office/ko_office_object_2x1bookshelf2.adef", adef(TALL_1_2)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_2x1_tall_med,
    },

    decor_ko_office_cabinet1 = {
        build = {"data/anims/KO_office/ko_office_object_2x1tvcabinet1.abld", abld(TALL_1_2)},
        anims = {"data/anims/KO_office/ko_office_object_2x1tvcabinet1.adef", adef(TALL_1_2)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_2x1_tall_med,
    },

    -- KO LAB ---------------------------------------------------------------------------------------------

    decor_ko_lab_tallcase1 = {
        build = {"data/anims/KO_lab/ko_lab_object_1x1tallcase1.abld", abld(TALL_1_1)},
        anims = {"data/anims/KO_lab/ko_lab_object_1x1tallcase1.adef", adef(TALL_1_1)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_tall_med,
    },

    decor_ko_lab_pit1 = {
        build = {"data/anims/KO_lab/ko_lab_object_2x3pit1.abld", abld(NONCOVER_2_3)},
        anims = {"data/anims/KO_lab/ko_lab_object_2x3pit1.adef", adef(NONCOVER_2_3)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.Floor_2x3,
    },

    decor_ko_lab_pit2 = {
        build = {"data/anims/KO_lab/ko_lab_object_2x3pit2.abld", abld(NONCOVER_2_3)},
        anims = {"data/anims/KO_lab/ko_lab_object_2x3pit2.adef", adef(NONCOVER_2_3)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.Floor_2x3,
    },

    -- KO BARRACKS ---------------------------------------------------------------------------------------------

    decor_ko_barracks_fridge1 = {
        build = {"data/anims/KO_Barracks/ko_barracks_object_1x1fridge1.abld", abld(TALL_1_1)},
        anims = {"data/anims/KO_Barracks/ko_barracks_object_1x1fridge1.adef", adef(TALL_1_1)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_tall_med,
    },

    decor_ko_barracks_vendingmachine1 = {
        build = {
            "data/anims/KO_Barracks/ko_barracks_object_1x1vendingmachine1.abld",
            abld(TALL_1_1),
        },
        anims = {
            "data/anims/KO_Barracks/ko_barracks_object_1x1vendingmachine1.adef",
            adef(TALL_1_1),
        },
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_tall_med,
    },

    -- KO HALL ---------------------------------------------------------------------------------------------

    decor_ko_hall_bookshelf1 = {
        build = {"data/anims/KO_Hall/ko_hall_object_2x1bookshelf1.abld", abld(TALL_1_2)},
        anims = {"data/anims/KO_Hall/ko_hall_object_2x1bookshelf1.adef", adef(TALL_1_2)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_2x1_tall_med,
    },

    -- SEIKAKU LAB ---------------------------------------------------------------------------------------------

    decor_sk_office_shelf1 = {
        build = {"data/anims/Seikaku_office/seikaku_office_object_1x1shelf1.abld", abld(TALL_1_1)},
        anims = {"data/anims/Seikaku_office/seikaku_office_object_1x1shelf1.adef", adef(TALL_1_1)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_tall_med,
    },

    decor_sk_office_walldivider1 = {
        build = {
            "data/anims/Seikaku_office/seikaku_office_object_1x1walldivider.abld",
            abld(TALL_NONCOVER_1_1),
        },
        anims = {
            "data/anims/Seikaku_office/seikaku_office_object_1x1walldivider.adef",
            adef(TALL_NONCOVER_1_1),
        },
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_med_med,
    },

    decor_sk_office_tv1 = {
        build = {"data/anims/Seikaku_office/seikaku_office_object_2x1tv.abld", abld(TALL_1_2)},
        anims = {"data/anims/Seikaku_office/seikaku_office_object_2x1tv.adef", adef(TALL_1_2)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_2x1_tall_med,
    },

    decor_sk_bay_tallcrate1 = {
        build = {
            "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1tallcrate.abld",
            abld(TALL_1_1),
        },
        anims = {
            "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1tallcrate.adef",
            adef(TALL_1_1),
        },
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_tall_med,
    },

    decor_plastek_psilab_cabinet1 = {
        build = {"data/anims/Plastek_psilab/plastek_psilab_object_1x1cabinet1.abld", abld(TALL_1_1)},
        anims = {"data/anims/Plastek_psilab/plastek_psilab_object_1x1cabinet1.adef", adef(TALL_1_1)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_tall_med,
    },

    decor_plastek_psilab_bookshelf1 = {
        build = {
            "data/anims/Plastek_psilab/plastek_psilab_object_2x1bookshelf1.abld",
            abld(TALL_1_2),
        },
        anims = {
            "data/anims/Plastek_psilab/plastek_psilab_object_2x1bookshelf1.adef",
            adef(TALL_1_2),
        },
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_2x1_tall_med,
    },

    decor_plastek_lab_cabinet1 = {
        build = {"data/anims/Plastek_Lab/plastek_lab_object_1x1cabinet1.abld", abld(TALL_1_1)},
        anims = {"data/anims/Plastek_Lab/plastek_lab_object_1x1cabinet1.adef", adef(TALL_1_1)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_med_med,
    },

    decor_plastek_hall_bookshelf1 = {
        build = {"data/anims/Plastek_hall/plastek_hall_object_1x1bookshelf1.abld", abld(TALL_1_1)},
        anims = {"data/anims/Plastek_hall/plastek_hall_object_1x1bookshelf1.adef", adef(TALL_1_1)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_tall_med,
    },

    decor_plastek_hall_bookshelf2 = {
        build = {"data/anims/Plastek_hall/plastek_hall_object_2x1bookshelf2.abld", abld(TALL_1_2)},
        anims = {"data/anims/Plastek_hall/plastek_hall_object_2x1bookshelf2.adef", adef(TALL_1_2)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_2x1_tall_med,
    },

    decor_cybernetics_object_2x1liquidpool1 = {
        build = {
            "data/anims/Unique_cybernetics/cybernetics_2x1_liquidpool1.abld",
            abld(NONCOVER_1_2),
        },
        anims = {
            "data/anims/Unique_cybernetics/cybernetics_2x1_liquidpool1.adef",
            adef(NONCOVER_1_2),
        },
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_2x1_med_med,
    },

    -- Mod-only --------------------------------------------------------------------------------------------

    -- Actually tall-cover, missing its tactical anim.
    ftm_hall_bookshelf = {
        build = {"data/anims/uitr/props/ftm_hall_object_2x1bookshelf.abld", abld(TALL_1_2)},
        anims = {"data/anims/uitr/props/ftm_hall_object_2x1bookshelf.adef", adef(TALL_1_2)},
        symbol = "character",
        scale = 0.25,
        layer = Layer.Object,
        boundType = BoundType.bound_2x1_med_med,
        filterSymbols = {
            {symbol = "icon", filter = "default"},
            {symbol = "light", filter = "default"},
        },
    },
}

local animdefsCoverTest = {
    uitr_test_non_1_1 = {
        build = {"data/anims/KO_office/ko_office_decor_lamp1.abld", abld(NONCOVER_1_1)},
        anims = {"data/anims/KO_office/ko_office_decor_lamp1.adef", adef(NONCOVER_1_1)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_tall_med,
    },
    uitr_test_non_1_2 = {
        build = {
            "data/anims/Unique_cybernetics/cybernetics_2x1_liquidpool1.abld",
            abld(NONCOVER_1_2),
        },
        anims = {
            "data/anims/Unique_cybernetics/cybernetics_2x1_liquidpool1.adef",
            adef(NONCOVER_1_2),
        },
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_2x1_med_med,
    },
    uitr_test_non_2_3 = {
        build = {"data/anims/KO_lab/ko_lab_object_2x3pit1.abld", abld(NONCOVER_2_3)},
        anims = {"data/anims/KO_lab/ko_lab_object_2x3pit1.adef", adef(NONCOVER_2_3)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.Floor_2x3,
    },

    uitr_test_tall_1_1 = {
        build = {"data/anims/FTM_hall/ftm_hall_object_1x1plant1.abld", abld(TALL_1_1)},
        anims = {"data/anims/FTM_hall/ftm_hall_object_1x1plant1.adef", adef(TALL_1_1)},
        symbol = "character",
        scale = 0.25,
        layer = Layer.Object,
        boundType = BoundType.bound_1x1_med_med,
        filterSymbols = {{symbol = "icon", filter = "default"}},
    },
    uitr_test_tall_1_2 = {
        build = {"data/anims/KO_office/ko_office_object_2x1bookshelf1.abld", abld(TALL_1_2)},
        anims = {"data/anims/KO_office/ko_office_object_2x1bookshelf1.adef", adef(TALL_1_2)},
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_2x1_tall_med,
    },
    uitr_test_tall_non_1_1 = {
        build = {
            "data/anims/Seikaku_office/seikaku_office_object_1x1walldivider.abld",
            abld(TALL_NONCOVER_1_1),
        },
        anims = {
            "data/anims/Seikaku_office/seikaku_office_object_1x1walldivider.adef",
            adef(TALL_NONCOVER_1_1),
        },
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.bound_1x1_med_med,
    },
}

return {
    animdefsFixup = animdefsFixup,
    animdefsTactical = animdefsTactical,
    animdefsCoverTest = animdefsCoverTest,
}
