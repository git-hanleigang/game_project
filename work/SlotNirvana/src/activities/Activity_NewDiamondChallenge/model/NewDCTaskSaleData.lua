--钻石挑战任务促销数据
local NewDCTaskSaleData = class("NewDCTaskSaleData")
local ShopItem = require "data.baseDatas.ShopItem"

-- message LuckyChallengeV2RefreshSale {
--     optional int32 index = 1;
--     optional string coins = 2;
--     repeated ShopItem items = 3;
--     optional string key = 4;
--     optional string keyId = 5;
--     optional string price = 6;
--   }

function NewDCTaskSaleData:ctor()
    self.p_coins = toLongNumber(0)
end

function NewDCTaskSaleData:parseData(data)
    self.p_Index = tonumber(data.index)
    if data.coins then
        self.p_coins:setNum(data.coins)
    end
    if data.items and #data.items > 0 then
        self.p_shop = {}
        for i,v in ipairs(data.items) do
            local shop = ShopItem:create()
            shop:parseData(v)
            table.insert(self.p_shop,shop)
        end
    end
    self.p_key = data.key
    self.p_keyId = data.keyId
    self.p_price = data.price
end

function NewDCTaskSaleData:getIndex()
    return self.p_Index or 0
end

function NewDCTaskSaleData:getCoins()
    return self.p_coins or 0
end

function NewDCTaskSaleData:getItems()
    return self.p_shop or {}
end

function NewDCTaskSaleData:getKey()
    return self.p_key or 0
end

function NewDCTaskSaleData:getKeyId()
    return self.p_keyId or 0
end

function NewDCTaskSaleData:getPrice()
    return self.p_price or 0
end

return NewDCTaskSaleData