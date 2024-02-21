--[[
    宠物规则宣传
]]
local PetRuleMgr = class("PetRuleMgr", BaseActivityControl)

function PetRuleMgr:ctor()
    PetRuleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PetRule)
end

function PetRuleMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function PetRuleMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function PetRuleMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return PetRuleMgr
