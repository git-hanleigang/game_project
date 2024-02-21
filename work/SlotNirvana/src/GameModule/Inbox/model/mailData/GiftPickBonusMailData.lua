--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local GiftPickBonusMailData = class("GiftPickBonusMailData", BaseClientMailData)

function GiftPickBonusMailData:ctor()
    GiftPickBonusMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function GiftPickBonusMailData:getExpireTime()
    -- nGameIndex:通过小游戏唯一索引id获得小游戏的数据
    local nGameIndex = self.nIndex
    local starPickMgr = G_GetMgr(G_REF.GiftPickBonus)
    local starPickData = starPickMgr:getData()
    if starPickData then
        local pGameData = starPickData:getPickGameDataById(nGameIndex)
        local expireTime = pGameData:getExpireAt()
        return math.max(math.floor(expireTime / 1000), 0)
    else
        return 0
    end
end

return GiftPickBonusMailData