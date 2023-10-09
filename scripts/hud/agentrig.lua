local AgentRig = include("gameplay/agentrig").rig
local cdefs = include("client_defs")
local util = include("client_util")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")
local track_colors = include(SCRIPT_PATHS.qed_uitr .. "/features/track_colors")

-- ===
-- Highlighting for Selected Units
-- Credit for selected highlights to Hekateras and Sizzlefrost.

local oldSelectedToggle = AgentRig.selectedToggle
function AgentRig:selectedToggle(toggle, ...)
    oldSelectedToggle(self, toggle, ...)

    self._uitrSelected = toggle
    self:refreshRenderFilter()
end

-- For filtering the unit
local AGENT_FILTER_COLORS = {

    -------- solid highlights
    ["CYAN_HILITE"] = {
        shader = KLEIAnim.SHADER_HILITE,
        r = 0 / 255,
        g = 252 / 255,
        b = 255 / 255,
        a = 1.0,
        lum = 1.0 - 0.46,
    },

    ["BLUE_HILITE"] = {
        shader = KLEIAnim.SHADER_HILITE,
        r = 58 / 255,
        g = 165 / 255,
        b = 255 / 255,
        a = 1.0,
        lum = 1.0 - 0.46,
    },

    ["GREEN_HILITE"] = {
        shader = KLEIAnim.SHADER_HILITE,
        r = 0 / 255,
        g = 255 / 255,
        b = 180 / 255,
        a = 1.0,
        lum = 1.0 - 0.46,
    },

    ["YELLOW_HILITE"] = {
        shader = KLEIAnim.SHADER_HILITE,
        r = 247 / 255,
        g = 241 / 255,
        b = 148 / 255,
        a = 1.0,
        lum = 1.0 - 0.46,
    },

    ["RED_HILITE"] = {
        shader = KLEIAnim.SHADER_HILITE,
        r = 255 / 255,
        g = 0 / 255,
        b = 0 / 255,
        a = 1.0,
        lum = 1.0 - 0.46,
    },

    ["PURPLE_HILITE"] = {
        shader = KLEIAnim.SHADER_HILITE,
        r = 229 / 255,
        g = 8 / 255,
        b = 226 / 255,
        a = 1.0,
        lum = 1.0 - 0.46,
    },

    ------- shaders
    ["CYAN_SHADE"] = {
        shader = KLEIAnim.SHADER_FOW,
        r = 0 / 255,
        g = 252 / 255,
        b = 255 / 255,
        a = 1.0,
        lum = 2,
    },

    ["BLUE_SHADE"] = {
        shader = KLEIAnim.SHADER_FOW,
        r = 58 / 255,
        g = 165 / 255,
        b = 255 / 255,
        a = 1.0,
        lum = 2,
    },

    ["GREEN_SHADE"] = {
        shader = KLEIAnim.SHADER_FOW,
        r = 0 / 255,
        g = 255 / 255,
        b = 180 / 255,
        a = 1.0,
        lum = 2,
    },

    ["YELLOW_SHADE"] = {
        shader = KLEIAnim.SHADER_FOW,
        r = 247 / 255,
        g = 241 / 255,
        b = 148 / 255,
        a = 1.0,
        lum = 2,
    },

    ["RED_SHADE"] = {
        shader = KLEIAnim.SHADER_FOW,
        r = 255 / 255,
        g = 0 / 255,
        b = 0 / 255,
        a = 1.0,
        lum = 2,
    },

    ["PURPLE_SHADE"] = {
        shader = KLEIAnim.SHADER_FOW,
        r = 229 / 255,
        g = 8 / 255,
        b = 226 / 255,
        a = 1.0,
        lum = 2,
    },
}

local AGENT_FILTER_TACTICAL_COLORS = {}
for label, color in pairs(AGENT_FILTER_COLORS) do
    local tactical_color = util.tdupe(color)
    tactical_color.a = 0.8 -- 0.2
    tactical_color.lum = 1.0 -- 1.0-0.41
    AGENT_FILTER_TACTICAL_COLORS[label] = tactical_color
end

