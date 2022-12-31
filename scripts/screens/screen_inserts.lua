local inserts = {
    {
        "hud.lua",
        {"widgets", 16, "children"}, -- topPnl
        {
            name = [[btnToggleVisionMode]],
            isVisible = true,
            noInput = false,
            anchor = 1,
            rotation = 0,
            x = -122,
            xpx = true,
            y = -21,
            ypx = true,
            w = 45,
            wpx = true,
            h = 40,
            hpx = true,
            sx = 1,
            sy = 1,
            ctor = [[button]],
            clickSound = [[SpySociety/HUD/menu/click]],
            hoverSound = [[SpySociety/HUD/menu/rollover]],
            hoverScale = 1,
            halign = MOAITextBox.CENTER_JUSTIFY,
            valign = MOAITextBox.CENTER_JUSTIFY,
            text_style = [[]],
            images = {
                {
                    file = [[gui/hud3/UserButtons/uitr_btn_enable_visionmode.png]],
                    name = [[inactive]],
                },
                {
                    file = [[gui/hud3/UserButtons/uitr_btn_enable_visionmode_hl.png]],
                    name = [[hover]],
                },
                {
                    file = [[gui/hud3/UserButtons/uitr_btn_enable_visionmode_hl.png]],
                    name = [[active]],
                },
            },
        },
    },
    {
        "hud.lua",
        {"widgets", 5, "children"}, -- agentPanel
        {
            name = [[uitrNonVisionActionsGroup]],
            isVisible = false,
            noInput = false,
            anchor = 1,
            rotation = 0,
            x = -1,
            xpx = true,
            y = -1,
            ypx = true,
            w = 0,
            h = 0,
            sx = 1,
            sy = 1,
            ctor = [[group]],
            children = {
                {
                    name = [[uitrNonVisionDynaction1]],
                    isVisible = true,
                    noInput = false,
                    anchor = 1,
                    rotation = 0,
                    x = 0,
                    xpx = true,
                    y = 0,
                    ypx = true,
                    w = 0,
                    wpx = true,
                    h = 0,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[button]],
                    halign = MOAITextBox.CENTER_JUSTIFY,
                    valign = MOAITextBox.CENTER_JUSTIFY,
                    text_style = [[]],
                    images = {
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[inactive]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[hover]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[active]],
                        },
                    },
                },
                {
                    name = [[uitrNonVisionDynaction2]],
                    isVisible = true,
                    noInput = false,
                    anchor = 1,
                    rotation = 0,
                    x = 0,
                    xpx = true,
                    y = 0,
                    ypx = true,
                    w = 0,
                    wpx = true,
                    h = 0,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[button]],
                    halign = MOAITextBox.CENTER_JUSTIFY,
                    valign = MOAITextBox.CENTER_JUSTIFY,
                    text_style = [[]],
                    images = {
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[inactive]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[hover]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[active]],
                        },
                    },
                },
                {
                    name = [[uitrNonVisionDynaction3]],
                    isVisible = true,
                    noInput = false,
                    anchor = 1,
                    rotation = 0,
                    x = 0,
                    xpx = true,
                    y = 0,
                    ypx = true,
                    w = 0,
                    wpx = true,
                    h = 0,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[button]],
                    halign = MOAITextBox.CENTER_JUSTIFY,
                    valign = MOAITextBox.CENTER_JUSTIFY,
                    text_style = [[]],
                    images = {
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[inactive]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[hover]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[active]],
                        },
                    },
                },
                {
                    name = [[uitrNonVisionDynaction4]],
                    isVisible = true,
                    noInput = false,
                    anchor = 1,
                    rotation = 0,
                    x = 0,
                    xpx = true,
                    y = 0,
                    ypx = true,
                    w = 0,
                    wpx = true,
                    h = 0,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[button]],
                    halign = MOAITextBox.CENTER_JUSTIFY,
                    valign = MOAITextBox.CENTER_JUSTIFY,
                    text_style = [[]],
                    images = {
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[inactive]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[hover]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[active]],
                        },
                    },
                },
                {
                    name = [[uitrNonVisionDynaction5]],
                    isVisible = true,
                    noInput = false,
                    anchor = 1,
                    rotation = 0,
                    x = 0,
                    xpx = true,
                    y = 0,
                    ypx = true,
                    w = 0,
                    wpx = true,
                    h = 0,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[button]],
                    halign = MOAITextBox.CENTER_JUSTIFY,
                    valign = MOAITextBox.CENTER_JUSTIFY,
                    text_style = [[]],
                    images = {
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[inactive]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[hover]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[active]],
                        },
                    },
                },
                {
                    name = [[uitrNonVisionDynaction6]],
                    isVisible = true,
                    noInput = false,
                    anchor = 1,
                    rotation = 0,
                    x = 0,
                    xpx = true,
                    y = 0,
                    ypx = true,
                    w = 0,
                    wpx = true,
                    h = 0,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[button]],
                    halign = MOAITextBox.CENTER_JUSTIFY,
                    valign = MOAITextBox.CENTER_JUSTIFY,
                    text_style = [[]],
                    images = {
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[inactive]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[hover]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[active]],
                        },
                    },
                },
                {
                    name = [[uitrNonVisionDynaction7]],
                    isVisible = true,
                    noInput = false,
                    anchor = 1,
                    rotation = 0,
                    x = 0,
                    xpx = true,
                    y = 0,
                    ypx = true,
                    w = 0,
                    wpx = true,
                    h = 0,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[button]],
                    halign = MOAITextBox.CENTER_JUSTIFY,
                    valign = MOAITextBox.CENTER_JUSTIFY,
                    text_style = [[]],
                    images = {
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[inactive]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[hover]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[active]],
                        },
                    },
                },
                {
                    name = [[uitrNonVisionDynaction8]],
                    isVisible = true,
                    noInput = false,
                    anchor = 1,
                    rotation = 0,
                    x = 0,
                    xpx = true,
                    y = 0,
                    ypx = true,
                    w = 0,
                    wpx = true,
                    h = 0,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[button]],
                    halign = MOAITextBox.CENTER_JUSTIFY,
                    valign = MOAITextBox.CENTER_JUSTIFY,
                    text_style = [[]],
                    images = {
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[inactive]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[hover]],
                        },
                        {
                            file = [[gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png]],
                            name = [[active]],
                        },
                    },
                },
            },
        },
    },
    {
        "hud-inworld.lua",
        {"skins"},
        {
            name = [[MainframeLayoutLineLeader]],
            isVisible = true,
            noInput = false,
            anchor = 1,
            rotation = 0,
            x = 0,
            y = 0,
            w = 0,
            h = 0,
            sx = 1,
            sy = 1,
            ctor = [[group]],
            children = {
                {
                    name = [[line]],
                    isVisible = true,
                    noInput = true,
                    anchor = 1,
                    rotation = 0,
                    x = 0,
                    y = 0,
                    w = 16,
                    wpx = true,
                    h = 16,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[uitrMainframeLineLeader]],
                    images = {
                        {
                            file = [[uitr_mf_leader_circle.png]],
                            name = [[target]],
                            color = { --
                                1,
                                1,
                                1,
                                0.69803923368454,
                            },
                        },
                        { --
                            file = [[white.png]],
                            name = [[line]],
                            color = { --
                                1,
                                0,
                                0,
                                1,
                            },
                        },
                    },
                    lineWidth = 2,
                    targetx = 0.5,
                    targety = 0.2,
                },
            },
        },
    },
    {
        "hud-inworld.lua",
        {"skins"},
        {
            name = [[MainframeLayoutDebug]],
            isVisible = true,
            noInput = false,
            anchor = 1,
            rotation = 0,
            x = 0,
            y = 0,
            w = 0,
            h = 0,
            sx = 1,
            sy = 1,
            ctor = [[group]],
            children = {
                {
                    name = [[ring]],
                    isVisible = true,
                    noInput = true,
                    anchor = 1,
                    rotation = 0,
                    x = 0,
                    xpx = true,
                    y = 0,
                    ypx = true,
                    w = 2,
                    wpx = true,
                    h = 2,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[image]],
                    color = { --
                        1,
                        1,
                        0.1,
                        0.5,
                    },
                    images = {
                        { --
                            file = [[uitr_mf_leader_circle.png]],
                            name = [[]],
                        },
                    },
                },
            },
        },
    },
}

return inserts
