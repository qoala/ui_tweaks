local mainframe_panel = include( "hud/mainframe_panel" )
local cdefs = include( "client_defs" )
local util = include( "client_util" )
local world_hud = include( "hud/hud-inworld" )
local mui_defs = require( "mui/mui_defs" )

local uitr_util = include( SCRIPT_PATHS.qed_uitr .. "/uitr_util" )
local mainframe_layout = include( SCRIPT_PATHS.qed_uitr .. "/mainframe_layout" )

local panel = mainframe_panel.panel
local MODE_HIDDEN = 0
local MODE_VISIBLE = 1

local function initLayouts( self )
	local layout = mainframe_layout(self._hud)
	self._uitr_layout = layout
	self._hud._world_hud:setLayout( world_hud.MAINFRAME, layout )
	-- There's also the RAW_MF_T group key for "Raw targeting" mainframe abilities added by SimConstructor.
	-- If the layout starts repositioning targeted abilities, should also account for these.
end

local function destroyLayouts( self )
	self._hud._world_hud:destroyLayout( world_hud.MAINFRAME )
	self._uitr_layout = nil

	local widgets = self._hud._world_hud:getWidgets( world_hud.MAINFRAME )
	if widgets then
		mainframe_layout.restoreWidgets(widgets)
	end
end

local oldRefresh = panel.refresh
function panel:refresh( ... )
	if self._mode == MODE_VISIBLE then

		-- Prepare the layout if necessary. This panel preserves the layout and widgets across refreshes.
		local useLayout = uitr_util.checkOption("mainframeLayout")
		if useLayout ~= self._uitr_usingLayout then
			self._uitr_usingLayout = useLayout
			if useLayout then
				initLayouts(self)
			else
				destroyLayouts(self)
			end
		end
		if self._uitr_layout then
			self._uitr_layout:refreshTuningSettings()
		end
	else
		-- Layout was destroyed by world_hud along with the mainframe widgets.
		self._uitr_usingLayout = false
	end

	oldRefresh( self, ... )
end

local oldRefreshBreakIceButton = panel.refreshBreakIceButton
function panel:refreshBreakIceButton( widget, unit, ... )
	oldRefreshBreakIceButton(self, widget, unit, ...)

	local sim = self._hud._game.simCore

	if sim:getHideDaemons() and not unit:getTraits().daemon_sniffed then
		widget.layoutState = "daemonHidden"
	elseif unit:getTraits().mainframe_program ~= nil then
		if unit:getTraits().daemon_sniffed then
			widget.layoutState = "daemonKnown"
		else
			widget.layoutState = "daemonUnknown"
		end
	else
		widget.layoutState = nil
	end
end
