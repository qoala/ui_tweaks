-- Modified copy of mui/mui/mui_lineleader
-- Changes at UITR:

local array = require( "modules/array" )
local util = require( "modules/util" )
local mathutil = require( "modules/mathutil" )
local mui_defs = require( "mui/mui_defs" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_texture = require( "mui/widgets/mui_texture" )
local mui_component = require( "mui/widgets/mui_component" )
local mui_container = require( "mui/widgets/mui_container" )

--------------------------------------------------------
--

local mui_leader_script = class( mui_component )

function mui_leader_script:init( screen, def )
	local deck = MOAIScriptDeck.new()
	deck:setDrawCallback(
		function( index, xOff, yOff, xFlip, yFlip )
			local t = 1.0
			if self._timer then
				t = self._t0 + (1.0 - self._t0) * self._timer:getTime() / self._timer:getPeriod()
			end
			-- UITR: No opacity.
			MOAIGfxDevice.setPenColor( 1.0, 1.0, 1.0, 1.0 )
			-- UITR: Thicker line.
			MOAIGfxDevice.setPenWidth( def.lineWidth )
			-- UITR: Only 1 line segment. Line goes directly to the button, instead of an underline.
			--       Line segment starts partway to the target, to start at the edge of the target circle.
			local x0, y0 = mathutil.lerp( 0, self._x1, self._t0 ), mathutil.lerp( 0, self._y1, self._t0 )
			local x1, y1 = mathutil.lerp( 0, self._x1, t ), mathutil.lerp( 0, self._y1, t )
			MOAIDraw.drawLine( x0, y0, x1, y1 )
		end )
	self._deck = deck

	local prop = MOAIProp2D.new()
	prop:setDeck( deck )

	mui_component.init( self, prop, def)

	self._t0 = 0
	self._x1, self._y1 = 0.1, 0.1
end

function mui_leader_script:setTarget( t0, x1, y1 )
	self._t0 = t0
	self._x1, self._y1 = x1, y1
end

function mui_leader_script:animate( duration, mode )
	if self._timer then
		self._timer:stop()
		self._timer = nil
	end

	if duration and mode then
		local timer = MOAITimer.new()
		timer:setSpan ( 0, duration )
		timer:setMode( mode )
		timer:start()
		self._timer = timer
	end
end

--------------------------------------------------------

local mui_lineleader = class( mui_widget )

function mui_lineleader:init( screen, def )
	mui_widget.init( self, def )

	self._targetImage = mui_texture( screen, util.inherit( def ) { x = 0, y = 0, noInput = true } )
	self._targetImage:setImageState( "target" )
	self._script = mui_leader_script( screen, { x = 0, y = 0, w = 0, h = 0, noInput = true, lineWidth = def.lineWidth } )

	self._cont = mui_container( def )
	self._cont:addComponent( self._script )
	self._cont:addComponent( self._targetImage )
end

function mui_lineleader:setTarget( t0, x1, y1 )
	self._script:setTarget( t0, x1, y1 )
end

function mui_lineleader:appear( duration )
	self._script:animate( duration, MOAITimer.NORMAL )
end

function mui_lineleader:disappear( duration )
	self._script:animate( duration, MOAITimer.REVERSE )
end

return mui_lineleader
