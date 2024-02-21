--[[

]]
local FarmRuleControl2 = class("FarmRuleControl2", BaseActivityControl)

function FarmRuleControl2:ctor()
    FarmRuleControl2.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FarmRule_2)
end

function FarmRuleControl2:getHallPath(hallName)
    local theme = self:getThemeName()
    return theme .. "/" .. hallName .. "HallNode"
end

function FarmRuleControl2:getSlidePath(slideName)
    local theme = self:getThemeName()
    return theme .. "/" .. slideName .. "SlideNode"
end

function FarmRuleControl2:getPopPath(popName)
    local theme = self:getThemeName()
    return theme .. "/" .. popName
end

return FarmRuleControl2
