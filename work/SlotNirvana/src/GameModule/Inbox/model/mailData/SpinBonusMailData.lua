--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local SpinBonusMailData = class("SpinBonusMailData", BaseClientMailData)

function SpinBonusMailData:ctor()
    SpinBonusMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function SpinBonusMailData:getExpireTime()
    if globalData.spinBonusData and globalData.spinBonusData:isTaskOpen() then
        return tonumber(globalData.spinBonusData.p_taskExpireAt / 1000)
    else
        return 0
    end
end

return SpinBonusMailData