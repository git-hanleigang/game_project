--[[
    @desc: mini game LevelFish
    author:csc
    time:2021-06-16 20:21:23
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_miniGameLevelFish = class("InboxItem_miniGameLevelFish", InboxItem_base)

function InboxItem_miniGameLevelFish:getCsbName()
    return "InBox/InboxItem_miniGameLevelFish.csb"
end
-- 描述说明
function InboxItem_miniGameLevelFish:getDescStr()
    return "LEVEL DASH GAME", "Don't forget your rewards"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_miniGameLevelFish:getExpireTime()
--     local nGameIndex = self.m_mailData.nIndex
--     local currGameData = gLobalMiniGameManager:getLevelFishGameDataForIdx(nGameIndex)

--     if currGameData then
--         return tonumber(currGameData.m_nExpireAt) / 1000
--     else
--         return 0
--     end
-- end

function InboxItem_miniGameLevelFish:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_inbox" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
        gLobalMiniGameManager:showLevelFishGameView(self.m_mailData.nIndex)
    end
end

return InboxItem_miniGameLevelFish
