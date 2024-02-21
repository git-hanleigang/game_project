--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local PokerRecallMailData = class("PokerRecallMailData", BaseClientMailData)

function PokerRecallMailData:ctor()
    PokerRecallMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function PokerRecallMailData:getExpireTime()
    -- nGameIndex:通过小游戏唯一索引id获得小游戏的数据
    local nGameIndex = self.nIndex
    local pokerRecallMgr = G_GetMgr(G_REF.PokerRecall)
    local pokerRecallData = pokerRecallMgr:getData()
    if pokerRecallData then
        local pGameData = pokerRecallData:getCurPokerGameDataById(nGameIndex)
        if not pGameData then
            return 0
        end
        local expireTime = pGameData:getExpireAt()
        return math.max(math.floor(expireTime / 1000), 0)
    else
        return 0
    end
end

return PokerRecallMailData