local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_miniGameDartsNew = class("InboxItem_miniGameDartsNew", InboxItem_base)

function InboxItem_miniGameDartsNew:initUI()
    InboxItem_miniGameDartsNew.super.initUI(self)
end

function InboxItem_miniGameDartsNew:getCsbName()
    return "InBox/InboxItem_DartBallon.csb"
end

-- 描述说明
function InboxItem_miniGameDartsNew:getDescStr()
    return "POP BALLOONS TO WIN BIG REWARDS!", "POP BALLOONS TO WIN BIG REWARDS!"
end

-- -- 结束时间(单位：秒)
-- function InboxItem_miniGameDartsNew:getExpireTime()
--     local gameData = self.m_mailData.gameData
--     if gameData then
--         return gameData:getExpirationTime()
--     else
--         return -1
--     end
-- end

function InboxItem_miniGameDartsNew:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_inbox" then
        if G_GetMgr(ACTIVITY_REF.DartsGameNew):isDownloadRes() then
            local gameData = self.m_mailData.gameData
            if gameData and gameData:canPlay() then
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
                G_GetMgr(ACTIVITY_REF.DartsGameNew):onClickMail(gameData:getIndex())
                self:closeInbox()
            end
        else
            gLobalViewManager:showDownloadTip()
        end
    end
end

function InboxItem_miniGameDartsNew:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

return InboxItem_miniGameDartsNew
