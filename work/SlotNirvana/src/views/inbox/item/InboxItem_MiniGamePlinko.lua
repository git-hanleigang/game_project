--[[--
    levelrush掉球游戏改版 邮件
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_MiniGamePlinko = class("InboxItem_MiniGamePlinko", InboxItem_base)

function InboxItem_MiniGamePlinko:getCsbName()
    return "InBox/InboxItem_BeerPlinko.csb"
end

-- 描述说明
function InboxItem_MiniGamePlinko:getDescStr()
    return "BEER PLINKO GAME", "Don't forget your rewards"
end

-- -- 结束时间(单位：秒)
-- function InboxItem_MiniGamePlinko:getExpireTime()
--     local gameId = self.m_mailData.nIndex
--     local data = G_GetMgr(G_REF.Plinko):getData()
--     if data then
--         local gameData = data:getGameDataById(gameId)
--         if gameData then
--             return gameData:getExpireAt()
--         end
--     end
--     return 0
-- end

function InboxItem_MiniGamePlinko:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    if name == "btn_inbox" then
        if G_GetMgr(G_REF.Plinko):isDownloadRes() then
            G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
            local data = G_GetMgr(G_REF.Plinko):getData()
            if data then
                local gameId = self.m_mailData.nIndex
                local gameData = data:getGameDataById(gameId)
                if gameData then
                    local isNewGame = false
                    if gameData:getGameStatus() == PlinkoConfig.GameStatus.Init then
                        isNewGame = true
                    end
                    G_GetMgr(G_REF.Plinko):enterGame(gameId, false, isNewGame)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
                end
            end
        else
            gLobalViewManager:showDownloadTip()
        end
    end
end

return InboxItem_MiniGamePlinko
