--[[
    coinPusher排行榜
]]
local CoinPusherShowTopMgr = class("CoinPusherShowTopMgr", BaseActivityControl)

function CoinPusherShowTopMgr:ctor()
    CoinPusherShowTopMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinPusherShowTop)
    self:addPreRef(ACTIVITY_REF.CoinPusher)
end

function CoinPusherShowTopMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function CoinPusherShowTopMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function CoinPusherShowTopMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return CoinPusherShowTopMgr
