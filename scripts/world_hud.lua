local world_hud = include( "hud/hud-inworld" )
local mui_defs = include( "mui/mui_defs")

local uitr_util = include( SCRIPT_PATHS.qed_uitr .. "/uitr_util" )

local oldRefreshWidgets = world_hud.refreshWidgets
function world_hud:refreshWidgets( ... )
	oldRefreshWidgets( self, ... )

	if uitr_util.checkOption("cleanShift") then
		local shouldShowHudActions = not (inputmgr.keyIsDown(mui_defs.K_SHIFT) and not inputmgr.keyIsDown(mui_defs.K_CONTROL))
		if shouldShowHudActions ~= self._uitr_hudActionsVisible  then
			local widgets = self._widgets[world_hud.HUD]
			if widgets then
				for _,widget in ipairs(widgets) do
					widget:setVisible(shouldShowHudActions)
				end
			end
			local layout = self._layouts[world_hud.HUD]
			if layout and layout._layout then
				for layoutID, lt in pairs(layout._layout) do
					if lt.leaderWidget then
						lt.leaderWidget:setVisible(shouldShowHudActions)
					end
				end
			end
		end
		self._uitr_hudActionsVisible = shouldShowHudActions
	else
		self._uitr_showHudActions = nil
	end
end

function world_hud:destroyLayout( groupKey )
	if self._layouts[ groupKey ] then
		self._layouts[ groupKey ]:destroy( self._screen )
		self._layouts[ groupKey ] = nil
	end
end

local oldCreateWidget = world_hud.createWidget
function world_hud:createWidget( groupKey, skinName, t, ... )
	if groupKey == world_hud.MAINFRAME and skinName == "BreakIce" and t.ownerID then
		local sim = self._game.simCore
		local unit = sim:getUnit( t.ownerID )
		if unit and unit:getLocation() then
			-- Store the true worldz without the mainframe panel's crude offset for overlapping targets
			t.layoutWorldz = unit:getTraits().breakIceOffset or 12
		end
	end

	local widget = oldCreateWidget(self, groupKey, skinName, t, ... )

	if self._layouts[groupKey] and self._layouts[groupKey].dirtyLayout then
		self._layouts[groupKey]:dirtyLayout()
	end

	return widget
end


local oldDestroyWidget = world_hud.destroyWidget
function world_hud:destroyWidget( groupKey, ... )
	local widget = oldDestroyWidget(self, groupKey, ... )

	if self._layouts[groupKey] and self._layouts[groupKey].dirtyLayout then
		self._layouts[groupKey]:dirtyLayout()
	end

	return widget
end

local oldGetWidgets = world_hud.getWidgets
function world_hud:getWidgets( groupKey, ... )
	local widget = oldGetWidgets(self, groupKey, ... )

	-- Technically not dirty yet, but the caller may dirty the widgets.
	if self._layouts[groupKey] and self._layouts[groupKey].dirtyLayout then
		self._layouts[groupKey]:dirtyLayout()
	end

	return widget
end
