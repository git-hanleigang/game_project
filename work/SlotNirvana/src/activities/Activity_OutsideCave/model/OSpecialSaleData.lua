-- 特殊促销数据
local OSpecialSaleData = class("OSpecialSaleData")

local ShopItem = util_require("data.baseDatas.ShopItem")

-- message OutsideCaveSpecialSale {
--     optional string key = 1; // 价格的档位
--     optional string price = 2; // 价钱
--     optional string keyId = 3; // 价钱的链接
--     optional int64 coins = 4;
--     repeated ShopItem items = 5;
--     optional int32 vipPoint = 6; //vip点数
-- }

function OSpecialSaleData:ctor()
    self.p_coins = toLongNumber(0)
end

function OSpecialSaleData:parseData(data)
    self.p_key = data.key  -- 价格的档位
    self.p_price = data.price  -- 价钱
    self.p_keyId = data.keyId  -- 价钱的链接
    self.p_coins:setNum((data.coins and data.coins ~= "") and data.coins or 0)  -- 金币
    self.p_items = self:parseItems(data.items) -- 道具
    self.p_vipPoint = tonumber(data.vipPoint)  
end

function OSpecialSaleData:parseItems(_items)
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

return OSpecialSaleData