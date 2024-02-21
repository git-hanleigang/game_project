--[[
    鲨鱼游戏道具化促销
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require("baseActivity.BaseActivityData")
local MythicGameSaleData = class("MythicGameSaleData",BaseActivityData)

-- message MythicGameSale {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional string coins = 4;
--     repeated ShopItem items = 5;
--     optional int32 remainingTimes = 6;//剩余购买次数
--     optional string key = 7;
--     optional string keyId = 8;
--     optional string price = 9;
--   }
function MythicGameSaleData:parseData(_data)
    MythicGameSaleData.super.parseData(self, _data)

    self.p_coins = tonumber(_data.coins)
    self.p_remainingTimes = _data.remainingTimes or 0
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_items = self:parseItems(_data.items)
end

function MythicGameSaleData:parseItems(_items)
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

function MythicGameSaleData:getKeyId()
    return self.p_keyId
end

function MythicGameSaleData:getPrice()
    return self.p_price
end

function MythicGameSaleData:getCoins()
    return self.p_coins
end

function MythicGameSaleData:getRemainingTimes()
    return self.p_remainingTimes or 0
end

function MythicGameSaleData:getItems()
    return self.p_items
end

function MythicGameSaleData:checkCompleteCondition()
    local times = self.p_remainingTimes or 0
    return times <= 0
end

function MythicGameSaleData:isRunning()
    local flag = MythicGameSaleData.super.isRunning(self)

    if flag then
        flag = not self:isCompleted()
    end

    return flag
end

return MythicGameSaleData
