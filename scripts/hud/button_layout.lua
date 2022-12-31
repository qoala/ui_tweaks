local button_layout = include("hud/button_layout")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

function button_layout:_newUpdateForce(fx, fy, dx, dy, mag, id0, id1)
    if mag then
        maxDist = self._tuning.repulseDist
        local d = math.sqrt(dx * dx + dy * dy)
        if d < 1 then
            if type(id0) ~= "number" or type(id1) ~= "number" or id0 == id1 then
                mag = 0
            elseif id1 > id0 then
                dx, dy = math.cos(2 * math.pi * (id1 - id0 / 100)),
                         math.sin(2 * math.pi * (id1 - id0 / 100))
            else
                dx, dy = -math.cos(2 * math.pi * (id0 - id1 / 100)),
                         -math.sin(2 * math.pi * (id0 - id1 / 100))
            end
        elseif d > maxDist * 4 then
            mag = 0
        else
            mag = mag * math.min(1, (maxDist * maxDist) / (d * d)) -- inverse sqr mag.
            dx, dy = dx / d, dy / d
        end

        fx, fy = fx + mag * dx, fy + mag * dy
    end
    return fx, fy
end

local oldCalculateForce = button_layout.calculateForce
function button_layout:calculateForce(layoutID, layout, statics)
    if not uitr_util.checkOption("mainframeLayout") then
        return oldCalculateForce(self, layoutID, layout, statics)
    end

    local fx, fy = 0, 0
    local l = layout[layoutID]
    for i = 1, #l.widgets do
        local x0, y0, r0 = self:getCircle(layoutID, i)
        for w2, ll in pairs(layout) do
            if w2 ~= layoutID then
                for j = 1, #ll.widgets do
                    local x1, y1, r1 = self:getCircle(w2, j)
                    fx, fy = self:_newUpdateForce(
                            fx, fy, x0 - x1, y0 - y1, self._tuning.repulseMagnitude, layoutID, w2)
                end
            end
        end
        for i, ll in pairs(statics) do
            local x1, y1 = ll.posx, ll.posy
            fx, fy = self:updateForce(fx, fy, x0 - x1, y0 - y1, self._tuning.repulseMagnitude)
        end
    end

    return fx, fy
end
