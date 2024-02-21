--[[
    黑五瓜分大奖
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_XmasSplit2023 = class("InboxItem_XmasSplit2023", InboxItem_base)

function InboxItem_XmasSplit2023:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end


-- 描述说明
function InboxItem_XmasSplit2023:getDescStr()
    return self.m_mailData.title or "CHRISTMAS CARNIVAL GIFT"
end

function InboxItem_XmasSplit2023:collectMailSuccess()
    local _mailDataExtra = json.decode(self.m_mailData.extra)
    if _mailDataExtra then
        local poolIndex = _mailDataExtra["pool"] or 1
        local userCoins = toLongNumber(_mailDataExtra["coins"] or 0)
        local themeName = _mailDataExtra["activityName"] or " Activity_XmasSplit2023"
        G_GetMgr(ACTIVITY_REF.XmasSplit2023):showRewardLayer(themeName, self.m_coins, poolIndex, userCoins)
        self:removeSelfItem()
    else
        gLobalViewManager:showDownloadTip()
    end
end

function InboxItem_XmasSplit2023:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

return InboxItem_XmasSplit2023
