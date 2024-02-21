--[[
    2周年
]]
local CommonRewards = require "data.baseDatas.CommonRewards"
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require("baseActivity.BaseActivityData")
local years2Data = class("years2Data",BaseActivityData)


function years2Data:parseData(_data)
    years2Data.super.parseData(self,_data)
    self.p_nextTime = tonumber(_data.nextExpireAt)
    self.p_coins    = tonumber(_data.dayReward.coins)
    self.p_itemList = self:parseRewardItemList(_data.dayReward.items)

    self.p_nextDayReward = nil
    if _data:HasField("nextDayReward") then -- 下一天奖励，已经是最后一天了，该值则为null
        local reward = CommonRewards:create()
        reward:parseData(_data.nextDayReward)
        self.p_nextDayReward = reward
    end
end

function years2Data:parseRewardItemList(_reward)
    -- 通用道具
    local itemsData = {}
    if _reward and #_reward > 0 then 
        for i,v in ipairs(_reward) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            if tempData.p_icon and string.find(tempData.p_icon,"Coupon") then 
                tempData.p_icon = "Coupon"
            elseif tempData.p_icon and string.find(tempData.p_icon,"GemSale") then 
                tempData.p_icon = "GemSale"
            end
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function years2Data:getCoins()
    return self.p_coins
end

function years2Data:getItems()
    return self.p_itemList
end

function years2Data:getReward()
    return self.p_coins, self.p_itemList
end

function years2Data:getNextTime()
    return (self.p_nextTime or 0) / 1000
end

function years2Data:getNextDayReward()
    return self.p_nextDayReward
end

return years2Data
