local resources = include("resources")

local function initUitrResources()
    -- Agent Path Warnings
    local quad = MOAIGfxQuad2D.new()
    quad:setTexture(resources.getPath("uitr/aim.png"))
    quad:setRect(-10, -10, 10, 10)
    resources.insertResource("uitrShoot", quad)
    local quad = MOAIGfxQuad2D.new()
    quad:setTexture(resources.getPath("uitr/shout-alert.png"))
    quad:setRect(-10, -10, 10, 10)
    resources.insertResource("uitrShoutAlert", quad)

    -- Guard Track History
    local quad = MOAIGfxQuad2D.new()
    quad:setTexture(resources.getPath("uitr/footprint-trail.png"))
    quad:setRect(-10.6, -10, 10.6, 10)
    resources.insertResource("uitrFootprintTrail", quad)
    local quad = MOAIGfxQuad2D.new()
    quad:setTexture(resources.getPath("uitr/footprint-trail-diag.png"))
    quad:setRect(-10.6, -10*math.sqrt(2), 10.6, 10*math.sqrt(2))
    resources.insertResource("uitrFootprintTrailDiag", quad)
end

return {initUitrResources = initUitrResources}
