--[[
    膨胀宣传 免费金币
]]
local MonsterFreeCoinsMgr = class("MonsterFreeCoinsMgr", BaseActivityControl)

function MonsterFreeCoinsMgr:ctor()
    MonsterFreeCoinsMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Monster_FreeCoins)
end

function MonsterFreeCoinsMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function MonsterFreeCoinsMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function MonsterFreeCoinsMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return MonsterFreeCoinsMgr
