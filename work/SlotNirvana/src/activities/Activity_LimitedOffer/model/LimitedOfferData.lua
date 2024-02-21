--[[
    限时促销
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require("baseActivity.BaseActivityData")
local LimitedOfferData = class("LimitedOfferData",BaseActivityData)

-- message LimitedGift {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated LimitedGiftSale giftList = 4;//礼包
--   }
function LimitedOfferData:parseData(_data)
    LimitedOfferData.super.parseData(self, _data)

    local _expireAt = tonumber(_data.expireAt)
    self.p_expireAt = _expireAt

    self.p_saleList = self:parseGiftList(_data.giftList) -- 促销礼包
end

-- message LimitedGiftSale {
--     optional string key = 1;
--     optional string keyId = 2;
--     optional string price = 3;
--     optional int64 coins = 4;
--     optional int32 originalPrice = 5;//原始价格
--     repeated ShopItem items = 6;
--     optional int32 buyTimes = 7; //已购买次数
--     optional int32 totalTimes = 8; //可购买总次数
--   }
function LimitedOfferData:parseGiftList(_data)
    -- 通用道具
    local saleData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_key = v.key
            tempData.p_keyId = v.keyId
            tempData.p_price = v.price
            tempData.p_coins = tonumber(v.coins)
            tempData.p_originalPrice = v.originalPrice
            tempData.p_buyTimes = v.buyTimes
            tempData.p_totalTimes = v.totalTimes
            tempData.p_items = self:parseItems(v.items)
            table.insert(saleData, tempData)
        end
    end
    return saleData
end

function LimitedOfferData:parseItems(_items)
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

function LimitedOfferData:getSaleList()
    return self.p_saleList
end

return LimitedOfferData
