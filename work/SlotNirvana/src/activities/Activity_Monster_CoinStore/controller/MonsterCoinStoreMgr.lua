--[[
    膨胀宣传 金币商城
]]
local MonsterCoinStoreMgr = class("MonsterCoinStoreMgr", BaseActivityControl)

function MonsterCoinStoreMgr:ctor()
    MonsterCoinStoreMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Monster_CoinStore)
end

function MonsterCoinStoreMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function MonsterCoinStoreMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function MonsterCoinStoreMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return MonsterCoinStoreMgr
