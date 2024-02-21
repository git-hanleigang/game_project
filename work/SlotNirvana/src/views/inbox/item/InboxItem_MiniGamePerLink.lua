--[[--
    levelrush掉球游戏改版 邮件
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_MiniGamePerLink = class("InboxItem_MiniGamePerLink", InboxItem_base)

function InboxItem_MiniGamePerLink:getCsbName()
    return "InBox/InboxItem_LevelDash_Link.csb"
end

-- 描述说明
function InboxItem_MiniGamePerLink:getDescStr()
    return "PEARLS LINK GAME", "Don't forget your rewards"
end

-- -- 结束时间(单位：秒)
-- function InboxItem_MiniGamePerLink:getExpireTime()
--     local gameId = self.m_mailData.nIndex
--     local data = G_GetMgr(G_REF.LeveDashLinko):getData()
--     if data then
--         local gameData = data:getGameDataById(gameId)
--         if gameData then
--             return gameData:getExpireAt()
--         end
--     end
--     return 0
-- end

function InboxItem_MiniGamePerLink:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    if name == "btn_inbox" then
         G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
            local data = G_GetMgr(G_REF.LeveDashLinko):getData()
            if data then
                local gameId = self.m_mailData.nIndex
                local gameData = data:getGameDataById(gameId)
                if gameData then
                    local isNewGame = false
                    if gameData:getGameStatus() == PlinkoConfig.GameStatus.Init then
                        isNewGame = true
                    end
                    G_GetMgr(G_REF.LeveDashLinko):enterGame(gameId, false, isNewGame)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
                end
            end
    end
end

return InboxItem_MiniGamePerLink
