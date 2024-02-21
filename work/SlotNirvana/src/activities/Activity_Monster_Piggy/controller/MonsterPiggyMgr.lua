--[[
    膨胀宣传 小猪
]]
local MonsterPiggyMgr = class("MonsterPiggyMgr", BaseActivityControl)

function MonsterPiggyMgr:ctor()
    MonsterPiggyMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Monster_Piggy)
end

function MonsterPiggyMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function MonsterPiggyMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function MonsterPiggyMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return MonsterPiggyMgr
