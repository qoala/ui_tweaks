local color = include( "modules/color" )
local pathrig = include( "gameplay/pathrig" )
local agentrig = include( "gameplay/agentrig" )
local util = include( "modules/util" )

PATH_COLORS = {
	color(0,     1,     0.1,   1.0),
	color(1,     1,     0.1,   1.0),
	color(1,     0.7,   0.1,   1.0),
	color(1,     1,     0.6,   1.0),
	color(0.5,   1,     0.7,   1.0),
	color(0,     0.7,   0.7,   1.0),
}

local path_color_idx = 0

local function assignColor( unit )
	local traits = unit:getTraits()
	if not traits.pathColor then
		traits.pathColor = PATH_COLORS[ (path_color_idx % #PATH_COLORS) + 1 ]
		path_color_idx = path_color_idx + 1
	end
	return traits.pathColor
end

local function calculatePathColors( self, unitID, pathPoints )
	local collisions = self._pathCollisions
	local colors = {}
	local unitColor = assignColor( self._boardRig:getSim():getUnit( unitID ) )

	for i = 2, #pathPoints do
		local prevPathPoint, pathPoint = pathPoints[i-1], pathPoints[i]
		local prevPointKey	= prevPathPoint.x .. "." .. prevPathPoint.y
		local pointKey = pathPoint.x .. "." .. pathPoint.y

		local collided = false

		if not collisions[pointKey] then
			collisions[pointKey] = {}
		end

		collisions[pointKey][unitID] = prevPointKey

		for otherUnitID in pairs( collisions[pointKey] ) do
			if unitID ~= otherUnitID and collisions[pointKey][otherUnitID] == prevPointKey then
				collided = true
			end
		end

		if collided then
			table.insert(colors, color(1, 1, 1, 1))
		else
			table.insert(colors, unitColor)
		end
	end

	return colors
end

local function refreshPlannedPath( originalFunction, self, unitID )
	originalFunction( self, unitID )

	if self._plannedPaths[ unitID ] then
		local pathCellColors = calculatePathColors( self, unitID, self._plannedPaths[ unitID ] )

		for i, prop in ipairs(self._plannedPathProps[ unitID ]) do
			prop:setColor( pathCellColors[ i ]:unpack() )
		end
	end
end

local function refreshAllTracks( originalFunction, self )
	self._pathCollisions = {}

	if not self._pathColors then
		self._pathColors = {}
	end

	return originalFunction( self )
end


local function drawInterest( originalFunction, self, interest, alerted )
   originalFunction( self, interest, alerted )
   if self.interestProp then
	   local color = assignColor( self:getUnit() )
	   self.interestProp:setSymbolModulate("interest_border", color:unpack() )
	   self.interestProp:setSymbolModulate("down_line", color:unpack() )
	   self.interestProp:setSymbolModulate("down_line_moving", color:unpack() )
	   self.interestProp:setSymbolModulate("interest_line_moving", color:unpack() )
   end
end


local patches = {
	{ package = pathrig.rig,  name = 'refreshPlannedPath', f = refreshPlannedPath },
	{ package = pathrig.rig,  name = 'refreshAllTracks',   f = refreshAllTracks },
	{ package = agentrig.rig, name = 'drawInterest',       f = drawInterest }
}
return monkeyPatch(patches)
