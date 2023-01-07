-- Unit Rig that loads its kanim as if it were a decor instance.
-- Used for more-easily debugging decor anims.
local cdefs = include("client_defs")
local unitrig = include("gameplay/unitrig")

local decorig = class(unitrig.rig)

function decorig:init(boardRig, unit)
    unitrig.rig.init(self, boardRig, unit)

    self._prop:setCurrentAnim("idle")
    self._prop:setCurrentSymbol("character")
end

function decorig:refreshRenderFilter()
    local gfxOptions = self._boardRig._game:getGfxOptions()
    local prop = self._prop
    if gfxOptions.bMainframeMode then
        prop:setCurrentAnim("idle_icon")
        prop:setRenderFilter(cdefs.RENDER_FILTERS['default'])
    elseif gfxOptions.bTacticalView then
        prop:setCurrentAnim("idle_tac")
        prop:setRenderFilter(cdefs.RENDER_FILTERS['default'])
    else
        prop:setCurrentAnim("idle")
    end
end

return {rig = decorig}
