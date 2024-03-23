local upgrade_dialog = include("hud/upgrade_dialog")
local skilldefs = include("sim/skilldefs")

local oldUpdateAgent = upgrade_dialog.updateAgent
function upgrade_dialog:updateAgent(agent)
    oldUpdateAgent(self, agent)

    local skills = agent:getSkills()
    for t, widget in self._screen.binder:forEach("skill") do
        local skill = skills[t]

        if skill and not (agent:getTraits().skillLock and agent:getTraits().skillLock[t]) then
            local tempPoints = 0
            if agent:getTraits().temp_skill_points then
                for p, tempskill in ipairs(agent:getTraits().temp_skill_points) do
                    if tempskill == t then
                        tempPoints = tempPoints + 1
                    end
                end
            end

            local actualLevel = skill._currentLevel - tempPoints
            local skillDef = skilldefs.lookupSkill(skill._skillID)

            for i, bar in widget.binder:forEach("metterBar") do
                if i > actualLevel and i <= skillDef.levels then
                    bar.binder.cost:setVisible(true)
                    -- if i > skill._currentLevel then
                    --     local SET_COLOR = {r=244/255,g=255/255,b=120/255, a=1}
                    --     bar.binder.cost:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
                    -- else
                    --     bar.binder.cost:setColor(0,0,0,1)
                    -- end
                end
            end
        end
    end
end
