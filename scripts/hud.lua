local hud = include( "hud/hud" )
local mui_tooltip = include( "mui/mui_tooltip")
local util = include( "client_util" )

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

local oldCreateHud = hud.createHud

hud.createHud = function( ... )
	local hudObject = oldCreateHud( ... )

	local btnToggleVisionMode = hudObject._screen.binder.topPnl.binder.btnToggleVisionMode
	if btnToggleVisionMode and not btnToggleVisionMode.isnull then
		hudObject._uitr_isVisionMode = false
		hudObject.uitr_setVisionMode = hud_uitr_setVisionMode

		btnToggleVisionMode:setTooltip( visionModeTooltip( false ) )
		btnToggleVisionMode.onClick = util.makeDelegate( nil, onClickVisionToggle, hudObject )
		btnToggleVisionMode:setHotkey( "UITR_VISIONMODE" )
	end

	return hudObject
end
