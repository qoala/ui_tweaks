local cdefs = include("client_defs")
local resources = include("resources")
local array = include("modules/array")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local smokerig = include("gameplay/smokerig").rig

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

-- ===
-- Copy vanilla helper functions for refresh. No changes.

local function createSmokeFx(rig, kanim, rootSymbol, x, y)
    local fxmgr = rig._boardRig._game.fxmgr
    x, y = rig._boardRig:cellToWorld(x, y)

    local args = {
        x = x,
        y = y,
        kanim = kanim,
        symbol = rootSymbol,
        anim = "loop",
        scale = 0.1,
        loop = true,
        layer = rig._boardRig:getLayer(),
    }

    return fxmgr:addAnimFx(args)
end

-- ===

-- UITR: Extract color selection, because we only want to create 1 render filter per rig.
-- Returns true if there's been a change.
function smokerig:_refreshColorDef()
    local color = self:getUnit():getTraits().gasColor
    if not color and self._color then
        self._color = nil
        self._tacticalRenderFilter = cdefs.RENDER_FILTERS["default"]

        return true
    elseif color and (not self._color or (self._color.r ~= color.r) or (self._color.g ~= color.g) or
            (self._color.b ~= color.b) or (color.r and self._color.r ~= color.r)) then
        self._color = {
            r = color.r,
            g = color.g,
            b = color.b,
            -- Mod:Neptune: Allow gas color to specify alpha
            a = color.a or 1,
        }
        self._tacticalRenderFilter = {
            shader = KLEIAnim.SHADER_FOW,
            r = color.r,
            g = color.g,
            b = color.b,
            a = color.a or 1,
            lum = 0.5,
        }
        return true
    end
end

local function applyColor(fx, color)
    fx._prop:setColor(color.r, color.g, color.b, color.a)
    fx._prop:setSymbolModulate("smoke_particles_lt0", color.r, color.g, color.b, color.a)
end

-- UITR: Move visibility update from smokerig:refresh to the FX's own update methods.
-- The rig is deleted before the FX has finished and we need to keep updating from graphics options.
local cloudFxAppend = {}
local edgeFxAppend = {}
function cloudFxAppend:update(rig)
    local gfxOptions = rig._boardRig._game:getGfxOptions()
    self._prop:setVisible(not gfxOptions.bMainframeMode)

    -- UITR: Switch between tactical and in-world effect animations.
    if gfxOptions.bTacticalView then
        self._prop:setCurrentSymbol("tactical")
        self._prop:setRenderFilter(rig._tacticalRenderFilter)
    else
        self._prop:setCurrentSymbol("effect")
        self._prop:setRenderFilter(cdefs.RENDER_FILTERS["default"])
    end
end
function edgeFxAppend:update(rig)
    local gfxOptions = rig._boardRig._game:getGfxOptions()
    self._prop:setVisible(not gfxOptions.bMainframeMode)
end
local function appendFx(fx, rig, append)
    local oldUpdate = fx.update
    function fx:update()
        append.update(self, rig)
        return oldUpdate(self)
    end
end

-- Overwrite :refresh()
-- Changes at CBF, UITR
function smokerig:refresh()
    self:_base().refresh(self)

    local colorUpdated = self:_refreshColorDef()

    -- Smoke aint got no ghosting behaviour.
    local unit = self:getUnit()
    local cloudID = unit:getID()
    local cells = unit:getSmokeCells() or {}
    -- UITR: track which FX are for cells
    local activeCells = {}
    for i, cell in ipairs(cells) do
        activeCells[cell] = true
        if self.smokeFx[cell] == nil then
            -- UITR: Use custom FX that also contains tactical sprites.
            local fx = createSmokeFx(self, "uitr/fx/smoke_grenade", "effect", cell.x, cell.y)
            appendFx(fx, self, cloudFxAppend)
            fx._prop:setFrame(math.random(1, fx._prop:getFrameCount()))
            self.smokeFx[cell] = fx
            if self._color then
                applyColor(fx, self._color)
            end
        elseif colorUpdated and self._color then
            applyColor(self.smokeFx[cell], self._color)
        end
    end
    local edgeUnits = unit:getSmokeEdge() or {}
    local activeEdgeUnits = {}
    for i, unitID in ipairs(edgeUnits) do
        -- CBF: Only draw active smoke edges if we're using CBF dynamic smoke edges.
        local edgeUnit = self._boardRig:getSim():getUnit(unitID)
        if edgeUnit and
                (not edgeUnit.isActiveForSmokeCloud or edgeUnit:isActiveForSmokeCloud(cloudID)) then
            activeEdgeUnits[unitID] = true
            if self.smokeFx[unitID] == nil then
                -- UITR: Define both main and edge in a single anim, with different root characters.
                local fx = createSmokeFx(
                        self, "uitr/fx/smoke_grenade", "edgeeffect", edgeUnit:getLocation())
                appendFx(fx, self, edgeFxAppend)
                fx._prop:setFrame(math.random(1, fx._prop:getFrameCount()))
                self.smokeFx[unitID] = fx
                if self._color then
                    applyColor(fx, self._color)
                end
            elseif colorUpdated and self._color then
                applyColor(self.smokeFx[unitID], self._color)
            end
        end
    end

    -- Remove any smoke that no longer exists.
    for k, fx in pairs(self.smokeFx) do
        if activeCells[k] == nil and activeEdgeUnits[k] == nil then
            fx:postLoop("pst")
        end
    end

    -- UITR: Moved the visibility update (hides in mainframe mode) to the individual FX updates.
end
