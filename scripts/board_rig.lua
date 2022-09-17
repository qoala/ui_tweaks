local boardrig = include( "gameplay/boardrig" )
local cdefs = include( "client_defs" )
local resources = include( "resources" )
local array = include( "modules/array" )
local simquery = include( "sim/simquery" )

-- ===

local function predictLOS(sim, unit, predictedFacing)
	local startCell = sim:getCell(unit:getLocation())
    local halfArc = simquery.getLOSArc( unit ) / 2
    local distance = unit:getTraits().LOSrange
	local facingRads = unit:getTraits().LOSrads or (math.pi / 4 * predictedFacing)

	return sim:getLOS():calculateLOS(startCell, facingRads, halfArc, distance)
end

local function predictPeripheralLOS(sim, unit, predictedFacing)
	local startCell = sim:getCell(unit:getLocation())
    local halfArc = unit:getTraits().LOSperipheralArc / 2
    local distance = unit:getTraits().LOSperipheralRange
	local facingRads = unit:getTraits().LOSrads or (math.pi / 4 * predictedFacing)

	return sim:getLOS():calculateLOS(startCell, facingRads, halfArc, distance)
end

-- Memoize LOS for predicted threat facings
local function trackerPredictLos(self, facing)
	if self._losByFacing[facing] then
		return self._losByFacing[facing]
	end

	local cells = predictLOS(self._sim, self.threat, facing)
	self._losByFacing[facing] = cells
	return cells
end

-- Memoize peripheral LOS for predicted threat facings
local function trackerPredictPeripheralLos(self, facing)
	if self._peripheralLosByFacing[facing] then
		return self._peripheralLosByFacing[facing]
	end

	local cells = predictPeripheralLOS(self._sim, self.threat, facing)
	self._peripheralLosByFacing[facing] = cells
	return cells
end

local function findThreats(sim, selectedUnit)
	local threats = {}
	local trackingThreats = {}
	for _,unit in pairs(sim:getAllUnits()) do
		if simquery.isEnemyAgent(unit:getPlayerOwner(), selectedUnit) and (unit:isAiming() or unit:getTraits().skipOverwatch) and not unit:getTraits().pacifist then
			local tracking = false
			-- Note: This is just for guards/drones. Turrets don't actually track around the edge of their vision!
			if unit:getBrain() then
				local senses = unit:getBrain():getSenses()
				if senses:hasTarget(selectedUnit) then
					local facing = unit:getFacing()
					local tracker = {
						threat=unit,
						facing=facing,
						lost=false,
						_sim=sim,
						_losByFacing={},
						_peripheralLosByFacing={},
						predictLos=trackerPredictLos,
						predictPeripheralLos=trackerPredictPeripheralLos,
					}
					table.insert(trackingThreats, tracker)
					tracking = true
				elseif senses:hasLostTarget(selectedUnit) then
					local facing = unit:getFacing()
					local tracker = {
						threat=unit,
						facing=facing,
						lost=true,
						_sim=sim,
						_losByFacing={},
						_peripheralLosByFacing={},
						predictLos=trackerPredictLos,
						predictPeripheralLos=trackerPredictPeripheralLos,
					}
					table.insert(trackingThreats, tracker)
					tracking = true
				end
			end
			if not tracking then
				table.insert(threats, unit)
			end
		end
	end

	return threats, trackingThreats
end

local function isWatchedByThreat(sim, threats, selectedUnit, cell)
	local seers = sim:getLOS():getSeers(cell.x, cell.y)
	for _,seerID in ipairs(seers) do
		local threat = array.findIf(threats, function(threat) return threat:getID() == seerID end)
		if threat and simquery.couldUnitSee(sim, threat, selectedUnit, false, cell) then
			return threat
		end
	end
end

