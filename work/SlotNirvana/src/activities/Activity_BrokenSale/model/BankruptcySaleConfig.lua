local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BankruptcySaleConfig = class("BankruptcySaleConfig")

--[[
    message BankruptcySaleConfig {
        optional int32 level = 1; //档位顺序
        optional string keyId = 2; //keyId
        optional string key = 3; //付费点key
        optional string price = 4; //购买价格
        optional string description = 5; //描述
        optional int32 discount = 6; //购买档位对应折扣
        optional string oriPrice = 7; //购买档位对应划线价格
        optional int64 coins = 8; //金币
    }
]]

BankruptcySaleConfig.protoKey2Key = 
{
    ["level"] = "level",
    ["keyId"] = "keyId",
    ["key"] = "key",
    ["price"] = "price",
    ["description"] = "description",
    ["discount"] = "discount",
    ["originalCoins"] = "originalCoins",
    ["coins"] = "coins",
}

function BankruptcySaleConfig:ctor()
    for _,key in pairs(self.protoKey2Key) do
        self:set(key):get(key)
    end
end

function BankruptcySaleConfig:parseData(data)
    for pKey,key in pairs(self.protoKey2Key) do
        if data:HasField(key) then
            local value = data[key]
            self['set'..self:getUperKey(key)](self,value)
        end
    end
end

function BankruptcySaleConfig:getAddItemList()
    local itemList = gLobalItemManager:checkAddLocalItemList(
        {p_keyId = self._keyId}
    )
    return itemList
end

function BankruptcySaleConfig:getVipPoint()
    local list = self:getAddItemList()
    for i = 1,#list do
        local data = list[i]
        if data.p_icon == "Vip" then
            return data.p_num or 0
        end
    end
end

--制作BuyTip数据
function BankruptcySaleConfig:makeDataForBuyTip()
    local saleData = SaleItemConfig:create()
    saleData.p_keyId = self._keyId
    saleData.p_discounts = self._discount
    saleData.p_originalCoins = self.m_originalCoins
    saleData.p_coins = tonumber(self._coins)
    saleData.p_price = self._price
    saleData.m_buyPosition = BUY_TYPE.BROKENSALE2
    saleData.p_vipPoint = self:getVipPoint()
    local purchaseData = gLobalItemManager:getCardPurchase(nil, self._price)
    if purchaseData then
        saleData:setClubPoints(tonumber(purchaseData.p_clubPoints) or 0)
    end
    return saleData
end

function BankruptcySaleConfig:set(key)
    if key then
        local firstUperKey = string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
        self["set"..firstUperKey] = function(self,v)
            self["_"..key] = v
        end
    end
    return self
end

function BankruptcySaleConfig:get(key)
    if key then
        local firstUperKey = string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
        self["get"..firstUperKey] = function(self)
            return self["_"..key]
        end
    end
    return self
end

function BankruptcySaleConfig:getUperKey(key)
    return string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
end

return BankruptcySaleConfig