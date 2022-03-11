local agent_actions = include( "hud/agent_actions" )
local mui_tooltip = include( "mui/mui_tooltip")

-- ====

local vision_tooltip = class( mui_tooltip )

function vision_tooltip:init( hud, unit )
	mui_tooltip.init( self, "VISION HOVER: " .. unit:getName(), "Hover to highlight seen tiles, ignoring cover. (Equivalent to SHIFT, but for only this unit)", nil )
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

local function addVisionActionsForUnit( hud, actions, targetUnit )
	local localPlayer = hud._game:getLocalPlayer()
	local x,y = targetUnit:getLocation()

	if targetUnit:hasTrait("hasSight") and targetUnit:getPlayerOwner() ~= localPlayer then
		table.insert( actions,
		{
			txt = STRINGS.UI.ACTIONS.LOOT_BODY.NAME,
			icon = "gui/items/icon-action_peek.png",
			x = x, y = y,
			enabled = true,
			layoutID = targetUnit:getID(),
			tooltip = string.format( "<ttheader>%s\n<ttbody>%s</>", "TOGGLE VISION: " .. targetUnit:getName(), "Hide this unit's vision from tactical view." ),
			onClick =
				function()
				end
		})
	end
	if targetUnit:hasTrait("hasSight") then
		table.insert( actions,
		{
			txt = STRINGS.UI.ACTIONS.LOOT_BODY.NAME,
			icon = "gui/items/icon-action_peek.png",
			x = x, y = y,
			enabled = false,
			layoutID = targetUnit:getID(),
			tooltip = vision_tooltip( hud, targetUnit ),
			onClick =
				function()
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

	for i,targetUnit in ipairs( localPlayer:getSeenUnits() ) do
		addVisionActionsForUnit( hud, actions, targetUnit )
	end

	for unitID,ghostUnit in pairs( localPlayer._ghost_units ) do
		local targetUnit = resolveGhost( sim, unitID, ghostUnit )
		if targetUnit then
			addVisionActionsForUnit( hud, actions, targetUnit )
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
