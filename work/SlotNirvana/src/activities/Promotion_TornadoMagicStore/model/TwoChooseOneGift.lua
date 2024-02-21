local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local TwoChooseOneGift = class("TwoChooseOneGift")
local ShopItem = util_require("data.baseDatas.ShopItem")

--[[
    message TwoChooseOneGift {
        optional string key = 1; //key
        optional string keyId = 2; //keyId
        optional string price = 3; //价格
        optional int64 coins = 4;//金币
        repeated ShopItem itemList = 5;//道具集合
        optional string discount = 6; //折扣
        optional int64 discountBeforeCoins = 7; //折扣前金币
    }
]]

TwoChooseOneGift.protoKey2Key = 
{
    ["key"] = "key",
    ["keyId"] = "keyId",
    ["price"] = "price",
    ["discountBeforeCoins"] = "discountBeforeCoins",
    ["discount"] = "discount",
    ["itemList"] = "itemList",
    ["coins"] = "coins",
}

function TwoChooseOneGift:ctor()
    for _,key in pairs(self.protoKey2Key) do
        self:set(key):get(key)
    end
end

function TwoChooseOneGift:parseData(data)
    for pKey,key in pairs(self.protoKey2Key) do
        if key == "itemList" then
            local shopItemList = {}
            for _, data in ipairs(data[key]) do
                local shopItem = ShopItem:create()
                shopItem:parseData(data)
                table.insert(shopItemList, shopItem)
            end
            self['set'..self:getUperKey(key)](self,shopItemList)
        elseif data:HasField(key) then
            local value = data[key]
            self['set'..self:getUperKey(key)](self,value)
        end
    end
end

function TwoChooseOneGift:getAddItemList()
    local itemList = gLobalItemManager:checkAddLocalItemList(
        {p_keyId = self._keyId}
    )
    return itemList
end

function TwoChooseOneGift:getVipPoint()
    local list = self:getAddItemList()
    for i = 1,#list do
        local data = list[i]
        if data.p_icon == "Vip" then
            return data.p_num or 0
        end
    end
end

--制作BuyTip数据
function TwoChooseOneGift:makeDataForBuyTip()
    local saleData = SaleItemConfig:create()
    saleData.p_keyId = self._keyId
    saleData.p_discounts = self._discount
    saleData.p_originalCoins = self.m_originalCoins
    saleData.p_coins = tonumber(self._coins)
    saleData.p_price = self._price
    saleData.m_buyPosition = BUY_TYPE.TwoChooseOneGiftSale
    saleData.p_vipPoint = self:getVipPoint()
    local purchaseData = gLobalItemManager:getCardPurchase(nil, self._price)
    if purchaseData then
        saleData:setClubPoints(tonumber(purchaseData.p_clubPoints) or 0)
    end
    return saleData
end

function TwoChooseOneGift:set(key)
    if key then
        local firstUperKey = string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
        self["set"..firstUperKey] = function(self,v)
            self["_"..key] = v
        end
    end
    return self
end

function TwoChooseOneGift:get(key)
    if key then
        local firstUperKey = string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
        self["get"..firstUperKey] = function(self)
            return self["_"..key]
        end
    end
    return self
end

function TwoChooseOneGift:getUperKey(key)
    return string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
end

return TwoChooseOneGift