--[[
    鲨鱼 小游戏 邮件列表
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_miniGameMythicGame = class("InboxItem_miniGameMythicGame", InboxItem_base)

function InboxItem_miniGameMythicGame:getCsbName()
    return "InBox/InboxItem_CardSeeker.csb"
end

-- 描述说明
function InboxItem_miniGameMythicGame:getDescStr()
    return "MYTHIC GAME", "Don't forget to play it!"
end

function InboxItem_miniGameMythicGame:initView()
    InboxItem_miniGameMythicGame.super.initView(self)

    self:setButtonLabelContent("btn_inbox", "PLAY")
end

-- -- 结束时间(单位：秒)
-- function InboxItem_miniGameMythicGame:getExpireTime()
--     -- nGameId:通过小游戏唯一索引id获得小游戏的数据
--     local nGameId = self.m_mailData.nIndex
--     local data = G_GetMgr(G_REF.MythicGame):getDataById(nGameId)
--     if data then
--         if data:isInited() then
--             local expireTime = data:getExpireAt()
--             return math.max(math.floor(expireTime), 0)
--         elseif data:isPlaying() then
--             return -100
--         end
--     end
--     return 0
-- end

function InboxItem_miniGameMythicGame:initTime()
    local leftTime = self.m_mailData.getExpireTime and self.m_mailData:getExpireTime() or 0
    if leftTime == -100 then
        if self.m_lb_time then
            self.m_lb_time:setString("ONGOING")
        end
    else
        InboxItem_miniGameMythicGame.super.initTime(self)
    end
end

function InboxItem_miniGameMythicGame:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    if name == "btn_inbox" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local nGameId = self.m_mailData.nIndex
        G_GetMgr(G_REF.MythicGame):enterGame(nGameId)
        self:closeInbox()
    end
end

function InboxItem_miniGameMythicGame:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

return InboxItem_miniGameMythicGame
