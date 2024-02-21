local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_miniGameLevelRoad = class("InboxItem_miniGameLevelRoad", InboxItem_base)

function InboxItem_miniGameLevelRoad:initUI()
    InboxItem_miniGameLevelRoad.super.initUI(self)
    
    self:setButtonLabelContent("btn_inbox", "PLAY NOW")
end

function InboxItem_miniGameLevelRoad:getCsbName()
    return "InBox/InboxItem_LevelRoadGame.csb"
end

-- 描述说明
function InboxItem_miniGameLevelRoad:getDescStr()
    return "LEVEL ROAD GAME", "PICK AND WIN BIG PRIZE!"
end

-- -- 结束时间(单位：秒)
-- function InboxItem_miniGameLevelRoad:getExpireTiem()
--     local gameData = self.m_mailData.gameData
--     if gameData then
--         return gameData:getExpirationTime()
--     else
--         return -1
--     end
-- end

function InboxItem_miniGameLevelRoad:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_inbox" then
        if G_GetMgr(ACTIVITY_REF.LevelRoadGame):isDownloadRes() then
            local gameData = self.m_mailData.gameData
            if gameData then
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
                G_GetMgr(ACTIVITY_REF.LevelRoadGame):onClickMail()
                self:closeInbox()
            end
        else
            gLobalViewManager:showDownloadTip()
        end
    end
end

function InboxItem_miniGameLevelRoad:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

return InboxItem_miniGameLevelRoad
