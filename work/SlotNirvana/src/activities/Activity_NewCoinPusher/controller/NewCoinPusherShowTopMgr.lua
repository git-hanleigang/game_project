--[[
    coinPusher排行榜
]]
local NewCoinPusherShowTopMgr = class("NewCoinPusherShowTopMgr", BaseActivityControl)

function NewCoinPusherShowTopMgr:ctor()
    NewCoinPusherShowTopMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewCoinPusherShowTop)
    self:addPreRef(ACTIVITY_REF.NewCoinPusher)
end

return NewCoinPusherShowTopMgr
