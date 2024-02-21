--[[
    Lottery乐透
]]
local LotteryOpenManager = class("LotteryOpenManager", BaseActivityControl)

function LotteryOpenManager:ctor()
    LotteryOpenManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LotteryOpen)
end

return LotteryOpenManager
