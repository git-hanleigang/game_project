--[[
    黑五瓜分大奖
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_XmasCraze2023 = class("InboxItem_XmasCraze2023", InboxItem_base)

function InboxItem_XmasCraze2023:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

-- 描述说明
function InboxItem_XmasCraze2023:getDescStr()
    return self.m_mailData.title or "PRIZE SHARE FROM CHRISTMAS CRAZE"
end

function InboxItem_XmasCraze2023:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

return InboxItem_XmasCraze2023
