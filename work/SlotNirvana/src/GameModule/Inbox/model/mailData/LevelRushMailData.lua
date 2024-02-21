--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local LevelRushMailData = class("LevelRushMailData", BaseClientMailData)

function LevelRushMailData:ctor()
    LevelRushMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function LevelRushMailData:getExpireTime()
    gLobalLevelRushManager:setLevelRushSource("LevelRushInbox")
    local nGameIndex = self.nIndex
    local currGameData = gLobalLevelRushManager:getGameData(nGameIndex)

    if currGameData then
        return currGameData.m_nExpireAt / 1000
    else
        return 0
    end
end

return LevelRushMailData