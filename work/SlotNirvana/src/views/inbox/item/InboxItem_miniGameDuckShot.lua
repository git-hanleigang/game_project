--[[
    @desc: mini game LevelFish
    author:csc
    time:2021-06-16 20:21:23
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_miniGameDuckShot = class("InboxItem_miniGameDuckShot", InboxItem_base)

function InboxItem_miniGameDuckShot:getCsbName()
    return "InBox/InboxItem_DuckShot.csb"
end
-- 描述说明
function InboxItem_miniGameDuckShot:getDescStr()
    return "DUCK SHOT", "Shot and win big prize!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_miniGameDuckShot:getExpireTime()
--     local nGameIndex = self.m_mailData.nIndex
--     local currGameData = G_GetMgr(ACTIVITY_REF.DuckShot):getDuckShotGameDataByIndex(nGameIndex)
--     if currGameData then
--         self.m_gameIndex = nGameIndex
--         return currGameData:getExpireAt()
--     else
--         return 0
--     end
-- end

function InboxItem_miniGameDuckShot:initView()
    self.m_gameIndex = self.m_mailData.m_gameIndex
    InboxItem_miniGameDuckShot.super.initView(self)
end

function InboxItem_miniGameDuckShot:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    if name == "btn_inbox" then
        local mgr = G_GetMgr(ACTIVITY_REF.DuckShot)
        if mgr:isDownloadRes() then
            G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
            local playingData = mgr:getPlayStatusDuckShotGameData()
            if playingData then
                self:closeInbox()
                mgr:showDuckShotGameView(playingData)
            else
                self:registerListener()
                mgr:sendGamePlay(self.m_gameIndex)
            end
        else
            gLobalViewManager:showDownloadTip()
        end
    end
end

function InboxItem_miniGameDuckShot:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

function InboxItem_miniGameDuckShot:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params then
                self:closeInbox()
                G_GetMgr(ACTIVITY_REF.DuckShot):showDuckShotGameView()
            else
                G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_ACTIVATE
    )
end

function InboxItem_miniGameDuckShot:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_miniGameDuckShot
