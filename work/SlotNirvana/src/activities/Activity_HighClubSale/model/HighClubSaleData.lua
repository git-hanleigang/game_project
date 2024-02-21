--[[
    高倍场体验卡促销
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require("baseActivity.BaseActivityData")
local HighClubSaleData = class("HighClubSaleData",BaseActivityData)

-- message HighClubSale {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional bool unlock = 4;//是否解锁
--     optional string price = 5;
--     optional string key = 6;
--     optional string keyId = 7;
--     optional int64 coins = 8;
--     repeated ShopItem items = 9;
--   }
function HighClubSaleData:parseData(_data)
    HighClubSaleData.super.parseData(self, _data)

    self.p_unlock = _data.unlock
    self.p_price = _data.price
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_coins = tonumber(_data.coins)
    self.p_items = self:parseItems(_data.items)
end

function HighClubSaleData:parseItems(_items)
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

function HighClubSaleData:getPrice()
    return self.p_price
end

function HighClubSaleData:getKey()
    return self.p_key
end

function HighClubSaleData:getkeyId()
    return self.p_keyId
end

function HighClubSaleData:getCoins()
    return self.p_coins
end

function HighClubSaleData:getItems()
    return self.p_items
end

function HighClubSaleData:isUnlock()
    return self.p_unlock
end

return HighClubSaleData
