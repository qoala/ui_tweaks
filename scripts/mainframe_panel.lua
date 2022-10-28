local mainframe_panel = include( "hud/mainframe_panel" )
local cdefs = include( "client_defs" )
local util = include( "client_util" )
local world_hud = include( "hud/hud-inworld" )
local mui_defs = require( "mui/mui_defs" )

local uitr_util = include( SCRIPT_PATHS.qed_uitr .. "/uitr_util" )
local mainframe_layout = include( SCRIPT_PATHS.qed_uitr .. "/mainframe_layout" )

local panel = mainframe_panel.panel

local function initLayouts( self )
	local layout = mainframe_layout(self._hud)
	self._hud._world_hud:setLayout( world_hud.MAINFRAME, layout )
	-- RAW_MF_T: Raw mainframe targeting from SimConstructor.
	-- if self.RAW_MF_T then
	-- 	local layout = mainframe_layout(self._hud)
	-- 	self._hud._world_hud:setLayout( self.RAW_MF_T, layout )
	-- end
end

local oldShow = panel.show
function panel:show( ... )
	if uitr_util.checkOption("mainframeLayout") then
		self._uitr_usingLayout = true
		initLayouts(self)
	end

	oldShow( self, ... )
end

local oldHide = panel.hide
function panel:hide( ... )
	oldHide( self, ... )

	-- Layout was destroyed by world_hud along with the mainframe widgets.
	self._uitr_usingLayout = false
end

local oldRefresh = panel.refresh
function panel:refresh( ... )
	local useLayout = uitr_util.checkOption("mainframeLayout")
	if useLayout ~= self._uitr_usingLayout then
		self._uitr_usingLayout = useLayout
		if useLayout then
			initLayouts(self)
		else
			self._hud._world_hud:destroyLayout( world_hud.MAINFRAME )
			-- if self.RAW_MF_T then self._hud._world_hud:destroyLayout( self.RAW_MF_T ) end
		end
	end

	oldRefresh( self, ... )
end
