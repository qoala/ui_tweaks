local mui = include( "mui/mui" )
local util = include( "client_util" )
local array = include( "modules/array" )
local serverdefs = include( "modules/serverdefs" )
local gameobj = include( "modules/game" )
local cdefs = include("client_defs")
local agentdefs = include("sim/unitdefs/agentdefs")
local rig_util = include( "gameplay/rig_util" )
local metadefs = include( "sim/metadefs" )
local modalDialog = include( "states/state-modal-dialog" )
local simdefs = include( "sim/simdefs" )


local endCard = class()

function endCard:init()
	self._screen = mui.createScreen("death-dialog.lua")
end

function endCard:show()
	mui.activateScreen(self._screen)

	MOAIFmodDesigner.stopMusic()
	MOAIFmodDesigner.stopSound("theme")
	self._screen.binder.pnl:setVisible(false)
	-- self._screen.binder.blackbg:setVisible(false)
	-- FMODMixer:pushMix("frontend")

    rig_util.wait(2.0 * cdefs.SECONDS)

	MOAIFmodDesigner.playSound("SpySociety/Music/music_title","theme")
	-- MOAIFmodDesigner.playSound("SpySociety/Music/music_map","theme")
	rig_util.wait(0.5 * cdefs.SECONDS)

	local popup = mui.createScreen("modal-end-card.lua")
	mui.activateScreen(popup)
	MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/unlock_agent")
end

function endCard:hide()
	if self._screen:isActive() then
		mui.deactivateScreen( self._screen )
		FMODMixer:popMix("frontend")

		if self._updateThread then
			self._updateThread:stop()
			self._updateThread = nil
		end

		MOAIFmodDesigner.stopSound( "tally" )
	end
end

return endCard
