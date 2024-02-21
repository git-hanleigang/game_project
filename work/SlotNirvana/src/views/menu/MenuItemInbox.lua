--[[

    author:{author}
    time:2022-01-24 11:26:27
]]
local BaseMenuItem = require("views.menu.BaseMenuItem")
local MenuItemInbox = class("MenuItemInbox", BaseMenuItem)

function MenuItemInbox:initUI(bDeluxe)
    MenuItemInbox.super.initUI(self, bDeluxe)
    self:updateNewMessageUi(0)
end

function MenuItemInbox:onEnter()
    MenuItemInbox.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(Target, mailCount)
            self:updateNewMessageUi(mailCount)
        end,
        ViewEventType.NOTIFY_REFRESH_MAIL_COUNT
    )
end

function MenuItemInbox:initView(bDeluxe)
    MenuItemInbox.super.initView(self, bDeluxe)
    if bDeluxe then
        util_changeTexture(self.m_spItemN, "Option/ui/btn_inbox_up1.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_inbox_down1.png")
    else
        util_changeTexture(self.m_spItemN, "Option/ui/btn_inbox_up.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_inbox_down.png")
    end
end

function MenuItemInbox:clickFunc(sender)
    MenuItemInbox.super.clickFunc(self, sender)
    self:onClickInbox(sender)
end

function MenuItemInbox:onClickInbox(sender)
    if gLobalSendDataManager:checkShowNetworkDialog() then
        return
    end
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_inbox)
    end
    if globalFireBaseManager.sendFireBaseLogDirect then
        if G_GetMgr(G_REF.Inbox):getMailCount() > 0 then
            G_GetMgr(G_REF.Inbox):setSourceData(FireBaseLogType.InboxGameTipClick)
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.InboxGameTipOpen)
        else
            G_GetMgr(G_REF.Inbox):setSourceData(FireBaseLogType.InboxGameNotipClick)
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.InboxGameNotipOpen)
        end
    end

    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "inboxSetting")
    G_GetMgr(G_REF.Inbox):showInboxLayer(
        {
            rootStartPos = sender:getTouchEndPosition(),
            senderName = sender:getName(),
            dotUrlType = DotUrlType.UrlName,
            dotEntrySite = DotEntrySite.UpView,
            dotEntryType = gLobalViewManager:isLobbyView() and DotEntryType.Lobby or DotEntryType.Game
        }
    )
end

return MenuItemInbox
