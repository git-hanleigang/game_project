--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local PerLinkMailData = class("PerLinkMailData", BaseClientMailData)

function PerLinkMailData:ctor()
    PerLinkMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function PerLinkMailData:getExpireTime()
    local gameId = self.nIndex
    local data = G_GetMgr(G_REF.LeveDashLinko):getData()
    if data then
        local gameData = data:getGameDataById(gameId)
        if gameData then
            return gameData:getExpireAt()
        end
    end
    return 0
end

return PerLinkMailData