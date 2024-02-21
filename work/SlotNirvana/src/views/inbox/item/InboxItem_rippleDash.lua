--[[
    rippleDash 活动邮件奖励
]]
local ShopItem = require "data.baseDatas.ShopItem"
local InboxItem_rippleDash = class("InboxItem_rippleDash", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_rippleDash:getCsbName()
    return "InBox/InboxItem_rippleDash.csb"
end

-- 描述说明
function InboxItem_rippleDash:getDescStr()
    return "RIPPLE DASH", "You've got a free RIPPLE DASH"
end

function InboxItem_rippleDash:collectMailSuccess()
    self:gainRewardSuccess()
    self:removeSelfItem()
end

-- 领取成功
function InboxItem_rippleDash:gainRewardSuccess()
    -- 需要做一个通用弹板，因为后面需要
    local coins = toLongNumber(0)
    local items = {}
    if self.m_mailData.awards ~= nil then
        coins:setNum(self.m_mailData.awards.coins)
        if self.m_mailData.awards.items ~= nil then
            for i=1,#self.m_mailData.awards.items do
                local shopItem = ShopItem:create()
                shopItem:parseData(self.m_mailData.awards.items[i], true)
               items[i] = shopItem
            end
        end
    end
    if toLongNumber(coins) > toLongNumber(0) or #items > 0 then
        local callbackfunc = function(  )
            if CardSysManager:needDropCards("Ripple Dash") then
				gLobalNoticManager:addObserver(self, function(sender, func)
					gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
					gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
				end,ViewEventType.NOTIFY_CARD_SYS_OVER)
				CardSysManager:doDropCards("Ripple Dash")
			else
				gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
			end
        end
        local propList = {}
        local reward = items
        if reward ~= nil and #reward > 0 then -- 有奖励的话,先把奖励赋值
            propList = clone(reward)
        end
        if toLongNumber(coins) > toLongNumber(0) then
            propList[#propList +1] = gLobalItemManager:createLocalItemData("Coins",coins,{p_limit = 3})
        end
        local rewardLayer = gLobalItemManager:createRewardLayer(propList,callbackfunc,coins,true)
        gLobalViewManager:showUI(rewardLayer,ViewZorder.ZORDER_UI)
    end
end

return  InboxItem_rippleDash