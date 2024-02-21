--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local PlinkoMailData = class("PlinkoMailData", BaseClientMailData)

function PlinkoMailData:ctor()
    PlinkoMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function PlinkoMailData:getExpireTime()
    local gameId = self.nIndex
    local data = G_GetMgr(G_REF.Plinko):getData()
    if data then
        local gameData = data:getGameDataById(gameId)
        if gameData then
            return gameData:getExpireAt()
        end
    end
    return 0
end

return PlinkoMailData