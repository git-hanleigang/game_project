local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_miniGamePinBallGo = class("InboxItem_miniGamePinBallGo", InboxItem_base)

function InboxItem_miniGamePinBallGo:getCsbName()
    return "InBox/InboxItem_PinballGo.csb"
end
-- 描述说明
function InboxItem_miniGamePinBallGo:getDescStr()
    return "PINBALL GO", "Play and win big prizes!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_miniGamePinBallGo:getExpireTime()
--     local nGameIndex = self.m_mailData.nIndex
--     local currGameData = G_GetMgr(ACTIVITY_REF.PinBallGo):getPinBallGoGameDataByIndex(nGameIndex)
--     if currGameData then
--         self.m_gameIndex = nGameIndex
--         return currGameData:getExpireAt()
--     else
--         return 0
--     end
-- end

function InboxItem_miniGamePinBallGo:initView()
    self.m_gameIndex = self.m_mailData.m_gameIndex
    InboxItem_miniGamePinBallGo.super.initView(self)
end

function InboxItem_miniGamePinBallGo:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    if name == "btn_inbox" then
        local mgr = G_GetMgr(ACTIVITY_REF.PinBallGo)
        if mgr:isDownloadRes() then
            G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
            local playingData = mgr:getPlayStatusPinBallGoGameData()
            if playingData then
                self:closeInbox()
                mgr:showPinBallGoGameView(playingData)
            else
                self:registerListener()
                mgr:sendPlayGame(self.m_gameIndex)
            end
        else
            gLobalViewManager:showDownloadTip()
        end
    end
end

function InboxItem_miniGamePinBallGo:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

function InboxItem_miniGamePinBallGo:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params then
                if G_GetMgr(ACTIVITY_REF.PinBallGo):isDownloadRes() then
                    self:closeInbox()
                    G_GetMgr(ACTIVITY_REF.PinBallGo):showPinBallGoGameView()
                else
                    gLobalViewManager:showDownloadTip()
                end
            else
                G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)
            end
        end,
        ViewEventType.NOTIFY_PLAY_PINBALL_GAME
    )
end

function InboxItem_miniGamePinBallGo:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_miniGamePinBallGo
