dependents =
{
    "skins.lua",
}
text_styles =
{
}
skins =
{
    {
        name = [[Group]],
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
        children =
        {
            {
                name = [[bar]],
                isVisible = true,
                noInput = false,
                anchor = 1,
                rotation = 0,
                x = -12,
                xpx = true,
                y = 3,
                ypx = true,
                w = 28,
                wpx = true,
                h = 15,
                hpx = true,
                sx = 1,
                sy = 1,
                ctor = [[image]],
                color =
                {
                    0.200000002980232,
                    0.341176480054855,
                    0.341176480054855,
                    1,
                },
                images =
                {
                    {
                        file = [[white.png]],
                        name = [[]],
                        color =
                        {
                            0.200000002980232,
                            0.341176480054855,
                            0.341176480054855,
                            1,
                        },
                    },
                },
            },
        },
    },
    {
        name = [[Group 2]],
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
        children =
        {
            {
                name = [[agentPnl]],
                isVisible = true,
                noInput = false,
                anchor = 1,
                rotation = 0,
                x = -15,
                xpx = true,
                y = 26,
                ypx = true,
                w = 0,
                h = 0,
                sx = 1,
                sy = 1,
                ctor = [[group]],
                children =
                {
                    {
                        name = [[bg]],
                        isVisible = true,
                        noInput = false,
                        anchor = 1,
                        rotation = 0,
                        x = 27,
                        xpx = true,
                        y = -26,
                        ypx = true,
                        w = 861,
                        wpx = true,
                        h = 482,
                        hpx = true,
                        sx = 1,
                        sy = 1,
                        ctor = [[image]],
                        color =
                        {
                            1,
                            1,
                            1,
                            1,
                        },
                        images =
                        {
                            {
                                file = [[gui/menu pages/unlocks/unlocks_new_program_window.png]],
                                name = [[]],
                            },
                        },
                    },
                    -- {
                    --     name = [[agentBG]],
                    --     isVisible = true,
                    --     noInput = false,
                    --     anchor = 1,
                    --     rotation = 0,
                    --     x = -126,
                    --     xpx = true,
                    --     y = -57,
                    --     ypx = true,
                    --     w = 256,
                    --     wpx = true,
                    --     h = 256,
                    --     hpx = true,
                    --     sx = 1,
                    --     sy = 0.99,
                    --     ctor = [[image]],
                    --     color =
                    --     {
                    --         1,
                    --         1,
                    --         1,
                    --         1,
                    --     },
                    --     images =
                    --     {
                    --         {
                    --             file = [[gui/menu pages/team_select/agent_bg.png]],
                    --             name = [[]],
                    --         },
                    --     },
                    -- },
                    -- {
                    --     name = [[agentIMG]],
                    --     isVisible = true,
                    --     noInput = false,
                    --     anchor = 1,
                    --     rotation = 0,
                    --     x = -125,
                    --     xpx = true,
                    --     y = -55,
                    --     ypx = true,
                    --     w = 256,
                    --     wpx = true,
                    --     h = 256,
                    --     hpx = true,
                    --     sx = 1,
                    --     sy = 1,
                    --     ctor = [[image]],
                    --     color =
                    --     {
                    --         1,
                    --         1,
                    --         1,
                    --         1,
                    --     },
                    --     images =
                    --     {
                    --         {
                    --             file = [[gui/agents/team_select_1_shalem.png]],
                    --             name = [[]],
                    --         },
                    --     },
                    -- },
                    {
                        name = [[agentName]],
                        isVisible = true,
                        noInput = false,
                        anchor = 1,
                        rotation = 0,
                        x = 15,
                        xpx = true,
                        y = 66,
                        ypx = true,
                        w = 400,
                        wpx = true,
                        h = 60,
                        hpx = true,
                        sx = 1,
                        sy = 1,
                        ctor = [[label]],
                        halign = MOAITextBox.CENTER_JUSTIFY,
                        valign = MOAITextBox.LEFT_JUSTIFY,
                        text_style = [[font1_33_l]],
                        color =
                        {
                            0.95686274766922,
                            1,
                            0.470588237047195,
                            1,
                        },
                    },
                    {
                        name = [[agentNameSmall]],
                        isVisible = false,
                        noInput = false,
                        anchor = 1,
                        rotation = 0,
                        x = 14,
                        xpx = true,
                        y = 59,
                        ypx = true,
                        w = 400,
                        wpx = true,
                        h = 60,
                        hpx = true,
                        sx = 1,
                        sy = 1,
                        ctor = [[label]],
                        halign = MOAITextBox.CENTER_JUSTIFY,
                        valign = MOAITextBox.LEFT_JUSTIFY,
                        text_style = [[font1_24_r]],
                        color =
                        {
                            0.95686274766922,
                            1,
                            0.470588237047195,
                            1,
                        },
                        str = [[STR_1079594648]],
                    },
                },
            },
        },
    },
}
widgets =
{
    {
        name = [[blackbg]],
        isVisible = true,
        noInput = false,
        anchor = 1,
        rotation = 0,
        x = 0.5,
        y = 0.5,
        w = 1,
        h = 1,
        sx = 1,
        sy = 1,
        ctor = [[image]],
        color =
        {
            0,
            0,
            0,
            0.705882370471954,
        },
        images =
        {
            {
                file = [[white.png]],
                name = [[]],
                color =
                {
                    0,
                    0,
                    0,
                    0.705882370471954,
                },
            },
        },
    },
    {
        name = [[pnl]],
        isVisible = true,
        noInput = false,
        anchor = 0,
        rotation = 0,
        x = 0,
        xpx = true,
        y = 0,
        ypx = true,
        w = 0,
        h = 0,
        sx = 1,
        sy = 1,
        ctor = [[group]],
        children =
        {
            {
                name = [[headerBG]],
                isVisible = true,
                noInput = false,
                anchor = 1,
                rotation = 0,
                x = 0,
                xpx = true,
                y = 337,
                ypx = true,
                w = 1024,
                wpx = true,
                h = 128,
                hpx = true,
                sx = 1,
                sy = 1,
                ctor = [[image]],
                color =
                {
                    1,
                    1,
                    1,
                    0.901960790157318,
                },
                images =
                {
                    {
                        file = [[gui/menu pages/unlocks/unlocks_header_window.png]],
                        name = [[]],
                        color =
                        {
                            1,
                            1,
                            1,
                            0.901960790157318,
                        },
                    },
                },
            },
            {
                name = [[titleTxt]],
                isVisible = true,
                noInput = false,
                anchor = 1,
                rotation = 0,
                x = 12,
                xpx = true,
                y = 322,
                ypx = true,
                w = 900,
                wpx = true,
                h = 72,
                hpx = true,
                sx = 1,
                sy = 1,
                ctor = [[label]],
                halign = MOAITextBox.CENTER_JUSTIFY,
                valign = MOAITextBox.LEFT_JUSTIFY,
                text_style = [[font4_32_r]],
                rawstr = [[NEW CONTENT <c:F4FF78F>UNLOCKED</>]],
            },
            {
                name = [[agent1]],
                isVisible = true,
                noInput = false,
                anchor = 1,
                rotation = 0,
                x = -450 + 5,
                xpx = true,
                y = 0 + 3,
                ypx = true,
                w = 889,
                wpx = true,
                h = 552,
                hpx = true,
                sx = 1,
                sy = 1,
                ctor = [[image]],
                color =
                {
                    1,
                    1,
                    1,
                    1,
                },
                images =
                {
                    {
                        file = [[gui/menu pages/unlocks_end_card_window.png]],
                        name = [[]],
                    },
                },
            },
            {
                name = [[agent2]],
                isVisible = true,
                noInput = false,
                anchor = 1,
                rotation = 0,
                x = 450 + 5,
                xpx = true,
                y = 0 + 3,
                ypx = true,
                w = 889,
                wpx = true,
                h = 552,
                hpx = true,
                sx = 1,
                sy = 1,
                ctor = [[image]],
                color =
                {
                    1,
                    1,
                    1,
                    1,
                },
                images =
                {
                    {
                        file = [[gui/menu pages/unlocks_end_card_window.png]],
                        name = [[]],
                    },
                },
            },
            -- {
            --     name = [[okBtn]],
            --     isVisible = true,
            --     noInput = false,
            --     anchor = 1,
            --     rotation = 0,
            --     x = 387,
            --     xpx = true,
            --     y = -166,
            --     ypx = true,
            --     w = 0,
            --     h = 0,
            --     sx = 1,
            --     sy = 1,
            --     skin = [[screen_button]],
            -- },
        },
    },
}
transitions =
{
}
properties =
{
    sinksInput = true,
    activateTransition = [[activate_left]],
}
return { dependents = dependents, text_styles = text_styles, transitions = transitions, skins = skins, widgets = widgets, properties = properties, currentSkin = nil }
