local cdefs = include("client_defs")
local resources = include("resources")
local array = include("modules/array")
local binops = include("modules/binary_ops")
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

local FULL_DIR_MASK = simdefs.DIRMASK_N + simdefs.DIRMASK_E + simdefs.DIRMASK_S + simdefs.DIRMASK_W

-- UITR: Extract color selection, because we only want to create 1 render filter per rig.
-- Returns true if there's been a change.
function smokerig:_refreshColorDef()
    local color = self:getUnit():getTraits().gasColor
    local tacticalColor = self:getUnit():getTraits().gasColorTactical

    local opaqueTrait = self:getUnit():getTraits().gasOpaque
    local isTransparent = (opaqueTrait == false) or
                                  (opaqueTrait == nil and color and color.a and color.a < 0.5)
    self._tacticalSymbol = isTransparent and "tactical_transparent" or "tactical_sightblock"

    if not color and self._color then
        self._color = nil
        self._tacticalSymbol = nil
        self._tacticalRenderFilter = cdefs.RENDER_FILTERS["default"]

        return true
    elseif color and (not self._color or (self._color.r ~= color.r) or (self._color.g ~= color.g) or
            (self._color.b ~= color.b) or (self._color.a ~= (color.a or 1))) then
        self._color = {
            r = color.r,
            g = color.g,
            b = color.b,
            -- Mod:Neptune: Allow gas color to specify alpha
            a = color.a or 1,
        }
        if isTransparent or tacticalColor then
            tacticalColor = tacticalColor or color
            self._tacticalRenderFilter = {
                shader = KLEIAnim.SHADER_FOW,
                r = tacticalColor.r,
                g = tacticalColor.g,
                b = tacticalColor.b,
                a = tacticalColor.a or 1,
                lum = 0.5,
            }
        else
            self._tacticalRenderFilter = cdefs.RENDER_FILTERS["default"]
        end
        return true
    elseif tacticalColor and ((self._tacticalRenderFilter.r ~= tacticalColor.r) or
            (self._tacticalRenderFilter.g ~= tacticalColor.g) or
            (self._tacticalRenderFilter.b ~= tacticalColor.b) or
            (self._tacticalRenderFilter.a ~= (tacticalColor.a or 1))) then
        self._tacticalRenderFilter = {
            shader = KLEIAnim.SHADER_FOW,
            r = tacticalColor.r,
            g = tacticalColor.g,
            b = tacticalColor.b,
            a = tacticalColor.a or 1,
            lum = 0.5,
        }
        return false -- Nothing to do for this in smokerig:refresh().
    end
end

local function applyColor(fx, color)
    fx._prop:setColor(color.r, color.g, color.b, color.a)
    fx._prop:setSymbolModulate("smoke_particles_lt0", color.r, color.g, color.b, color.a)
    fx._prop:setSymbolModulate("edge_smoke_particles_lt0", color.r, color.g, color.b, color.a)
end

-- UITR: Move visibility update from smokerig:refresh to the FX's own update methods.
-- The rig is deleted before the FX has finished and we need to keep updating from graphics options.
local cloudFxAppend = {}
local edgeFxAppend = {}
function cloudFxAppend:update(rig)
    local gfxOptions = rig._boardRig._game:getGfxOptions()
    local prop = self._prop
    prop:setVisible(not gfxOptions.bMainframeMode)

    -- UITR: Switch between tactical and in-world effect animations.
    local tacticalCloudsOpt = uitr_util.checkOption("tacticalClouds")
    if tacticalCloudsOpt ~= false and (gfxOptions.bTacticalView or tacticalCloudsOpt == 2) then
        if not self._uitrData.inTactical then
            self._uitrData.inTactical = true
            if self._uitrData.inPostLoop then
                if prop:getCurrentAnim() == "loop" then -- Force an almost-sync.
                    prop:setFrame(prop:getFrameCount() - 1)
                end
            else
                prop:setFrame(
                        (prop:getFrame() - self._uitrData.inworldOffset) % prop:getFrameCount())
            end
        end
        prop:setCurrentSymbol(rig._tacticalSymbol or "tactical_sightblock")
        prop:setRenderFilter(rig._tacticalRenderFilter)
    else
        if self._uitrData.inTactical then
            self._uitrData.inTactical = false
            if not self._uitrData.inPostLoop then
                prop:setFrame(
                        (prop:getFrame() + self._uitrData.inworldOffset) % prop:getFrameCount())
            end
        end
        prop:setCurrentSymbol("effect")
        prop:setRenderFilter(cdefs.RENDER_FILTERS["default"])
    end
