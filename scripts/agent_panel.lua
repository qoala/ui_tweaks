local agent_panel = include( "hud/agent_panel" )
local cdefs = include( "client_defs" )
local util = include( "client_util" )
local agent_actions = include( "hud/agent_actions" )
local mui_defs = require( "mui/mui_defs" )

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

local function onClickAbilityHotkeyDisabled( self, reason )
    -- Should only be called if the widget is in fact disabled.
	local sim = self._hud._game.simCore
    local isEndless = sim:getParams().difficultyOptions.maxHours == math.huge
    local campaignHours = sim:getParams().campaignHours

    local level = "SpySociety/HUD/voice/level1/"

    MOAIFmodDesigner.playSound(level.."alarmvoice_warning")
    self._hud:showWarning( STRINGS.UI.WARNING_CANT_USE, {r=1,g=1,b=1,a=1}, reason )
end

local function onClickAbilityAction( self, abilityOwner, abilityUser, ability )
	self._hud:transitionAbilityTarget( abilityOwner, abilityUser, ability )
end

local function updateButtonFromAbility( self, btn, ability, abilityOwner )
	local sim = self._hud._game.simCore
	local enabled, reason = self._unit:canUseAbility( sim, ability, abilityOwner )
	assert(abilityOwner)

	btn:setVisible( true )
    if not enabled then
	    btn.onHotkey = util.makeDelegate( nil, onClickAbilityHotkeyDisabled, self, reason )
    else
        btn.onHotkey = nil
    end
	btn.onClick = util.makeDelegate( nil, onClickAbilityAction, self, abilityOwner, self._unit, ability )
	btn:setHotkey( ability.hotkey )
end

local function updateButtonFromAction( self, btn, action )
	btn:setVisible( true )
	btn.onHotkey = action.onHotkey
	btn:setHotkey( action.hotkey )
end

local function refreshNonVisionActions( self, unit, binder )
	if not self._panelNonVisionActions then
		return
	end

	local actions = {}
	agent_actions.generateNonVisionActions( self._hud, actions, unit )

	for i, btn in binder:forEach( "uitrNonVisionDynaction" ) do
		local item = table.remove( actions )
		if item and item.ability then
			updateButtonFromAbility( self, btn, item.ability, unit )
		elseif item then
			updateButtonFromAction( self, btn, item )
		else
			btn:setVisible( false )
		end
	end
end

-- ===
-- Appends
-- ===

local oldInit = agent_panel.agent_panel.init
function agent_panel.agent_panel:init( hud, screen, ... )
	local nonVisionActions = screen.binder.uitrNonVisionActionsGroup
	if nonVisionActions and not nonVisionActions.isnull then
		self._panelNonVisionActions = nonVisionActions
	end

	oldInit(self, hud, screen, ...)
end

local oldRefreshPanel = agent_panel.agent_panel.refreshPanel
function agent_panel.agent_panel:refreshPanel( swipeIn, ... )
	oldRefreshPanel(self, swipeIn, ...)

	if (not self._hud._game:isReplaying()
		and not self._hud:isMainframe()
		and #self._popUps == 0
		and self._hud:canShowElement( "abilities" )
		and self._hud._uitr_isVisionMode
	) then
		-- Vision Mode is active

        self._panel.binder.agentInfo:setVisible( false )
		self._panelInventory:setVisible(false)
		self._panelAugments:setVisible(false)
		self._panelActions:setVisible(false)
		self._panelDead:setVisible(false)

		refreshVisionActions(self, self._panel.binder)

		local sim = self._hud._game.simCore
		local unit = self._hud:getSelectedUnit()
		if (unit and unit:getPlayerOwner() ~= nil
			and unit:getPlayerOwner() == sim:getCurrentPlayer()
			and unit:getPlayerOwner() == self._hud._game:getLocalPlayer()
			and unit:getLocation()
			and not unit:isGhost()
		) then
			self._panelNonVisionActions:setVisible(true)
			refreshNonVisionActions(self, unit, self._panel.binder)
		elseif self._panelNonVisionActions then
			self._panelNonVisionActions:setVisible(false)
		end
	elseif self._panelNonVisionActions then
		self._panelNonVisionActions:setVisible(false)
	end
end
