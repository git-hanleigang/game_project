local EgyptCoinPusherSalePackData = class("EgyptCoinPusherSalePackData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function EgyptCoinPusherSalePackData:ctor()
    self.p_coins = toLongNumber(0)
    self.p_buyType = BUY_TYPE.EGYPT_COINPUSHER_PACK_SALE
end

--[[
    message CoinPusherV3SpecialSale {
        optional string key = 1; // 价格的档位
        optional string price = 2; // 价钱
        optional string keyId = 3; // 价钱的链接
        optional string coins = 4;
        repeated ShopItem items = 5;
        optional int32 vipPoint = 6; //vip点数
    }
]]
function EgyptCoinPusherSalePackData:parseData(_data)
    self.p_key = _data.keyId -- 由于基类key为keyId
    self.p_price = _data.price
    self.p_keyId = _data.key
    if _data.coins and _data.coins ~= "" then
        self.p_coins:setNum(_data.coins)
    end
    self.p_items = self:parseItems(_data.items)
    self.p_vipPoint = _data.vipPoint
end

function EgyptCoinPusherSalePackData:parseItems(_items)
    local items = {}
    if _items and #_items > 0 then
        for i = 1, #_items do
            local itemData = _items[i]
            local shopItem = ShopItem:create()
            shopItem:parseData(itemData)
            items[#items + 1] = shopItem
        end
    end
    return items
end

function EgyptCoinPusherSalePackData:getKey()
    return self.p_key
end

function EgyptCoinPusherSalePackData:getPrice()
    return self.p_price
end

function EgyptCoinPusherSalePackData:getKeyId()
    return self.p_keyId
end

function EgyptCoinPusherSalePackData:getCoins()
    return self.p_coins
end

function EgyptCoinPusherSalePackData:getItems()
    return self.p_items
end

function EgyptCoinPusherSalePackData:getVipPoint()
    return self.p_vipPoint
end

return EgyptCoinPusherSalePackData
