--[[
    coinPusher排行榜
]]
local EgyptCoinPusherShowTopMgr = class("EgyptCoinPusherShowTopMgr", BaseActivityControl)

function EgyptCoinPusherShowTopMgr:ctor()
    EgyptCoinPusherShowTopMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.EgyptCoinPusherShowTop)
    self:addPreRef(ACTIVITY_REF.EgyptCoinPusher)
end

function EgyptCoinPusherShowTopMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function EgyptCoinPusherShowTopMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function EgyptCoinPusherShowTopMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

function EgyptCoinPusherShowTopMgr:showPopLayer(popInfo, callback)
    if popInfo and type(popInfo) == "table" and popInfo.clickFlag then
        return G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):showSelectLayer()
    else
        return EgyptCoinPusherShowTopMgr.super.showPopLayer(self, popInfo, callback)
    end
end

return EgyptCoinPusherShowTopMgr
