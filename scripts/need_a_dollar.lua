
-- not the most elegant way to pull this off, but
-- better than monkey-patching the giant "can loot" function.
--
local aiplayer = include('sim/aiplayer')
local simquery = include('sim/simquery')

local function createGuard(originalFunction, self, sim,unitType)
	local unit = originalFunction(self, sim, unitType)

	if not unit:getTraits().isDrone and unit:getTraits().cashOnHand == 0 then
	unit:getTraits().cashOnHand = 1
	end

	return unit
end

local function calculateCashOnHand( originalFunction, sim, unit )
	local value = unit:getTraits().cashOnHand
	if value == 1 then
	return value
	else
	return originalFunction(sim, unit)
	end
end

local patches = {
	{ package = aiplayer, name = 'createGuard', f = createGuard },
	{ package = simquery, name = 'calculateCashOnHand', f = calculateCashOnHand }

}

return monkeyPatch(patches)
