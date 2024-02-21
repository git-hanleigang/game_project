--[[
    邮箱收集
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local NewDoubleData = class("NewDoubleData",BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"

-- message NewDoubleSaleConfig {
--     optional string activityId = 1; //活动id
--     optional int32 expire = 2; //剩余秒数
--     optional int64 expireAt = 3; //过期时间
--     repeated ShopItem itemResultList = 4; //中奖道具
--     optional int64 coins = 5; //金币
--     optional int32 sequence = 6; //轮次
--     optional bool alreadyBuy = 7; //是否已经购买
--     optional bool win = 8; //是否中奖
--     optional string key = 9; //key
--     optional string keyId = 10; //keyId
--     optional string price = 11; //价格
--   }

function NewDoubleData:parseData(_data)
    NewDoubleData.super.parseData(self,_data)

    self.p_coins  = tonumber(_data.coins)
    self.p_sequence = _data.sequence
    self.p_alreadyBuy = _data.alreadyBuy
    self.p_win = _data.win
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_items  = self:parseItemsData(_data.itemList) -- 奖励物品    
end

-- 解析道具数据
function NewDoubleData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function NewDoubleData:getCoins()
    return self.p_coins or 0
end

function NewDoubleData:getItems()
    return self.p_items
end

function NewDoubleData:getSequence()
    return self.p_sequence
end

function NewDoubleData:getAlreadyBuy()
    return self.p_alreadyBuy
end

function NewDoubleData:getKeyId()
    return self.p_keyId
end

function NewDoubleData:getPrice()
    return self.p_price
end

return NewDoubleData
