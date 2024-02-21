--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local PiggyClickerMailData = class("PiggyClickerMailData", BaseClientMailData)

function PiggyClickerMailData:ctor()
    PiggyClickerMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function PiggyClickerMailData:getExpireTime()
    local gameData = self.gameData
    if gameData then
        return gameData:getExpireAt() * 0.001
    else
        return 0
    end
end

return PiggyClickerMailData