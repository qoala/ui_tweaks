local targeting = include( "hud/targeting" )

function cellInLOS(sim, x0, y0, x, y)
	local raycastX, raycastY = sim:getLOS():raycast(x0, y0, x, y)
	return raycastX == x and raycastY == y
end

-- Overwrite onDraw.
-- Instead of sim:canPlayerSee, use player:getLastKnownCell. Highlight affected tiles that the player knows about, not just those the player can currently see.
function targeting.throwTarget:onDraw()
	local sim = self.sim
	local player = self.unit:getPlayerOwner()
	if not (self.mx and self.my and self.cells and player) then
		return false
	end

	MOAIGfxDevice.setPenColor(unpack(self._hiliteClr))
	for i = 1, #self.cells, 2 do
		local x, y = self.cells[i], self.cells[i+1]
		if (self._ignoreLOS or cellInLOS(sim, self.mx, self.my, x, y)) and player:getLastKnownCell(sim, x, y) then
			local x0, y0 = self._game:cellToWorld( x + 0.4, y + 0.4 )
			local x1, y1 = self._game:cellToWorld( x - 0.4, y - 0.4 )
			MOAIDraw.fillRect( x0, y0, x1, y1 )
		end
	end
	return true
end
