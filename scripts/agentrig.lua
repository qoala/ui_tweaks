local agentrig = include( "gameplay/agentrig" ).rig
local cdefs = include( "client_defs" )
local util = include( "modules/util" )

-- Credit for selected highlights to Hekateras and Sizzlefrost.


local oldSelectedToggle = agentrig.selectedToggle
function agentrig:selectedToggle(toggle, ...)
	oldSelectedToggle(self, toggle, ...)

	self._uitrSelected = toggle
	self:refreshRenderFilter()
end



-- FOR FILTERING THE RING
local FILTER_COLORS = {
-----------------these three look best for the 'ring' filter!!
["CYAN_SHADE"] = { shader=KLEIAnim.SHADER_FOW,			r=0/255,	g=252/255,	b=255/255,	a=1.0,	lum=1.5 },

["WHITE_SHADE"] = { shader=KLEIAnim.SHADER_FOW,			r=255/255,	g=255/255,	b=255/255,	a=1.0,	lum=1.75 },

["BLUE_SHADE"] = { shader=KLEIAnim.SHADER_FOW,			r=58/255,	g=165/255,	b=255/255,	a=1.0,	lum=1.5 },
}

-- this version colours the HUD circle at the agent's feet instead of the agent. In the table above, I have marked with *** the filters I think look best here. The others were all picked for agent filtering. - Hek

local oldRefreshRenderFilter = agentrig.refreshRenderFilter
function agentrig:refreshRenderFilter(...)
	oldRefreshRenderFilter(self, ...)

	local uiTweaks = self._boardRig:getSim():getParams().difficultyOptions.uiTweaks
	if not uiTweaks or uiTweaks.selectionFilter == false then
		return
	end

	if self._renderFilterOverride then
		-- (override is for the prop. Reset circle to default)
		if self._HUDteamCircle then
			self._HUDteamCircle:setRenderFilter(cdefs.RENDER_FILTERS["default"])
		end
	elseif self._uitrSelected then
		-- Apply selection filters
		if self._HUDteamCircle then
			local paramsColor = uiTweaks.selectionFilter or "CYAN_SHADE"
			local filter = FILTER_COLORS[paramsColor] or cdefs.RENDER_FILTERS["default"]
			self._HUDteamCircle:setRenderFilter( filter )
		end
	else
		-- Not selected. Reset filters.
		if self._HUDteamCircle then
			self._HUDteamCircle:setRenderFilter(cdefs.RENDER_FILTERS["default"])
		end
	end

end

-- this version of the function will colour the unit instead of the HUD circle!

-- FOR FILTERING THE UNIT
-- local FILTER_COLORS = {

-- -------- highlights
-- ["CYAN_HILITE"] = { shader=KLEIAnim.SHADER_HILITE,			r=0/255,	g=252/255,	b=255/255,	a=1.0,	lum=1.0-0.46 },

-- ["BLUE_HILITE"] = { shader=KLEIAnim.SHADER_HILITE,			r=58/255,	g=165/255,	b=255/255,	a=1.0,	lum=1.0-0.46 },

-- ["GREEN_HILITE"] = { shader=KLEIAnim.SHADER_HILITE,			r=0/255,	g=255/255,	b=180/255,	a=1.0,	lum=1.0-0.46 },

-- ["YELLOW_HILITE"] = { shader=KLEIAnim.SHADER_HILITE,			r=247/255,	g=241/255,	b=148/255,	a=1.0,	lum=1.0-0.46 },

-- ["RED_HILITE"] = { shader=KLEIAnim.SHADER_HILITE,			r=255/255,	g=0/255,	b=0/255,	a=1.0,	lum=1.0-0.46 },

-- ["PURPLE_HILITE"] = { shader=KLEIAnim.SHADER_HILITE,			r=229/255,	g=8/255,	b=226/255,	a=1.0,	lum=1.0-0.46 },

-- ------- shaders
-- ["CYAN_SHADE"] = { shader=KLEIAnim.SHADER_FOW,			r=0/255,	g=252/255,	b=255/255,	a=1.0,	lum=2 },

-- ["BLUE_SHADE"] = { shader=KLEIAnim.SHADER_FOW,			r=58/255,	g=165/255,	b=255/255,	a=1.0,	lum=2 },

-- ["GREEN_SHADE"] = { shader=KLEIAnim.SHADER_FOW,			r=0/255,	g=255/255,	b=180/255,	a=1.0,	lum=2 },

-- ["YELLOW_SHADE"] = { shader=KLEIAnim.SHADER_FOW,			r=247/255,	g=241/255,	b=148/255,	a=1.0,	lum=2 },

-- ["RED_SHADE"] = { shader=KLEIAnim.SHADER_FOW,			r=255/255,	g=0/255,	b=0/255,	a=1.0,	lum=2 },

-- ["PURPLE_SHADE"] = { shader=KLEIAnim.SHADER_FOW,			r=229/255,	g=8/255,	b=226/255,	a=1.0,	lum=2 },
-- }


-- function agentrig.refreshRenderFilter(self)
	-- refresh_old(self)

	-- if self._renderFilterOverride then
		-- self._prop:setRenderFilter( self._renderFilterOverride )
	-- else
		-- local unit = self._boardRig:getLastKnownUnit( self._unitID )
		-- if unit then
			-- self._prop:setPlayMode( self._playMode )
			-- if unit:getTraits().selectedFilter and FILTER_COLORS[unit:getTraits().selectedFilter] then
				-- local filter = FILTER_COLORS[unit:getTraits().selectedFilter]
				-- self._prop:setRenderFilter( filter )
			-- end
		-- end
	-- end
-- end
