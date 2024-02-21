--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local TSMailData = class("TSMailData", BaseClientMailData)

function TSMailData:ctor()
    TSMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function TSMailData:getExpireTime()
    -- nGameId:通过小游戏唯一索引id获得小游戏的数据
    local nGameId = self.nIndex
    local data = G_GetMgr(G_REF.TreasureSeeker):getData()
    if data then
        local pGameData = data:getGameDataById(nGameId)
        if pGameData:isInited() then
            local expireTime = pGameData:getExpireAt()
            return math.max(math.floor(expireTime / 1000), 0)
        else
            return 0
        end
    else
        return 0
    end
end

return TSMailData