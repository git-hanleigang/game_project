--[[
    促销
]]
local ShopItem = require "data.baseDatas.ShopItem"
local HolidaySaleData = class("HolidaySaleData")

-- message HolidayNewChallengePromotion {
--     optional string key = 1;// 对应的档位
--     optional string keyId = 2; // 对应的支付连接
--     optional string price = 3; // 价格
--     repeated ShopItem items = 4;//道具
--     optional string coins = 5; // 金币
--     optional string discount = 6;// 折扣
--   }

function HolidaySaleData:parseData(_data)
    self.p_key      = _data.key        --对应的档位                    
    self.p_keyId    = _data.keyId      --对应的支付连接
    self.p_price    = _data.price      --价格    
    self.p_coins    = _data.coins      --金币   
    self.p_discount = _data.discount   --折扣  
    
    self.p_itemsList  = self:parseItemsList(_data.items) --道具
end

function HolidaySaleData:parseItemsList(_items)
    local itemsList = {}
    if _items and #_items > 0 then
        for i, v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsList, tempData)
        end
    end
    return itemsList
end

function HolidaySaleData:getKey()
    return self.p_key
end

function HolidaySaleData:getItems()
    return self.p_itemsList
end

-- 获取付费链接
function HolidaySaleData:getPayKey()
    return self.p_keyId
end

function HolidaySaleData:getPrice()
    return tonumber(self.p_price)
end

function HolidaySaleData:getCoins()
    return self.p_coins
end

function HolidaySaleData:getDiscount()
    return self.p_discount 
end

return HolidaySaleData
