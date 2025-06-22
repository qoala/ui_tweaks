local flagui = include('hud/flag_ui')

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

-- Other half of the changes is in hud/home_panel.lua

local oldRefreshFlag = flagui.refreshFlag

function flagui:refreshFlag(unit, isSelected)
    local sim = self._rig._boardRig:getSim()
    if not uitr_util.checkOption("preciseAp") then
        return oldRefreshFlag(self, unit, isSelected)
    end

    unit = unit or self._rig:getUnit()
    local ret = oldRefreshFlag(self, unit, isSelected)

    if not (unit:getPlayerOwner():isNPC() or unit:isKO() or unit:getTraits().takenDrone) then
        if sim:getCurrentPlayer() == unit:getPlayerOwner() then
            local mp = unit:getMP() - (self._moveCost or 0)
            mp = uitr_util.roundPointFive(math.max(mp, 0))
            self._widget.binder.meters.binder.APnum:setText(mp)
        end
    end
end

