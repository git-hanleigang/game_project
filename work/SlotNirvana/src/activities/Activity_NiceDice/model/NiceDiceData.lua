--[[
    2周年
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require("baseActivity.BaseActivityData")
local NiceDiceData = class("NiceDiceData",BaseActivityData)

function NiceDiceData:parseData(_data)
    NiceDiceData.super.parseData(self,_data)

    self.p_bigRewardType = _data.bigRewardType -- 大奖奖励 -1，表示没有大奖
    self.p_diceResult = string.split(_data.diceResult, ";") -- 骰子结果 1-1-2
    self.p_couponItems = self:parseCouponItems(_data.couponItems) -- 促销券道具
    self.p_bigRewards = self:parseBigRewards(_data.bigRewards) -- 大奖奖励
end

function NiceDiceData:parseCouponItems(_reward)
    -- 通用道具
    local itemsData = {}
    if _reward and #_reward > 0 then 
        for i,v in ipairs(_reward) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            if tempData.p_icon and tempData.p_icon == "Coupon_ND_Coin" then 
                tempData.p_icon = "Coupon"
            elseif tempData.p_icon and tempData.p_icon == "Coupon_ND_Gem" then 
                tempData.p_icon = "GemSale"
            elseif tempData.p_icon and tempData.p_icon == "Coupon_ND_Piggy" then 
                tempData.p_icon = "Piggy_coupon"
            end
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function NiceDiceData:parseBigRewards(_reward)
    -- 通用道具
    local itemsData = {}
    itemsData.p_coins = tonumber(_reward.coins)
    itemsData.p_coinValue = _reward.coinValue
    itemsData.p_items = self:parseItems(_reward.items)
    return itemsData
end

function NiceDiceData:parseItems(_items)
    -- 通用道具
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function NiceDiceData:getCouponItems()
    return self.p_couponItems
end

function NiceDiceData:getBigRewards()
    return self.p_bigRewards
end

function NiceDiceData:getDiceResult()
    return self.p_diceResult    
end

function NiceDiceData:getBigRewardType()
    return self.p_bigRewardType
end

return NiceDiceData
