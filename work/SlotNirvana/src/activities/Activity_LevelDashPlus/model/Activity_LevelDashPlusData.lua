
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local LevelDashPlusTask = class("LevelDashPlusTask")
local ShopItem = util_require("data.baseDatas.ShopItem")

--[[
    message LevelDashPlusTask {
        optional int32 needTimes = 1;//完成需要次数
        optional string description = 2;//描述
        optional int64 coins = 3;//金币奖励
        repeated ShopItem itemList = 4;//物品奖励
        optional bool complete = 5;//是否完成
    }
]]

LevelDashPlusTask.protoKey2Key = 
{
    ["needTimes"] = "needTimes",
    ["description"] = "description",
    ["coins"] = "coins",
    ["itemList"] = "itemList",
    ["complete"] = "complete",
}

function LevelDashPlusTask:ctor()
    for _,key in pairs(self.protoKey2Key) do
        self:set(key):get(key)
    end
end

function LevelDashPlusTask:parseData(data)
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

function LevelDashPlusTask:getAddItemList()
    local itemList = gLobalItemManager:checkAddLocalItemList(
        {p_keyId = self._keyId}
    )
    return itemList
end

function LevelDashPlusTask:getVipPoint()
    local list = self:getAddItemList()
    for i = 1,#list do
        local data = list[i]
        if data.p_icon == "Vip" then
            return data.p_num or 0
        end
    end
end

--制作BuyTip数据
function LevelDashPlusTask:makeDataForBuyTip()
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

function LevelDashPlusTask:set(key)
    if key then
        local firstUperKey = string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
        self["set"..firstUperKey] = function(self,v)
            self["_"..key] = v
        end
    end
    return self
end

function LevelDashPlusTask:get(key)
    if key then
        local firstUperKey = string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
        self["get"..firstUperKey] = function(self)
            return self["_"..key]
        end
    end
    return self
end

function LevelDashPlusTask:getUperKey(key)
    return string.gsub(key,"^.",string.upper(string.sub(key,1,1)))
end

----------------------------------------------------------------------------------------------------

local BaseActivityData = require "baseActivity.BaseActivityData"
local Activity_LevelDashPlusData = class("Activity_LevelDashPlusData", BaseActivityData)

function Activity_LevelDashPlusData:ctor()
    Activity_LevelDashPlusData.super.ctor(self)
    -- self.p_open = true

    self._rewardDataList = {}
end

function Activity_LevelDashPlusData:parseData(data)
    Activity_LevelDashPlusData.super.parseData(self,data)
    
    self._rewardDataList = {}
    if #data.taskList > 0 then
        for i = 1,#data.taskList do
            local value = data.taskList[i]
            local rewardObj = LevelDashPlusTask.new()
            rewardObj:parseData(value)
            self._rewardDataList[i] = rewardObj
        end
    end

    if not gLobalViewManager:isLevelView() then
        self:setStatus()
    end
end

function Activity_LevelDashPlusData:setStatus()
    if self._rewardDataList[3] and self._rewardDataList[3]:getComplete() == true then
        self.p_open = false
    end
end

function Activity_LevelDashPlusData:getDataByIndex(index)
    return self._rewardDataList[index]
end

function Activity_LevelDashPlusData:setLevelDashPlusIndex(index)
    self._levelDashPlusIndex = index
end

function Activity_LevelDashPlusData:getLevelDashPlusIndex()
    return self._levelDashPlusIndex
end

return Activity_LevelDashPlusData