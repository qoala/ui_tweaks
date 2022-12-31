local modifications = {
    {
        "options_dialog_screen.lua",
        {"widgets"},
        {
            -- Raise the top of the dialog screen.
            [2] = { -- bg box
                y = 0 + 16,
                h = 580 + 32,
            },
            [6] = { -- header box top
                y = 297 + 32,
            },
            [7] = { -- header
                y = 243 + 32,
            },
            [8] = { -- header underline
                y = 229 + 32,
            },
        },
    },
    {
        "options_dialog_screen.lua",
        {"widgets", 5, "tabs"},
        {
            -- Raise the tab buttons.
            [1] = {
                [1] = {
                    children = {
                        [1] = { -- tabButton
                            y = 32,
                        },
                    },
                },
            },
            [2] = {
                [1] = {
                    children = {
                        [1] = { -- tabButton
                            y = 32,
                        },
                    },
                },
            },
            [3] = {
                [1] = {
                    children = {
                        [1] = { -- tabButton
                            y = 32,
                        },
                    },
                },
            },
            [4] = {
                [1] = {
                    children = {
                        [1] = { -- tabButton
                            y = 32,
                        },
                    },
                },
            },
        },
    },
}

return modifications
