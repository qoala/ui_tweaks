local resources = include("resources")

local function initUitrResources()
    local quad = MOAIGfxQuad2D.new()
    quad:setTexture(resources.getPath("uitr/aim.png"))
    quad:setRect(-10, -10, 10, 10)
    resources.insertResource("uitrShoot", quad)
    local quad = MOAIGfxQuad2D.new()
    quad:setTexture(resources.getPath("uitr/shout-alert.png"))
    quad:setRect(-10, -10, 10, 10)
    resources.insertResource("uitrShoutAlert", quad)
end

return {initUitrResources = initUitrResources}
