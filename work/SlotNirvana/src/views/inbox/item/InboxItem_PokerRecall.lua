--[[
Author: dinghansheng dinghansheng@luckxcyy.com
Date: 2022-06-07 14:10:44
LastEditors: dinghansheng dinghansheng@luckxcyy.com
LastEditTime: 2022-06-15 16:21:05
FilePath: /SlotNirvana/src/views/inbox/InboxItem_PokerRecall.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_PokerRecall = class("InboxItem_PokerRecall", InboxItem_base)

function InboxItem_PokerRecall:getCsbName()
    return "InBox/InboxItem_PokerRecall.csb"
end
-- 描述说明
function InboxItem_PokerRecall:getDescStr()
    return "POKER RECALL", "FLOP THE BEST POKER SET AND WIN BIG PRIZE!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_PokerRecall:getExpireTime()
--     -- nGameIndex:通过小游戏唯一索引id获得小游戏的数据
--     local nGameIndex = self.m_mailData.nIndex
--     local pokerRecallMgr = G_GetMgr(G_REF.PokerRecall)
--     local pokerRecallData = pokerRecallMgr:getData()
--     if pokerRecallData then
--         local pGameData = pokerRecallData:getCurPokerGameDataById(nGameIndex)
--         if not pGameData then
--             return 0
--         end
--         local expireTime = pGameData:getExpireAt()
--         return math.max(math.floor(expireTime / 1000), 0)
--     else
--         return 0
--     end
-- end

function InboxItem_PokerRecall:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_inbox" then
        local nGameIndex = self.m_mailData.nIndex
        G_GetMgr(G_REF.PokerRecall):showMainLayer(nGameIndex)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
    end
end

return InboxItem_PokerRecall
