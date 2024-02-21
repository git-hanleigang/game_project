--[[
    黑五瓜分大奖
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_BlackFridayPoolAward = class("InboxItem_BlackFridayPoolAward", InboxItem_base)

function InboxItem_BlackFridayPoolAward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
-- function InboxItem_BlackFridayPoolAward:getCardSource()
--     return {"Pipe Pass"}
-- end

-- 描述说明
function InboxItem_BlackFridayPoolAward:getDescStr()
    return self.m_mailData.title or "BLACK FRIDAY CARNIVAL GIFT"
end

-- function InboxItem_BlackFridayPoolAward:clickFunc(sender)
--     local _mailDataExtra = json.decode(self.m_mailData.extra)
--     local poolIndex = _mailDataExtra["pool"] or 1
--     local userCoins = _mailDataExtra["coins"] or 0

--     local name = sender:getName()    
--     if name == "btn_inbox" then
--         if G_GetMgr(ACTIVITY_REF.BFDraw):isDownloadRes() then
--             gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
--             G_GetMgr(ACTIVITY_REF.BFDraw):showRewardLayer(self.m_coins, poolIndex, userCoins)
--             self:removeSelfItem()
--         else
--             gLobalViewManager:showDownloadTip()
--         end
--     end
-- end

function InboxItem_BlackFridayPoolAward:collectMailSuccess()
   -- if G_GetMgr(ACTIVITY_REF.BFDraw):isDownloadRes() then
        local _mailDataExtra = json.decode(self.m_mailData.extra)
        if _mailDataExtra then
            local poolIndex = _mailDataExtra["pool"] or 1
            local userCoins = toLongNumber(_mailDataExtra["coins"] or 0)
            local themeName = _mailDataExtra["activityName"] or "Activity_BFCarnival"
            G_GetMgr(ACTIVITY_REF.BFDraw):showRewardLayer(themeName, self.m_coins, poolIndex, userCoins)
            self:removeSelfItem()
       --end
    else
        gLobalViewManager:showDownloadTip()
    end
end

function InboxItem_BlackFridayPoolAward:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

return InboxItem_BlackFridayPoolAward
