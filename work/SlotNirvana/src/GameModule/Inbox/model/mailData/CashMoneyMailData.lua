--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local CashMoneyMailData = class("CashMoneyMailData", BaseClientMailData)

function CashMoneyMailData:ctor()
    CashMoneyMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function CashMoneyMailData:getExpireTime()
    local gameId = self.gameId
    local currGameData = G_GetMgr(G_REF.CashMoney):getDataByGameId(gameId)
    if currGameData then
        self.m_gameId = gameId
        local time = currGameData:getExpireAt()
        time = time / 1000
        return time
    else
        return 0
    end
end

return CashMoneyMailData