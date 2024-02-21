local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_levelRush = class("InboxItem_levelRush", InboxItem_base)

function InboxItem_levelRush:getCsbName( )
      return "InBox/InboxItem_levelRush.csb"
end
-- 描述说明
function InboxItem_levelRush:getDescStr()
      return "LEVEL DASH GAME", "Don't forget your rewards"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_levelRush:getExpireTime()
--       gLobalLevelRushManager:setLevelRushSource("LevelRushInbox")
--       local nGameIndex = self.m_mailData.nIndex
--       local currGameData = gLobalLevelRushManager:getGameData(nGameIndex)
  
--       if currGameData then
--           return currGameData.m_nExpireAt / 1000
--       else
--             return 0
--       end
-- end
-- 倒计时结束回调
function InboxItem_levelRush:timeEndCallback()
      gLobalLevelRushManager:setLevelRushSource(nil)
end

function InboxItem_levelRush:clickFunc(sender)
      local name = sender:getName()
      local tag = sender:getTag()
      if name == "btn_inbox" then
            local nGameIndex = self.m_mailData.nIndex
            local bGameInit = gLobalLevelRushManager:pubCheckGameInit(nGameIndex)
            if bGameInit then
                  gLobalLevelRushManager:pubShowLevelRush(nGameIndex)
            else
                  gLobalLevelRushManager:pubRequestGameData(nGameIndex)
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
      end
end

return  InboxItem_levelRush