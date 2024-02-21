
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local MissionRushReward = class("MissionRushReward")
local ShopItem = util_require("data.baseDatas.ShopItem")

--[[
    message MissionRushReward{
        optional int32 taskNum = 1; // 第几个每日任务
        optional bool collected = 2; // 是否领取
        optional int64 dailyPrizeCoin = 3; //实际金币奖励
        repeated ShopItem items = 4; //Daily Mission道具奖励
        }
]]

MissionRushReward.protoKey2Key = 
{
    ["taskNum"] = "taskNum",
    ["collected"] = "collected",
    ["dailyPrizeCoin"] = "dailyPrizeCoin",
    ["items"] = "items",
}

function MissionRushReward:ctor()
    for _,key in pairs(self.protoKey2Key) do
        self:set(key):get(key)
    end
end

function MissionRushReward:parseData(data)
    for pKey,key in pairs(self.protoKey2Key) do
        if key == "items" then
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

function MissionRushReward:getAddItemList()
    local itemList = gLobalItemManager:checkAddLocalItemList(
        {p_keyId = self._keyId}
    )
    return itemList
end

function MissionRushReward:getVipPoint()
    local list = self:getAddItemList()
    for i = 1,#list do
        local data = list[i]
        if data.p_icon == "Vip" then
            return data.p_num or 0
        end
    end
end

--制作BuyTip数据
function MissionRushReward:makeDataForBuyTip()
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

function MissionRushReward:set(key)
    if key then
        local firstUperKey = string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
        self["set"..firstUperKey] = function(self,v)
            self["_"..key] = v
        end
    end
    return self
end

function MissionRushReward:get(key)
    if key then
        local firstUperKey = string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
        self["get"..firstUperKey] = function(self)
            return self["_"..key]
        end
    end
    return self
end

function MissionRushReward:getUperKey(key)
    return string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
end

----------------------------------------------------------------------------------------------------

local BaseActivityData = require "baseActivity.BaseActivityData"
local Activity_DailySprint_CouponData = class("Activity_DailySprint_CouponData", BaseActivityData)

function Activity_DailySprint_CouponData:ctor()
    Activity_DailySprint_CouponData.super.ctor(self)

    self._rewardDataList = {}
end

function Activity_DailySprint_CouponData:parseData(data)
    Activity_DailySprint_CouponData.super.parseData(self,data)
    
    self._rewardDataList = {}
    if #data.reward > 0 then
        for i = 1,#data.reward do
            local value = data.reward[i]
            local rewardObj = MissionRushReward.new()
            rewardObj:parseData(value)
            self._rewardDataList[i] = rewardObj
        end
    end
end

function Activity_DailySprint_CouponData:getDataByIndex(index)
    return self._rewardDataList[index]
end

function Activity_DailySprint_CouponData:setLevelDashPlusIndex(index)
    self._levelDashPlusIndex = index
end

function Activity_DailySprint_CouponData:getLevelDashPlusIndex()
    return self._levelDashPlusIndex
end

return Activity_DailySprint_CouponData