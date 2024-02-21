local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_miniGameDarts = class("InboxItem_miniGameDarts", InboxItem_base)

function InboxItem_miniGameDarts:initUI()
    InboxItem_miniGameDarts.super.initUI(self)
end

function InboxItem_miniGameDarts:getCsbName()
    return "InBox/InboxItem_DartBallon.csb"
end

-- 描述说明
function InboxItem_miniGameDarts:getDescStr()
    return "POP BALLOONS TO WIN BIG REWARDS!", "POP BALLOONS TO WIN BIG REWARDS!"
end

-- -- 结束时间(单位：秒)
-- function InboxItem_miniGameDarts:getExpireTime()
--     local gameData = self.m_mailData.gameData
--     if gameData then
--         return gameData:getExpirationTime()
--     else
--         return -1
--     end
-- end

function InboxItem_miniGameDarts:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_inbox" then
        if G_GetMgr(ACTIVITY_REF.DartsGame):isDownloadRes() then
            local gameData = self.m_mailData.gameData
            if gameData and gameData:canPlay() then
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
                G_GetMgr(ACTIVITY_REF.DartsGame):onClickMail(gameData:getIndex())
                self:closeInbox()
            end
        else
            gLobalViewManager:showDownloadTip()
        end
    end
end

function InboxItem_miniGameDarts:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

return InboxItem_miniGameDarts
