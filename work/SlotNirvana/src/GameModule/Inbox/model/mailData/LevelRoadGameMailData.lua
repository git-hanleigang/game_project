--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local LevelRoadGameMailData = class("LevelRoadGameMailData", BaseClientMailData)

function LevelRoadGameMailData:ctor()
    LevelRoadGameMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function LevelRoadGameMailData:getExpireTime()
    local gameData = self.gameData
    if gameData then
        return gameData:getExpirationTime()
    else
        return -1
    end
end

return LevelRoadGameMailData