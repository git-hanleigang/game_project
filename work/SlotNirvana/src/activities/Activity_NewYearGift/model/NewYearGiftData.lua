--[[
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require "baseActivity.BaseActivityData"
local NewYearGiftData = class("NewYearGiftData", BaseActivityData)

-- message EndYearReward {
--     optional string activityId = 1;
--     optional string name = 2;
--     optional string begin = 3;
--     optional int64 expireAt = 4;
--     optional int32 expire = 5;
--     optional int64 coins = 6;
--     repeated ShopItem item = 7;//物品
--     optional string address = 8;//信息填写地址
--     optional bool collect = 9;//奖励是否已领取
       --optional string year = 10;//大R弹板年份
--  }

function NewYearGiftData:parseData(_netData)
    NewYearGiftData.super.parseData(self, _netData)
    
    self.p_coins = tonumber(_netData.coins or 0)
    self.p_items = {}
    if _netData.item and #_netData.item > 0  then
        for i = 1, #_netData.item do 
            local itemData = ShopItem:create()
            itemData:parseData(_netData.item[i])
            table.insert(self.p_items, itemData)
        end
    end
    self.p_address = _netData.address -- "https://www.baidu.com/"
    self.p_collect = _netData.collect
    self.p_year = _netData.year
end

function NewYearGiftData:getCoins()
    return self.p_coins
end

function NewYearGiftData:getItems()
    return self.p_items
end

function NewYearGiftData:getAddress()
    return self.p_address
end

function NewYearGiftData:isCollected()
    return self.p_collect
end

function NewYearGiftData:getYears()
    return self.p_year or "2023"
end

return NewYearGiftData
