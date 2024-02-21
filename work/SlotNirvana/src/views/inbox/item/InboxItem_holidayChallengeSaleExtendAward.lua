--[[
    holidayChallenge 节日挑战邮件奖励
]]

local ShopItem = util_require("data.baseDatas.ShopItem")
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_holidayChallengeSaleExtendAward = class("InboxItem_holidayChallengeSaleExtendAward", InboxItem_base)

function InboxItem_holidayChallengeSaleExtendAward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

-- 描述说明
function InboxItem_holidayChallengeSaleExtendAward:getDescStr()
    return  self.m_mailData.title or "SPRING EGG HUNT DOUBLE REWARDS"
end

function InboxItem_holidayChallengeSaleExtendAward:collectMailSuccess()
    self:gainRewardSuccess()
    self:removeSelfItem()
end

-- 领取成功
function InboxItem_holidayChallengeSaleExtendAward:gainRewardSuccess()
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
            if CardSysManager:needDropCards("Holiday Challenge") == true then
                -- 卡包开完消息 只在自己触发掉卡的时候监听 监听早了会被其他地方掉卡影响
                CardSysManager:doDropCards("Holiday Challenge")
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
            -- 刷新高倍场点数
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUEXECLUB_POINT_UPDATE)
        end
        local propList = {}
        if items and #items > 0 then
            for index, value in ipairs(items) do
                propList[#propList +1] = value
            end
        end
        if toLongNumber(coins) > toLongNumber(0) then
            propList[#propList +1] = gLobalItemManager:createLocalItemData("Coins",coins,{p_limit = 3})
        end
        
        if #propList > 0 then
            local rewardLayer = gLobalItemManager:createRewardLayer(propList,callbackfunc,coins,true)
            gLobalViewManager:showUI(rewardLayer,ViewZorder.ZORDER_UI)
        end
    end
end

return  InboxItem_holidayChallengeSaleExtendAward