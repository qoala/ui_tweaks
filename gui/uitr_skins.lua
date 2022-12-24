
local skins =
{
	{
		name = [[uitrTooltip]], -- Copy of "skins.lua/tooltip", but with an additional footer element.
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
				name = [[bg]],
				isVisible = true,
				noInput = true,
				anchor = 1,
				rotation = 0,
				x = 129,
				xpx = true,
				y = -38,
				ypx = true,
				w = 256,
				wpx = true,
				h = 72,
				hpx = true,
				sx = 1,
				sy = 1,
				ctor = [[image]],
				color =
				{
					0.133333340287209,
					0.223529413342476,
					0.219607844948769,
					0.862745106220245,
				},
				images =
				{
					{
						file = [[white.png]],
						name = [[]],
						color =
						{
							0.133333340287209,
							0.223529413342476,
							0.219607844948769,
							0.862745106220245,
						},
					},
				},
			},
			{
				name = [[label]],
				isVisible = true,
				noInput = true,
				anchor = 1,
				rotation = 0,
				x = 174,
				xpx = true,
				y = -220,
				ypx = true,
				w = 340,
				wpx = true,
				h = 432,
				hpx = true,
				sx = 1,
				sy = 1,
				ctor = [[label]],
				halign = MOAITextBox.LEFT_JUSTIFY,
				valign = MOAITextBox.LEFT_JUSTIFY,
				text_style = [[font1_16_r]],
			},
			{
				name = [[footer]], -- Moved these elements into a child group, to simplify moving/showing/hiding.
				isVisible = true,
				noInput = false,
				anchor = 1,
				rotation = 0,
				x = 0,   -- This group leaves x centered, children move to fit.
				xpx = true,
				y = -84, -- This group specifies y, with children following along.
				ypx = true,
				w = 0,
				h = 0,
				sx = 1,
				sy = 1,
				ctor = [[group]],
				children =
				{
					{
						name = [[border]],
						isVisible = true,
						noInput = true,
						anchor = 1,
						rotation = 0,
						x = 129,
						xpx = true,
						y = 0,
						ypx = true,
						w = 256,
						wpx = true,
						h = 20,
						hpx = true,
						sx = 1,
						sy = 1,
						ctor = [[image]],
						color =
						{
							0.219607844948769,
							0.376470595598221,
							0.376470595598221,
							0.862745106220245,
						},
						images =
						{
							{
								file = [[white.png]],
								name = [[]],
								color =
								{
									0.219607844948769,
									0.376470595598221,
									0.376470595598221,
									0.862745106220245,
								},
							},
						},
					},
					{
						name = [[hotkey]],
						isVisible = true,
						noInput = true,
						anchor = 1,
						rotation = 0,
						x = 131,
						xpx = true,
						y = 0,
						ypx = true,
						w = 256,
						wpx = true,
						h = 22,
						hpx = true,
						sx = 1,
						sy = 1,
						ctor = [[label]],
						halign = MOAITextBox.LEFT_JUSTIFY,
						valign = MOAITextBox.CENTER_JUSTIFY,
						text_style = [[font1_16_r]],
					},
					{
						name = [[controllerHotkey]], -- Controller Bindings mod.
						isVisible = true,
						noInput = true,
						anchor = 1,
						rotation = 0,
						x = 131,
						xpx = true,
						y = 0,
						ypx = true,
						w = 24,
						wpx = true,
						h = 24,
						hpx = true,
						sx = 1,
						sy = 1,
						ctor = [[image]],
						images =
						{
							{
								file = [[qedctrl/button-A.png]],
								-- file = [[white.png]],
								name = [[]],
							},
						},
					},
				},
			},
		},
	},
}

return { dependents = {}, text_styles = {}, transitions = {}, skins = skins, widgets = {}, properties = {}, currentSkin = nil }
