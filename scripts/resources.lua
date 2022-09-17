local resources = include( "resources" )

local function initUitrResources()
	local quad = MOAIGfxQuad2D.new ()
	quad:setTexture ( resources.getPath("uitr/aim.png") )
	quad:setRect( -10, -10, 10, 10 )
	resources.insertResource( "uitrShoot", quad )
end

return {
	initUitrResources = initUitrResources,
}
