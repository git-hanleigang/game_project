--[[
    鲨鱼 小游戏 邮件列表
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_MiniGameTreasureSeeker = class("InboxItem_MiniGameTreasureSeeker", InboxItem_base)

function InboxItem_MiniGameTreasureSeeker:getCsbName()
    return "InBox/InboxItem_miniGameTreasureSeeker.csb"
end
-- 描述说明
function InboxItem_MiniGameTreasureSeeker:getDescStr()
    return "TREASURE SEEKER", "Don't forget to play it!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_MiniGameTreasureSeeker:getExpireTime()
--     -- nGameId:通过小游戏唯一索引id获得小游戏的数据
--     local nGameId = self.m_mailData.nIndex
--     local data = G_GetMgr(G_REF.TreasureSeeker):getData()
--     if data then
--         local pGameData = data:getGameDataById(nGameId)
--         if pGameData:isInited() then
--             local expireTime = pGameData:getExpireAt()
--             return math.max(math.floor(expireTime / 1000), 0)
--         else
--             return 0
--         end
--     else
--         return 0
--     end
-- end

function InboxItem_MiniGameTreasureSeeker:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    if name == "btn_inbox" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local nGameId = self.m_mailData.nIndex
        G_GetMgr(G_REF.TreasureSeeker):enterGame(nGameId)
        self:closeInbox()
    end
end

function InboxItem_MiniGameTreasureSeeker:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

return InboxItem_MiniGameTreasureSeeker
