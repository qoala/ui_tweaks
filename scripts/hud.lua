local hud = include( "hud/hud" )
local mui_defs = include( "mui/mui_defs")
local mui_tooltip = include( "mui/mui_tooltip")
local util = include( "client_util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

local function onClickVisionToggle( hud )
	hud:uitr_setVisionMode( not hud._uitr_isVisionMode )
end

function visionModeTooltip( doEnable )
	return mui_tooltip( STRINGS.UITWEAKSR.UI.BTN_VISIONMODE_HEADER,
			doEnable and STRINGS.UITWEAKSR.UI.BTN_VISIONMODE_DISABLE_TXT or STRINGS.UITWEAKSR.UI.BTN_VISIONMODE_ENABLE_TXT,
			"UITR_VISIONMODE" )
end

function hud_uitr_setVisionMode( hud, doEnable )
	hud._uitr_isVisionMode = doEnable

	local btnToggleVisionMode = hud._screen.binder.topPnl.binder.btnToggleVisionMode
	btnToggleVisionMode:setTooltip( visionModeTooltip( doEnable ) )
	btnToggleVisionMode:setInactiveImage(doEnable and "gui/hud3/UserButtons/uitr_btn_disable_visionmode.png" or "gui/hud3/UserButtons/uitr_btn_enable_visionmode.png")
	btnToggleVisionMode:setActiveImage(doEnable and "gui/hud3/UserButtons/uitr_btn_disable_visionmode_hl.png" or "gui/hud3/UserButtons/uitr_btn_enable_visionmode_hl.png")
	btnToggleVisionMode:setHoverImage(doEnable and "gui/hud3/UserButtons/uitr_btn_disable_visionmode_hl.png" or "gui/hud3/UserButtons/uitr_btn_enable_visionmode_hl.png")

	hud:refreshHud()
end

function hud_updateVision( hud )
	local sim = hud._game.simCore
	local localPlayer = hud._game:getLocalPlayer()

	local keyBindingDown = util.isKeyBindingDown( "UITR_VISIONMODE" )
	if keyBindingDown ~= hud._uitr_visionKeyBindingDown then
		hud._uitr_visionKeyBindingDown = keyBindingDown
		hud:uitr_setVisionMode( keyBindingDown )
	end

	local prevOneCellVision = sim:getTags().uitr_oneCellVision
	if localPlayer and hud._tooltipX and hud._tooltipY and keyBindingDown and sim:getCurrentPlayer() == localPlayer then
		sim:getTags().uitr_oneCellVision = simquery.toCellID(hud._tooltipX, hud._tooltipY)
	else
		sim:getTags().uitr_oneCellVision = nil
	end
	if prevOneCellVision ~= sim:getTags().uitr_oneCellVision then
		hud._game.boardRig:refresh()
	end
end

local oldCreateHud = hud.createHud

hud.createHud = function( ... )
	local hudObject = oldCreateHud( ... )

	local btnToggleVisionMode = hudObject._screen.binder.topPnl.binder.btnToggleVisionMode
	if btnToggleVisionMode and not btnToggleVisionMode.isnull then
		hudObject._uitr_isVisionMode = false
		hudObject.uitr_setVisionMode = hud_uitr_setVisionMode

		local oldOnSimEvent = hudObject.onSimEvent
		function hudObject:onSimEvent( ev, ... )
			local result = oldOnSimEvent( self, ev, ... )

			if ev.eventType == simdefs.EV_TURN_END then
				self._game.simCore:uitr_resetAllUnitVision()
			end

			return result
		end

		local oldUpdateHud = hudObject.updateHud
		function hudObject:updateHud( ... )
			oldUpdateHud( self, ... )

			hud_updateVision( self )
		end

		btnToggleVisionMode:setTooltip( visionModeTooltip( false ) )
		btnToggleVisionMode.onClick = util.makeDelegate( nil, onClickVisionToggle, hudObject )
		-- Implemented as press-and-hold in hud_updateVision
		-- btnToggleVisionMode:setHotkey( "UITR_VISIONMODE" )
	end

	return hudObject
end
