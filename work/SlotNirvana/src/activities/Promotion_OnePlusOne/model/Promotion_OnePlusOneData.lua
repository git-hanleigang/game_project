local BaseActivityData = require "baseActivity.BaseActivityData"
local Promotion_OnePlusOneData = class("Promotion_OnePlusOneData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")

function Promotion_OnePlusOneData:ctor()
    Promotion_OnePlusOneData.super.ctor(self)
    self._saleItems = {}
end

--[[
    message OnePlusOneSaleConfig {
        optional string activityId = 1; //活动id
        optional int64 expireAt = 2; //过期时间
        optional int32 expire = 3; //剩余秒数
        optional string key = 4; //key
        optional string keyId = 5; //keyId
        optional string price = 6; //价格
        optional OnePlusOneReward paidReward = 7; //付费奖励
        optional OnePlusOneReward freeReward = 8; //免费奖励
        optional bool buy = 9; //是否已经购买
        optional bool collectFreeReward = 10; //是否领取免费奖励
        optional bool end = 11; //是否结束
    }
]]

function Promotion_OnePlusOneData:parseData(data)
    Promotion_OnePlusOneData.super.parseData(self,data)

    if data:HasField("paidReward") then
        self._paidReward = {}
        local paidReward = data.paidReward
        if paidReward:HasField("coins") then
            self._paidReward.coins = paidReward.coins
        end
        if paidReward.itemList and #paidReward.itemList > 0 then
            self._paidReward.itemList = {}
            for i=1,#paidReward.itemList do
                local shopItem = ShopItem:create()
                shopItem:parseData(paidReward.itemList[i])
                table.insert(self._paidReward.itemList, shopItem)
            end
        end
    end

    if data:HasField("freeReward") then
        self._freeReward = {}
        local freeReward = data.freeReward
        if freeReward:HasField("coins") then
            self._freeReward.coins = freeReward.coins
        end
        if freeReward.itemList and #freeReward.itemList > 0 then
            self._freeReward.itemList = {}
            for i=1,#freeReward.itemList do
                local shopItem = ShopItem:create()
                shopItem:parseData(freeReward.itemList[i])
                table.insert(self._freeReward.itemList, shopItem)
            end
        end
    end

    if data:HasField("key") then
        self._key = data.key
    end

    if data:HasField("keyId") then
        self._keyId = data.keyId
    end

    if data:HasField("price") then
        self._price = data.price
    end

    if data:HasField("buy") then
        self._buy = data.buy
    end

    if data:HasField("collectFreeReward") then
        self._collectFreeReward = data.collectFreeReward
    end

    if data:HasField("end") then
        self["_end"] = data['end']
        if self._end == true then
            self.p_open = false
        end
    end
end

function Promotion_OnePlusOneData:getPayData()
    return self._paidReward
end

function Promotion_OnePlusOneData:getFreeData()
    return self._freeReward
end

function Promotion_OnePlusOneData:getKey()
    return self._key
end

function Promotion_OnePlusOneData:getKeyID()
    return self._keyId
end

function Promotion_OnePlusOneData:getPrice()
    return self._price
end

function Promotion_OnePlusOneData:isBuy()
    return self._buy
end

function Promotion_OnePlusOneData:isCollectFreeReward()
    return self._collectFreeReward
end

function Promotion_OnePlusOneData:isEnd()
    return self._end
end

function Promotion_OnePlusOneData:getAddItemList()
    local itemList = gLobalItemManager:checkAddLocalItemList(
        {p_keyId = self._keyId}
    )
    return itemList
end

function Promotion_OnePlusOneData:getVipPoint()
    local list = self:getAddItemList()
    for i = 1,#list do
        local data = list[i]
        if data.p_icon == "Vip" then
            return data.p_num or 0
        end
    end
end

--制作BuyTip数据
function Promotion_OnePlusOneData:makeDataForBuyTip()
    local saleData = SaleItemConfig:create()
    saleData.p_keyId = self._keyId
    saleData.p_originalCoins = self.m_originalCoins
    saleData.p_coins = tonumber(self._freeReward.coins)
    saleData.p_price = self._price
    saleData.m_buyPosition = BUY_TYPE.OnePlusOneSale
    saleData.p_vipPoint = self:getVipPoint()
    local purchaseData = gLobalItemManager:getCardPurchase(nil, self._price)
    if purchaseData then
        saleData:setClubPoints(tonumber(purchaseData.p_clubPoints) or 0)
    end
    return saleData
end

return Promotion_OnePlusOneData