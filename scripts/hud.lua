local hud = include( "hud/hud" )
local mui_tooltip = include( "mui/mui_tooltip")
local util = include( "client_util" )

local function onClickVisionToggle( hud )
	hud:uitr_setVisionMode( not hud._uitr_isVisionMode )
end

function uitr_setVisionMode( hud, doEnable )
	hud._uitr_isVisionMode = doEnable

	local btnToggleVisionMode = hud._screen.binder.topPnl.binder.btnToggleVisionMode
	btnToggleVisionMode:setTooltip( mui_tooltip( "VISION MODE", doEnable and "Disable vision mode" or "Enable vision mode", nil ) )
	btnToggleVisionMode:setInactiveImage(doEnable and "gui/hud3/UserButtons/userbtn_rotate_right.png" or "gui/hud3/UserButtons/userbtn_rotate_left.png")
	btnToggleVisionMode:setActiveImage(doEnable and "gui/hud3/UserButtons/userbtn_rotate_right_hl.png" or "gui/hud3/UserButtons/userbtn_rotate_left_hl.png")
	btnToggleVisionMode:setHoverImage(doEnable and "gui/hud3/UserButtons/userbtn_rotate_right_hl.png" or "gui/hud3/UserButtons/userbtn_rotate_left_hl.png")

	hud:refreshHud()
end

local oldCreateHud = hud.createHud

hud.createHud = function( ... )
	local hudObject = oldCreateHud( ... )

	local btnToggleVisionMode = hudObject._screen.binder.topPnl.binder.btnToggleVisionMode
	if btnToggleVisionMode and not btnToggleVisionMode.isnull then
		hudObject._uitr_isVisionMode = false
		hudObject.uitr_setVisionMode = uitr_setVisionMode

		btnToggleVisionMode:setTooltip( mui_tooltip( "VISION MODE", "Enable vision mode", nil ) )
		btnToggleVisionMode.onClick = util.makeDelegate( nil, onClickVisionToggle, hudObject )
	end

	return hudObject
end
