--[[
    starpick 小游戏 邮件列表
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_giftPickBonusGame = class("InboxItem_giftPickBonusGame", InboxItem_base)

function InboxItem_giftPickBonusGame:getCsbName()
    return "InBox/InboxItem_giftPickBonus.csb"
end
-- 描述说明
function InboxItem_giftPickBonusGame:getDescStr()
    return "GIFT PICK BONUS", "Pick and win big prizes!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_giftPickBonusGame:getExpireTime()
--     -- nGameIndex:通过小游戏唯一索引id获得小游戏的数据
--     local nGameIndex = self.m_mailData.nIndex
--     local starPickMgr = G_GetMgr(G_REF.GiftPickBonus)
--     local starPickData = starPickMgr:getData()
--     if starPickData then
--         local pGameData = starPickData:getPickGameDataById(nGameIndex)
--         local expireTime = pGameData:getExpireAt()
--         return math.max(math.floor(expireTime / 1000), 0)
--     else
--         return 0
--     end
-- end

function InboxItem_giftPickBonusGame:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_inbox" then
        local nGameIndex = self.m_mailData.nIndex
        G_GetMgr(G_REF.GiftPickBonus):showMainLayer(nGameIndex)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
    end
end

return InboxItem_giftPickBonusGame
