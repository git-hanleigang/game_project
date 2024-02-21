--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local MythicGameMailData = class("MythicGameMailData", BaseClientMailData)

function MythicGameMailData:ctor()
    MythicGameMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function MythicGameMailData:getExpireTime()
    -- nGameId:通过小游戏唯一索引id获得小游戏的数据
    local nGameId = self.nIndex
    local data = G_GetMgr(G_REF.MythicGame):getDataById(nGameId)
    if data then
        if data:isInited() then
            local expireTime = data:getExpireAt()
            return math.max(math.floor(expireTime), 0)
        elseif data:isPlaying() then
            return -100
        end
    end
    return 0
end

return MythicGameMailData