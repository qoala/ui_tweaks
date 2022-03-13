local agent_actions = include( "hud/agent_actions" )
local mui_tooltip = include( "mui/mui_tooltip" )
local util = include( "modules/util" )
local simquery = include( "sim/simquery" )

-- ====

local vision_tooltip = class( mui_tooltip )

function vision_tooltip:init( hud, unit )
	mui_tooltip.init( self, util.sformat(STRINGS.UITWEAKSR.UI.HOVER_VISION, util.toupper(unit:getName())), nil, nil )
	self._game = hud._game
	self._unit = unit
end

function vision_tooltip:activate( screen )
	mui_tooltip.activate( self, screen )

	local sim = self._game.simCore
	local losCoords, cells = {}, {}
	sim:getLOS():getVizCells( self._unit:getID(), losCoords )
	for i = 1, #losCoords, 2 do
		local x, y = losCoords[i], losCoords[i+1]
		table.insert( cells, sim:getCell( x, y ))
	end
	self._hiliteID = self._game.boardRig:hiliteCells( cells )
end

function vision_tooltip:deactivate()
	mui_tooltip.deactivate( self )
	self._game.boardRig:unhiliteCells( self._hiliteID )
	self._hiliteID = nil
end

-- ====

local explode_tooltip = class( mui_tooltip )

function explode_tooltip:init( hud, unit )
	mui_tooltip.init( self, util.sformat(STRINGS.UITWEAKSR.UI.HOVER_EFFECT, util.toupper(unit:getName())), nil, nil )
	self._game = hud._game
	self._unit = unit
end

function explode_tooltip:activate( screen )
	mui_tooltip.activate( self, screen )

	local cells
	local unit = self._unit
	if unit:getUnitData().type == "simemppack" and not unit:getTraits().flash_pack then
		local sim = self._game.simCore
		local x0,y0 = unit:getLocation()
		cells = simquery.rasterCircle( sim, x0, y0, unit:getTraits().range )
	else
		cells = unit:getExplodeCells()
	end

	self._hiliteID = self._game.boardRig:hiliteCells( cells )
end

function explode_tooltip:deactivate()
	mui_tooltip.deactivate( self )
	self._game.boardRig:unhiliteCells( self._hiliteID )
	self._hiliteID = nil
end

-- ====

local function addVisionActionsForUnit( hud, actions, targetUnit, isSeen )
	local localPlayer = hud._game:getLocalPlayer()
	local x,y = targetUnit:getLocation()
	local sim = hud._game.simCore
	local canNormallySeeLOS = sim:getParams().difficultyOptions.dangerZones or isSeen

	if targetUnit:getUnitData().type == "eyeball" then
		return
	end

	if targetUnit:hasTrait("hasSight") then
		table.insert( actions,
		{
			txt = "",
			icon = "gui/items/icon-action_peek.png",
			x = x, y = y,
			enabled = false,
			layoutID = targetUnit:getID(),
			tooltip = vision_tooltip( hud, targetUnit ),
			priority = -10,
		})
	end
	if targetUnit.getExplodeCells and not targetUnit:hasAbility( "carryable" ) then
		table.insert( actions,
		{
			txt = "",
			icon = "gui/items/icon-emp.png",
			x = x, y = y,
			enabled = false,
			layoutID = targetUnit:getID(),
			tooltip = explode_tooltip( hud, targetUnit ),
			priority = -9,
		})
	end
	if canNormallySeeLOS and targetUnit:hasTrait("hasSight") and targetUnit:getPlayerOwner() ~= localPlayer then
		local doEnable = not targetUnit:getTraits().uitr_hideVision
		table.insert( actions,
		{
			txt = "",
			icon = doEnable and "gui/items/icon-action_peek.png" or "gui/items/uitr-icon-action_unpeek.png",
			x = x, y = y,
			enabled = true,
			layoutID = targetUnit:getID(),
			tooltip = string.format( "<ttheader>%s\n<ttbody>%s</>",
					STRINGS.UITWEAKSR.UI.BTN_UNITVISION_HEADER,
					(doEnable and STRINGS.UITWEAKSR.UI.BTN_UNITVISION_HIDE_TXT or STRINGS.UITWEAKSR.UI.BTN_UNITVISION_SHOW_TXT) ),
			priority = -5,
			onClick =
				function()
					targetUnit:getTraits().uitr_hideVision = not targetUnit:getTraits().uitr_hideVision 
					hud._game.boardRig:refresh()
					hud:refreshHud()
				end
		})
	end
end

local function resolveGhost( sim, unitID, ghostUnit )
	local unit = sim:getUnit( ghostUnit:getID() )
	if not unit then
		return nil
	end
	local x0,y0 = ghostUnit:getLocation()
	local x1,y1 = unit:getLocation()
	if x0 ~= x1 or y0 ~= y1 then
		-- Ghost is stale (by the metric used for shift-highlighting)
		return nil
	end
	return unit
end

local oldGeneratePotentialActions = agent_actions.generatePotentialActions
function agent_actions.generatePotentialActions( hud, actions, unit, cellx, celly, ... )
	if not hud._uitr_isVisionMode then
		return oldGeneratePotentialActions( hud, actions, unit, cellx, celly, ... )
	end

	local x0, y0 = unit:getLocation()
	if x0 ~= cellx or y0 ~= celly then
		-- Only execute once, on the current unit's cell
		return
	end

	local sim = hud._game.simCore
	local localPlayer = hud._game:getLocalPlayer()

	-- Vision actions for seen units
	for i,targetUnit in ipairs( localPlayer:getSeenUnits() ) do
		addVisionActionsForUnit( hud, actions, targetUnit, true )
	end

	-- Vision actions for known ghosts
	for unitID,ghostUnit in pairs( localPlayer._ghost_units ) do
		local targetUnit = resolveGhost( sim, unitID, ghostUnit )
		if targetUnit then
			addVisionActionsForUnit( hud, actions, targetUnit, false )
		end
	end

	-- Non-proxy abilities (copied from vanilla. All other abilities are suppressed)
	for j, ability in ipairs( unit:getAbilities() ) do
		if agent_actions.shouldShowAbility( hud._game, ability, unit, unit )
				-- Only show untargetted abilities (that go in the bottom-left panel)
				and not ability.acquireTargets then
			table.insert( actions, { ability = ability, abilityOwner = unit, abilityUser = unit, priority = ability.HUDpriority } )
		end
	end
end

local oldShouldShowProxyAbility = agent_actions.shouldShowProxyAbility
function agent_actions.shouldShowProxyAbility( game, ability, abilityOwner, abilityUser, actions, ... )
	if game.hud and game.hud._uitr_isVisionMode then
		return false
	end
	return oldShouldShowProxyAbility( game, ability, abilityOwner, abilityUser, actions, ... )
end