end
DIR_SYMBOLS = {
    [simdefs.DIR_E] = "sightblock_E",
    [simdefs.DIR_N] = "sightblock_N",
    [simdefs.DIR_W] = "sightblock_W",
    [simdefs.DIR_S] = "sightblock_S",
}
function edgeFxAppend:update(rig)
    local gfxOptions = rig._boardRig._game:getGfxOptions()
    local orientation = rig._boardRig._game:getCamera():getOrientation()
    local prop = self._prop
    prop:setVisible(not gfxOptions.bMainframeMode)

    -- UITR: Switch between tactical and in-world effect animations.
    local tacticalCloudsOpt = uitr_util.checkOption("tacticalClouds")
    if tacticalCloudsOpt ~= false and (gfxOptions.bTacticalView or tacticalCloudsOpt == 2) then
        local dirMask = self._uitrData.dirMask
        for dir, symbol in pairs(DIR_SYMBOLS) do
            local dirBit = simdefs:maskFromDir((dir + orientation * 2) % simdefs.DIR_MAX)
            prop:setSymbolVisibility(symbol, binops.test(dirMask, dirBit))
        end

        if not self._uitrData.inTactical then
            self._uitrData.inTactical = true
            if self._uitrData.inPostLoop then
                if prop:getCurrentAnim() == "loop" then -- Force an almost-sync.
                    prop:setFrame(prop:getFrameCount() - 1)
                end
            else
                prop:setFrame(
                        (prop:getFrame() - self._uitrData.inworldOffset) % prop:getFrameCount())
            end
        end
        prop:setCurrentSymbol(rig._tacticalSymbol or "tactical_sightblock")
        prop:setRenderFilter(rig._tacticalRenderFilter)
    else
        if self._uitrData.inTactical then
            self._uitrData.inTactical = false
            if not self._uitrData.inPostLoop then
                prop:setFrame(
                        (prop:getFrame() + self._uitrData.inworldOffset) % prop:getFrameCount())
            end
        end
        prop:setCurrentSymbol("effect_edge")
        prop:setRenderFilter(cdefs.RENDER_FILTERS["default"])
    end
end
local function appendFx(fx, rig, append)
    local oldUpdate = fx.update
    function fx:update()
        append.update(self, rig)
        return oldUpdate(self)
    end
end

-- ===

local oldDestroy = smokerig.destroy
function smokerig:destroy()
    for _, fx in pairs(self.smokeFx) do
        if fx._uitrData then
            fx._uitrData.inPostLoop = true
        end
    end

    oldDestroy(self)
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
            fx._uitrData = {x = cell.x, y = cell.y}
            -- Whole-cloud offset. Tactical anims within a cloud pulse together, but overlapping
            -- clouds should pulse independently.
            local frameCount = fx._prop:getFrameCount()
            self._frameOffset = self._frameOffset or math.random(1, frameCount)
            fx._uitrData.inworldOffset = math.random(1, frameCount)
            fx._prop:setFrame((self._frameOffset + fx._uitrData.inworldOffset) % frameCount)
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
        -- CBF: Only draw active smoke edges when using CBF dynamic smoke edges.
        local edgeUnit = self._boardRig:getSim():getUnit(unitID)
        if edgeUnit and
                (not edgeUnit.isActiveForSmokeCloud or edgeUnit:isActiveForSmokeCloud(cloudID)) then
            activeEdgeUnits[unitID] = true
            local fx
            local dirMask =
                    edgeUnit.dirMaskForSmokeCloud and edgeUnit:dirMaskForSmokeCloud(cloudID) or
                            FULL_DIR_MASK
            if self.smokeFx[unitID] == nil then
                -- UITR: Define both main and edge in a single anim, with different root symbols.
                -- There are separate in-world anims for cloud and edge, but opaque clouds use
                -- the same tactical anim, with symbol-visibility.
                local x, y = edgeUnit:getLocation()
                fx = createSmokeFx(self, "uitr/fx/smoke_grenade", "effect_edge", x, y)
                appendFx(fx, self, edgeFxAppend)
                fx._uitrData = {x = x, y = y}
                fx._prop:setSymbolVisibility("sphere", false) -- No central sphere for edges.
                local frameCount = fx._prop:getFrameCount()
                fx._uitrData.inworldOffset = math.random(1, frameCount)
                fx._prop:setFrame((self._frameOffset + fx._uitrData.inworldOffset) % frameCount)
                self.smokeFx[unitID] = fx
                if self._color then
                    applyColor(fx, self._color)
                end
                simlog("LOG_UITR_TAC", "smokeEdgeRig:add %s,%s dirs=%s", x, y, tostring(dirMask))
            else
                fx = self.smokeFx[unitID]
                if colorUpdated and self._color then
                    applyColor(fx, self._color)
                end
            end
            fx._uitrData.dirMask = dirMask
        end
    end

    -- Remove any smoke that no longer exists.
    for k, fx in pairs(self.smokeFx) do
        if activeCells[k] == nil and activeEdgeUnits[k] == nil then
            simlog(
                    "LOG_UITR_TAC", "smokeEdgeRig:remove %s,%s dirs=%s", tostring(fx._uitrData.x),
                    tostring(fx._uitrData.y), tostring(fx._uitrData.dirMask))
            fx:postLoop("pst")
            if fx._uitrData then
                fx._uitrData.inPostLoop = true
            end

            -- UITR: Drop reference to the old FX (which is asynchronously removing itself),
            -- so that when a temporary edge comes back later, we can create a new FX in that spot.
            self.smokeFx[k] = nil
        end
    end

    -- UITR: Moved the visibility update (hides in mainframe mode) to the individual FX updates.
end
