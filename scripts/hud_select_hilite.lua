local sim = include("sim/engine")
local cdefs = include("client_defs")
local flagui = include("hud/flag_ui")
local boardrig = include("gameplay/boardrig")
local cellrig = include("gameplay/cellrig")
local wallrig = include("gameplay/wallrig2")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local hudFile = include( "hud/hud" )
local util = include("modules/util")

local oldCreateHud = hudFile.createHud
-- thanks to Sizzlefrost for the bulk of this code!

function hudFile.createHud(...)
	local hud = oldCreateHud(...)

	local oldOnSelectUnit = hud.onSelectUnit

	local boardrig = hud._game.boardRig

	function hud.onSelectUnit( self, prevUnit, selectedUnit, ... )
		if prevUnit then
			-- prevUnit:getTraits().selectedFilter = nil 
			prevUnit:getTraits().selectedFilter = "default"
		end
		if selectedUnit and selectedUnit:getSim() and selectedUnit:isPC() then
			local sim = selectedUnit:getSim()
			local paramsColor = sim:getParams().difficultyOptions.uiTweaks and sim:getParams().difficultyOptions.uiTweaks.selectionFilter
			if (paramsColor == nil) or (paramsColor ~= false) then
				local filterColor = paramsColor or "WHITE_SHADE"
				local unit = selectedUnit
				unit:getTraits().selectedFilter = filterColor
				-- sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
			end			
		end
		boardrig:refresh()

	    return oldOnSelectUnit( self, prevUnit, selectedUnit, ... )
	end

	return hud
end