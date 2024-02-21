--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local PBGMailData = class("PBGMailData", BaseClientMailData)

function PBGMailData:ctor()
    PBGMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function PBGMailData:getExpireTime()
    local nGameIndex = self.nIndex
    local currGameData = G_GetMgr(ACTIVITY_REF.PinBallGo):getPinBallGoGameDataByIndex(nGameIndex)
    if currGameData then
        self.m_gameIndex = nGameIndex
        return currGameData:getExpireAt()
    else
        return 0
    end
end

return PBGMailData