--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local DuckShotMailData = class("DuckShotMailData", BaseClientMailData)

function DuckShotMailData:ctor()
    DuckShotMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function DuckShotMailData:getExpireTime()
    local nGameIndex = self.nIndex
    local currGameData = G_GetMgr(ACTIVITY_REF.DuckShot):getDuckShotGameDataByIndex(nGameIndex)
    if currGameData then
        self.m_gameIndex = nGameIndex
        return currGameData:getExpireAt()
    else
        return 0
    end
end

return DuckShotMailData