local function isTrackingWatched(sim, trackingThreats, selectedUnit, cell, prevCell)
	local foundThreat = nil
	for _,tracker in ipairs(trackingThreats) do
		local threat = tracker.threat
		local tx,ty = threat:getLocation()
		local facing = simquery.getDirectionFromDelta(cell.x-tx, cell.y-ty)

		local couldSee = simquery.couldUnitSee(sim, threat, selectedUnit, false, cell)

		local watchedCells
		if not tracker.lost then
			-- Threat will turn to face immediately.
			watchedCells = tracker:predictLos(facing)
		elseif couldSee and tracker:predictPeripheralLos(tracker.facing)[cell.id] and not simquery.checkCover(sim, threat, prevCell.x, prevCell.y) then
			-- We just stepped into peripheral from a visible cell.
			-- Threat will turn to face the previous cell.
			tracker.facing = simquery.getDirectionFromDelta(prevCell.x-tx, prevCell.y-ty)
			watchedCells = tracker:predictLos(tracker.facing)
		else
			-- Threat is watching cells based on last known facing.
			watchedCells = tracker:predictLos(tracker.facing)
		end

		if couldSee and watchedCells[cell.id] then
			-- Threat will see us.
			tracker.lost = false
			tracker.facing = facing
			foundThreat = foundThreat or threat
			simlog("UITR: %s %d,%d facing=%d SHOT", threat:getName(), cell.x, cell.y, tracker.facing)
		elseif not tracker.lost or (couldSee and tracker:predictPeripheralLos(tracker.facing)[cell.id]) then
			-- We just left sight, or we are stepping through peripheral.
			-- Threat will turn to track.
			tracker.lost = true
			tracker.facing = facing
			simlog("UITR: %s %d,%d facing=%d TURN", threat:getName(), cell.x, cell.y, tracker.facing)
		else
			simlog("UITR: %s %d,%d facing=%d", threat:getName(), cell.x, cell.y, tracker.facing)
		end
	end
	return foundThreat
end

local function newShootProp(self, cell, color)
	local shootTex = resources.find("uitrShoot")
	local x,y = self:cellToWorld( cell.x, cell.y )

	local prop = MOAIProp2D.new()
	prop:setDeck(shootTex)
	prop:setLoc(x,y)
	if color then
		prop:setColor(color.r, color.g, color.b, color.a)
	else
		prop:setColor(cdefs.COLOR_WATCHED_BOLD:unpack())
	end
	return prop
end

-- ===

local oldChainCells = boardrig.chainCells
local oldUnchainCells = boardrig.unchainCells

function boardrig:chainCells( cells, color, ... )
	local id = oldChainCells( self, cells, color, ... )
	local selectedUnit = self._game.hud:getSelectedUnit()
	local sim = self:getSim()

	local uiTweaks = sim:getParams().difficultyOptions.uiTweaks
	if not selectedUnit or not uiTweaks then
		return id
	end

	-- Identify threats that could shoot us.
	local threats, trackingThreats = findThreats(sim, selectedUnit)
	if not next(threats) and not next(trackingThreats) then
		return id
	end

	-- Mark movement cells that get us shot.
	local fgProps = {}
	local prevCell = nil
	for i,coord in ipairs(cells) do
		local cell = sim:getCell(coord.x, coord.y)
		if not prevCell then
			-- Skip the origin cell of the path.
		elseif isWatchedByThreat(sim, threats, selectedUnit, cell) then
			table.insert(fgProps, newShootProp(self, cell, color))
		elseif isTrackingWatched(sim, trackingThreats, selectedUnit, cell, prevCell) then
			table.insert(fgProps, newShootProp(self, cell, color))
		end
		prevCell = cell
	end

	local layer = self:getLayer("ceiling")
	for _,prop in ipairs(fgProps) do
		layer:insertProp(prop)
	end
	self._chainCells[ id ].fgProps = fgProps

	return id
end

function boardrig:unchainCells( id, ... )
	local chain = self._chainCells[ id ]
	if chain and chain.fgProps then
		local layer = self:getLayer("ceiling")
		for _,prop in ipairs(chain.fgProps) do
			layer:removeProp(prop)
		end
	end

	oldUnchainCells( self, id, ... )
end
