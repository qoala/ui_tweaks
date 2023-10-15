local reveal_path = include("gameplay/viz_handlers/reveal_path")

-- UITR: Overwrite vanilla.
function reveal_path:onStop()
    -- Stopping: instantly reveal the rest of the path
    local pathRig = self.boardRig:getPathRig()
    pathRig:regeneratePath(self.unitID)
    if not pathRig:_shouldDrawPath(self.unitID) then
        -- Now that the animation has completed, re-apply "should not draw" settings.
        pathRig:refreshProps(nil, pathRig._plannedPathProps[self.unitID], nil)
    end

    local unitRig = self.boardRig:getUnitRig(self.unitID)
    if unitRig then
        unitRig:refreshInterest()
    end
end
