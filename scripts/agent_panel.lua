local agent_panel = include( "hud/agent_panel" )
local cdefs = include( "client_defs" )
local util = include( "client_util" )
local agent_actions = include( "hud/agent_actions" )

-- ===
-- Helper functions
-- ===

local function refreshVisionActions( self, binder )
	local actions = {}
	local cellTargets = agent_panel.buttonLocator( self._hud )

	agent_actions.generateVisionActions( self._hud, actions )

	table.sort( actions, function( a0, a1 ) return (a0.priority or math.huge) > (a1.priority or math.huge) end )

	-- Show all actionables.
	for _,item in ipairs( actions ) do
		self:addActionTargets( cellTargets, item )
	end
end

-- ===
-- Appends
-- ===

local oldRefreshPanel = agent_panel.agent_panel.refreshPanel
function agent_panel.agent_panel:refreshPanel( swipeIn, ... )
	oldRefreshPanel(self, swipeIn, ...)

	if (not self._hud._game:isReplaying()
		and not self._hud:isMainframe()
		and #self._popUps == 0
		and self._hud._uitr_isVisionMode
	) then
        self._panel.binder.agentInfo:setVisible( false )
		self._panelInventory:setVisible(false)
		self._panelAugments:setVisible(false)
		self._panelActions:setVisible(false)
		self._panelDead:setVisible(false)

		refreshVisionActions(self, self._panel.binder)
	end
end
