---
-- 有新版本需要更新
--

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_poker = class("InboxItem_poker", InboxItem_base)

function InboxItem_poker:getCsbName( )
      return "InBox/InboxItem_pokerlink.csb"
end
-- 描述说明
function InboxItem_poker:getDescStr()
      return "THE POKER LINK IS WAITING FOR YOU!", "DON'T FORGET YOUR PRIZE!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_poker:getExpireTime()
--       local levelDashData = G_GetActivityDataByRef(ACTIVITY_REF.LevelDash)
--       if levelDashData then 
--             return tonumber(levelDashData.p_endDayExpireAt / 1000)
--       else
--             return 0
--       end
-- end
-- 倒计时结束回调
function InboxItem_poker:timeEndCallback()
      local levelDashData = G_GetActivityDataByRef(ACTIVITY_REF.LevelDash)
      levelDashData:setLevelDashStatus(LEVEL_DASH_STATUS.WAIT)
end

function InboxItem_poker:clickFunc(sender)
      if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
            return
      end

      local name = sender:getName()
      local tag = sender:getTag()
      if name == "btn_inbox" then
            G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
            local view = nil
            local levelDashData = G_GetActivityDataByRef(ACTIVITY_REF.LevelDash)
            if levelDashData:getLevelDashStatus() == LEVEL_DASH_STATUS.PLAY then
                  view = util_createFindView("Activity/LevelDashSrc/Activity_LevelDash_PokerLinkResult")
            elseif levelDashData:getLevelDashStatus() == LEVEL_DASH_STATUS.REWARD then
                  view = util_createFindView("Activity/LevelDashSrc/Activity_LevelDashResult", levelDashData:getPokerData().winCoins)
            elseif levelDashData:getLevelDashStatus() == LEVEL_DASH_STATUS.GAME then
                  view = util_createFindView("Activity/LevelDashSrc/Activity_LevelDash_PokerLinkPlay")
            end
            if view ~= nil then
                  if gLobalSendDataManager.getLogPopub then
                        gLobalSendDataManager:getLogPopub():addNodeDot(view,name,DotUrlType.UrlName,false)
                  end
                  gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
            else
                  G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)
            end
      end
end

return  InboxItem_poker