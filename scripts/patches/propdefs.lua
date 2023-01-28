local util = include("modules/util")

propdefsCoverTest = {
	AnimTest_cover_1_1 = {
        type = "simunit",
        name = "UITR DEBUG cover 1x1",
        onWorldTooltip = function() end,
        kanim = "kanim_office_1x1_side_table",
        traits = {cover = true, impass = {0, 0}},
        sounds = {appeared = "SpySociety/HUD/gameplay/peek_negative"},
        rig = "uitrdebug_decorig",
    },
	AnimTest_cover_1_2 = {
        type = "simunit",
        name = "UITR DEBUG cover 1x1",
        onWorldTooltip = function() end,
        kanim = "kanim_office_2x1_Bookshelf",
        traits = {cover = true, impass = {0, 0}},
        sounds = {appeared = "SpySociety/HUD/gameplay/peek_negative"},
        rig = "uitrdebug_decorig",
    },

    AnimTest_noncover_1_1 = {
        type = "simunit",
        name = "UITR DEBUG non-cover 1x1",
        onWorldTooltip = function() end,
        kanim = "uitr_test_non_1_1",
        traits = {cover = true, impass = {0, 0}},
        sounds = {appeared = "SpySociety/HUD/gameplay/peek_negative"},
        rig = "uitrdebug_decorig",
    },
    AnimTest_noncover_1_2 = {
        type = "simunit",
        name = "UITR DEBUG non-cover 1x2",
        onWorldTooltip = function() end,
        kanim = "uitr_test_non_1_2",
        traits = {cover = true, impass = {0, 0}},
        sounds = {appeared = "SpySociety/HUD/gameplay/peek_negative"},
        rig = "uitrdebug_decorig",
    },
    AnimTest_noncover_2_3 = {
        type = "simunit",
        name = "UITR DEBUG non-cover 2x3",
        onWorldTooltip = function() end,
        kanim = "uitr_test_non_2_3",
        traits = {cover = true, impass = {0, 0}},
        sounds = {appeared = "SpySociety/HUD/gameplay/peek_negative"},
        rig = "uitrdebug_decorig",
    },

    AnimTest_tall_1_1 = {
        type = "simunit",
        name = "UITR DEBUG tall cover 1x1",
        onWorldTooltip = function() end,
        kanim = "uitr_test_tall_1_1",
        traits = {cover = true, impass = {0, 0}},
        sounds = {appeared = "SpySociety/HUD/gameplay/peek_negative"},
        rig = "uitrdebug_decorig",
    },
    AnimTest_tall_1_2 = {
        type = "simunit",
        name = "UITR DEBUG tall cover 1x2",
        onWorldTooltip = function() end,
        kanim = "uitr_test_tall_1_2",
        traits = {cover = true, impass = {0, 0}},
        sounds = {appeared = "SpySociety/HUD/gameplay/peek_negative"},
        rig = "uitrdebug_decorig",
    },
    AnimTest_tall_noncover_1_1 = {
        type = "simunit",
        name = "UITR DEBUG tall noncover 1x1",
        onWorldTooltip = function() end,
        kanim = "uitr_test_tall_non_1_1",
        traits = {cover = true, impass = {0, 0}},
        sounds = {appeared = "SpySociety/HUD/gameplay/peek_negative"},
        rig = "uitrdebug_decorig",
    },
}

return {propdefsCoverTest = propdefsCoverTest}
