local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local ShopItem = require("data.baseDatas.ShopItem")
local BrokenSaleV2ItemConfig = class("BrokenSaleV2ItemConfig")

function BrokenSaleV2ItemConfig:ctor()
    self.p_coins = toLongNumber(0)
end

--[[
    message GoBrokeSalePrice {
        optional string keyId = 1; // 档位标识 S1
        optional string key = 2; // 付费唯一标识 0p99
        optional string price = 3; // 价格 0.99
        optional string coins = 4; // 金币
        optional int32 index = 5; // 付费档位123
        repeated ShopItem items = 6; // 道具
        repeated ShopItem extraItems = 7; // 额外道具
        optional int32 buyLimit = 8; // 当前档位每次购买上限
        optional int32 discount = 9; // 折扣
        optional int32 vipPoint = 10; // vip点数
        repeated ShopItem displayList = 11; // 同商城显示道具
        optional string buffMultiple = 12; // buff倍数
    }
]]
function BrokenSaleV2ItemConfig:parseData(data)
    self.p_keyId = data.keyId
    self.p_key = data.key
    self.p_price = data.price
    self.p_coins:setNum(data.coins)
    self.p_index = tonumber(data.index)
    self.p_items = self:parseShopItem(data.items)
    self.p_extraItems = self:parseShopItem(data.extraItems)
    self.p_buyLimit = tonumber(data.buyLimit)
    self.p_discount = tonumber(data.discount)
    self.p_vipPoint = tonumber(data.vipPoint)
    self.p_displayList = self:parseShopItem(data.displayList)
    self.p_buffMultiple = tonumber(data.buffMultiple)
end

function BrokenSaleV2ItemConfig:parseShopItem(_items)
    local itemList = {}
    for _, data in ipairs(_items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(itemList, shopItem)
    end
    return itemList
end

--制作BuyTip数据
function BrokenSaleV2ItemConfig:getBuyTipData()
    local saleData = SaleItemConfig:create()
    saleData.p_keyId = self.p_key
    saleData.p_discounts = self.p_discount
    saleData.p_coins = self.p_coins
    saleData.p_price = self.p_price
    saleData.m_buyPosition = BUY_TYPE.BROKENSALEV2
    saleData.p_vipPoint = self.p_vipPoint
    local purchaseData = gLobalItemManager:getCardPurchase(nil, self._price)
    if purchaseData then
        saleData:setClubPoints(tonumber(purchaseData.p_clubPoints or 0))
    end
    return saleData
end

function BrokenSaleV2ItemConfig:getKeyId()
    return self.p_keyId
end

function BrokenSaleV2ItemConfig:getKey()
    return self.p_key
end

function BrokenSaleV2ItemConfig:getPrice()
    return self.p_price
end

function BrokenSaleV2ItemConfig:getCoins()
    return self.p_coins or 0
end

function BrokenSaleV2ItemConfig:getDiscount()
    return self.p_discount
end

function BrokenSaleV2ItemConfig:getIndex()
    return self.p_index
end

function BrokenSaleV2ItemConfig:getItems()
    return self.p_items
end

function BrokenSaleV2ItemConfig:getExtraItems()
    return self.p_extraItems
end

function BrokenSaleV2ItemConfig:getDisplayList()
    return self.p_displayList
end

function BrokenSaleV2ItemConfig:getBuyLimit()
    return self.p_buyLimit or 0
end

function BrokenSaleV2ItemConfig:getBuffMultiple()
    return self.p_buffMultiple or 0
end

function BrokenSaleV2ItemConfig:getVipPoint()
    return self.p_vipPoint or 0
end

return BrokenSaleV2ItemConfig