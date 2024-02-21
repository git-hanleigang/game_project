local BaseActivityData = require "baseActivity.BaseActivityData"
local Promotion_TopSaleData = class("Promotion_TopSaleData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")

function Promotion_TopSaleData:ctor()
    Promotion_TopSaleData.super.ctor(self)
    self.p_saleItems = {}
end

--[[
    message StoreUpscaleSaleConfig {
    optional string activityId = 1; //活动id
    optional int64 expireAt = 2; //过期时间
    optional int32 expire = 3; //剩余秒数
    optional string key = 4; //key
    optional string keyId = 5; //keyId
    optional string price = 6; //价格
    optional int64 coins = 7;//金币
    repeated ShopItem items = 8; //物品
    }
]]

function Promotion_TopSaleData:parseData(data)
    Promotion_TopSaleData.super.parseData(self,data)

    if data:HasField("key") then
        self.p_key = data.key
    end

    if data:HasField("keyId") then
        self.p_keyId = data.keyId
    end

    if data:HasField("price") then
        self.p_price = data.price
    end
    
    if data:HasField("coins") then
        self.p_coins = tonumber(data.coins) 
    end

    if data.items and #data.items > 0 then
        self.p_saleItems = {}
        for i=1,#data.items do
            local shopItem = ShopItem:create()
            shopItem:parseData(data.items[i])
            table.insert(self.p_saleItems, shopItem)
        end
    end
    self.m_isDirty = false
end

function Promotion_TopSaleData:getKey()
    return self.p_key
end

function Promotion_TopSaleData:getKeyID()
    return self.p_keyId
end

function Promotion_TopSaleData:getPrice()
    return self.p_price
end

function Promotion_TopSaleData:getCoins()
    return self.p_coins
end

function Promotion_TopSaleData:getSaleItems()
    return self.p_saleItems
end


function Promotion_TopSaleData:changeToDirty()
    self.m_isDirty = true
end

function Promotion_TopSaleData:isDirty()
    return self.m_isDirty
end

function Promotion_TopSaleData:getAddItemList()
    local itemList = gLobalItemManager:checkAddLocalItemList(
        {p_keyId = self.p_keyId}
    )
    return itemList
end

function Promotion_TopSaleData:getVipPoint()
    local list = self:getAddItemList()
    for i = 1,#list do
        local data = list[i]
        if data.p_icon == "Vip" then
            return data.p_num or 0
        end
    end
end

--制作BuyTip数据
function Promotion_TopSaleData:makeDataForBuyTip()
    local saleData = SaleItemConfig:create()
    saleData.p_keyId = self.p_keyId
    saleData.p_originalCoins = self.m_originalCoins
    saleData.p_coins = self.p_coins
    saleData.p_price = self.p_price
    saleData.m_buyPosition = BUY_TYPE.TopSale
    saleData.p_vipPoint = self:getVipPoint()
    local purchaseData = gLobalItemManager:getCardPurchase(nil, self.p_price)
    if purchaseData then
        saleData:setClubPoints(tonumber(purchaseData.p_clubPoints) or 0)
    end
    return saleData
end

return Promotion_TopSaleData