--[[

]]
local FarmRuleControl = class("FarmRuleControl", BaseActivityControl)

function FarmRuleControl:ctor()
    FarmRuleControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FarmRule_1)
end

function FarmRuleControl:getHallPath(hallName)
    local theme = self:getThemeName()
    return theme .. "/" .. hallName .. "HallNode"
end

function FarmRuleControl:getSlidePath(slideName)
    local theme = self:getThemeName()
    return theme .. "/" .. slideName .. "SlideNode"
end

function FarmRuleControl:getPopPath(popName)
    local theme = self:getThemeName()
    return theme .. "/" .. popName
end

return FarmRuleControl
