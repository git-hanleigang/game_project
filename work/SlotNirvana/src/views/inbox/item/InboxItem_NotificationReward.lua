---
-- 推送奖励
--

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_NotificationReward = class("InboxItem_NotificationReward", InboxItem_base)

function InboxItem_NotificationReward:getCsbName()
    return "InBox/InboxItem_Notifaction.csb"
end

function InboxItem_NotificationReward:initView()
    InboxItem_NotificationReward.super.initView(self)

    self:setButtonLabelContent("btn_inbox", "GO TO GET")
end

-- 描述说明
function InboxItem_NotificationReward:getDescStr()
    return "There is a BIG REWARD waiting\nfor you!"
end

function InboxItem_NotificationReward:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    local name = sender:getName()
    if name == "btn_inbox" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)

        local idx = G_GetMgr(ACTIVITY_REF.Entrance):getCellIdxByRefName(ACTIVITY_REF.Notification)
        local layer = G_GetMgr(ACTIVITY_REF.Entrance):showMainLayer(idx)
    end
end

return  InboxItem_NotificationReward