local inserts =
{
	{
		"hud.lua",
		{ "widgets", 16, "children" },
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
			images =
			{
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
}

return inserts
