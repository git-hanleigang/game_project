--[[
    手动发的补偿邮件
]]

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_giftCode = class("InboxItem_giftCode", InboxItem_base)

function InboxItem_giftCode:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_giftCode:getCardSource()
    return {"Gift Code"}
end
-- 描述说明
function InboxItem_giftCode:getDescStr()
    self.m_content = self.m_mailData.content
    if self.m_content and self.m_content ~= "" then
        self:setButtonLabelContent("btn_inbox", "SEE MORE")
    end
    return self.m_mailData.title or ""
end

function InboxItem_giftCode:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    local name = sender:getName()
    if name == "btn_inbox" then
        G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
        sender:setTouchEnabled(false)
        if self.m_content ~= "" then
            local mailData = self.m_mailData
            local view = util_createView("views.inbox.item.InboxItem_PageLayerSendGift", mailData)
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        else
            self:collectBonus()
        end
    end
end

function InboxItem_giftCode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if tonumber(params.id) == tonumber(self.m_mailData.id) then
                -- self:collectBonus()
                if self.m_removeMySelf ~= nil then
                    --刷新界面
                    self.m_removeMySelf(self)
                end
            end
        end,
        ViewEventType.NOTIFY_INBOX_GIFT_COLLECT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if tonumber(params.id) == tonumber(self.m_mailData.id) then
                G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)
                self:findChild("btn_inbox"):setTouchEnabled(true)
            end
        end,
        ViewEventType.NOTIFY_INBOX_GIFT_END
    )

    InboxItem_giftCode.super.onEnter(self)
end

function InboxItem_giftCode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_giftCode
