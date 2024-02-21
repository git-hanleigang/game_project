--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local DartsMailData = class("DartsMailData", BaseClientMailData)

function DartsMailData:ctor()
    DartsMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function DartsMailData:getExpireTime()
    local gameData = self.gameData
    if gameData then
        return gameData:getExpirationTime()
    else
        return -1
    end
end

return DartsMailData