--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-19 13:59:24
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-19 15:56:34
FilePath: /SlotNirvana/src/views/inbox/InboxItem_miniGamePiggyClicker.lua
Description: 快速点击小游戏 邮件
--]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local PiggyClickerGameConfig = util_require("GameModule.PiggyClicker.config.PiggyClickerGameConfig")
local InboxItem_miniGamePiggyClicker = class("InboxItem_miniGamePiggyClicker", InboxItem_base)

function InboxItem_miniGamePiggyClicker:getCsbName()
    return "InBox/InboxItem_PiggyClicker.csb"
end
-- 描述说明
function InboxItem_miniGamePiggyClicker:getDescStr()
    return "PIGGY CLICKER", "Hit for rewards!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_miniGamePiggyClicker:getExpireTime()
--     local gameData = self.m_mailData.gameData
--     if gameData then
--         return gameData:getExpireAt() * 0.001
--     else
--         return 0
--     end
-- end

function InboxItem_miniGamePiggyClicker:clickFunc(sender)
    local gameData = self.m_mailData.gameData
    if not gameData or not gameData:checkCanPlay() then
        return
    end
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    if name == "btn_inbox" then
        if G_GetMgr(ACTIVITY_REF.PiggyClicker):isDownloadRes() then
            G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
            self:registerListener()
            G_GetMgr(ACTIVITY_REF.PiggyClicker):sendStartGameReq(gameData)
        else
            gLobalViewManager:showDownloadTip()
        end
    end
end

function InboxItem_miniGamePiggyClicker:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

function InboxItem_miniGamePiggyClicker:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(self, _gameIdx)
            if _gameIdx then
                local view = G_GetMgr(ACTIVITY_REF.PiggyClicker):showMainLayer(_gameIdx)
                if view then
                    self:closeInbox()
                else
                    G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)
                end
            else
                G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)
            end
        end,
        PiggyClickerGameConfig.EVENT_NAME.PIGGY_CLICKER_START_GAME_SUCCESS
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, _gameIdx)
            G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)
        end,
        PiggyClickerGameConfig.EVENT_NAME.PIGGY_CLICKER_START_GAME_FAILD
    )
end

return InboxItem_miniGamePiggyClicker
