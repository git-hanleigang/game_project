--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local LevelFishMailData = class("LevelFishMailData", BaseClientMailData)

function LevelFishMailData:ctor()
    LevelFishMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function LevelFishMailData:getExpireTime()
    local nGameIndex = self.nIndex
    local currGameData = gLobalMiniGameManager:getLevelFishGameDataForIdx(nGameIndex)

    if currGameData then
        return tonumber(currGameData.m_nExpireAt) / 1000
    else
        return 0
    end
end

return LevelFishMailData