-- For filtering the HUD circle below the agent
local TILE_FILTER_COLORS = {
    -----------------these three look best for the 'ring' filter!!
    ["CYAN_SHADE"] = {
        shader = KLEIAnim.SHADER_FOW,
        r = 0 / 255,
        g = 252 / 255,
        b = 255 / 255,
        a = 1.0,
        lum = 1.5,
    },

    ["WHITE_SHADE"] = {
        shader = KLEIAnim.SHADER_FOW,
        r = 255 / 255,
        g = 255 / 255,
        b = 255 / 255,
        a = 1.0,
        lum = 1.75,
    },

    ["BLUE_SHADE"] = {
        shader = KLEIAnim.SHADER_FOW,
        r = 58 / 255,
        g = 165 / 255,
        b = 255 / 255,
        a = 1.0,
        lum = 1.5,
    },

    ["GREEN_SHADE"] = {
        shader = KLEIAnim.SHADER_FOW,
        r = 0 / 255,
        g = 255 / 255,
        b = 180 / 255,
        a = 1.0,
        lum = 1.5,
    },

    ["PURPLE_SHADE"] = {
        shader = KLEIAnim.SHADER_FOW,
        r = 229 / 255,
        g = 8 / 255,
        b = 226 / 255,
        a = 1.0,
        lum = 1.5,
    },
}

-- this version colours the HUD circle at the agent's feet instead of the agent. In the table above, I have marked with *** the filters I think look best here. The others were all picked for agent filtering. - Hek

local function shouldHighlightAgent(uiTweaks, unit, isTacticalView)
    if uiTweaks.selectionFilterAgentColor == false then
        return
    end
    if isTacticalView then
        return uiTweaks.selectionFilterAgentTactical
    else
        -- Don't override invisible filtering.
        return uiTweaks.selectionFilterAgentInWorld and not unit:getTraits().invisible
    end
end
local function shouldHighlightTile(uiTweaks, isTacticalView)
    if uiTweaks.selectionFilterTileColor == false then
        return
    end
    if isTacticalView then
        return uiTweaks.selectionFilterTileTactical
    else
        -- Don't override invisible filtering.
        return uiTweaks.selectionFilterTileInWorld
    end
end

local oldRefreshRenderFilter = AgentRig.refreshRenderFilter
function AgentRig:refreshRenderFilter(...)
    local uiTweaks = uitr_util:getOptions()

    if uiTweaks.selectionFilterStyle ~= false then
        -- Not selected. Reset filters first, in case the old refresh wants to change them.
        self._prop:setRenderFilter(cdefs.RENDER_FILTERS["default"])
        if self._HUDteamCircle then
            self._HUDteamCircle:setRenderFilter(cdefs.RENDER_FILTERS["default"])
        end
    end

    oldRefreshRenderFilter(self, ...)

    local unit = self._boardRig:getLastKnownUnit(self._unitID)
    if ((uiTweaks.selectionFilterTileColor == false and uiTweaks.selectionFilterAgentColor == false) or
            not unit) then
        return
    end

    if self._renderFilterOverride then
        -- (override is for the prop. Reset circle to default)
        if self._HUDteamCircle then
            self._HUDteamCircle:setRenderFilter(cdefs.RENDER_FILTERS["default"])
        end
    elseif self._uitrSelected then
        -- Apply selection filters
        local gfxOptions = self._boardRig._game:getGfxOptions()
        -- (Agent)
        -- Doesn't override cloaking in non-tactical view
        if shouldHighlightAgent(uiTweaks, unit, gfxOptions.bTacticalView) then
            local agentColor = uiTweaks.selectionFilterAgentColor or "BLUE_SHADE"
            local agentFilter
            if gfxOptions.bTacticalView then
                agentFilter = AGENT_FILTER_TACTICAL_COLORS[agentColor] or
                                      cdefs.RENDER_FILTERS["default"]
            else
                agentFilter = AGENT_FILTER_COLORS[agentColor] or cdefs.RENDER_FILTERS["default"]
            end
            self._prop:setRenderFilter(agentFilter)
        end
        -- (Floor tile HUD circle)
        if self._HUDteamCircle and shouldHighlightTile(uiTweaks, gfxOptions.bTacticalView) then
            local tileColor = uiTweaks.selectionFilterTileColor or "CYAN_SHADE"
            local tileFilter = TILE_FILTER_COLORS[tileColor] or cdefs.RENDER_FILTERS["default"]
            self._HUDteamCircle:setRenderFilter(tileFilter)
        end
    end

end

-- ===
-- Colored Tracks for guard interest points.

local oldDrawInterest = AgentRig.drawInterest
function AgentRig:drawInterest(interest, alerted)
    oldDrawInterest(self, interest, alerted)

    if uitr_util.checkOption("coloredTracks") and self.interestProp then
        local color = track_colors:assignColor(self:getUnit())
        self.interestProp:setSymbolModulate("interest_border", color:unpack())
        self.interestProp:setSymbolModulate("down_line", color:unpack())
        self.interestProp:setSymbolModulate("down_line_moving", color:unpack())
        self.interestProp:setSymbolModulate("interest_line_moving", color:unpack())
    end
end
