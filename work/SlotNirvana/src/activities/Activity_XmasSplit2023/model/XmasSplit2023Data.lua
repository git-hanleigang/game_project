

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local XmasSplit2023Data = class("XmasSplit2023Data", BaseActivityData)

--[[
    message XmasSplit {
        optional string activityId = 1; //活动id
        optional int64 expireAt = 2; //过期时间
        optional int32 expire = 3; //剩余秒数
        optional string totalPurchase = 4;//累计付费
        repeated XmasSplitPool pools = 5;//奖池
        repeated int32 gainPoolIndex = 6; //当前付费获取的奖池index+1
    }

    message XmasSplitPool {
        optional int32 pool = 1;//奖池ID
        optional string amountRequired = 2;//解锁累计付费
        optional string coins = 3;//金币
        repeated ShopItem items = 4; // 道具
    }
]]

function XmasSplit2023Data:parseData(_data)
    XmasSplit2023Data.super.parseData(self, _data)
    self.m_curPool = 0

    self.p_totalPayAmount = _data.totalPurchase
    self.p_pools = self:parsePools(_data.pools)

    self.p_gainPoolIndex = {}
    for i = 1, #_data.gainPoolIndex do
        local index = _data.gainPoolIndex[i]
        table.insert(self.p_gainPoolIndex, index)
    end

end

function XmasSplit2023Data:parsePools(_dataPools)
    local list = {}
    local shopItem = ShopItem:create()
    for i,v in ipairs(_dataPools) do
        local tempData = {}
        tempData.pool = tonumber(v.pool)
        tempData.amountRequired = tonumber(v.amountRequired)
        tempData.coins = v.coins
        tempData.items = self:parseShopItemData(v.items)
        table.insert(list, tempData)
        if tonumber(self.p_totalPayAmount) >= tempData.amountRequired then
            self.m_curPool = i
        end
    end
    return list
end

function XmasSplit2023Data:parseShopItemData(items)
    local itemList = {}
    for _, data in ipairs(items) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data, true)
        table.insert(itemList, shopItem)
    end
    return itemList
end

function XmasSplit2023Data:getTotalPayAmount()
    if self.p_totalPayAmount == "" then
        return "0"
    end
    return self.p_totalPayAmount or "0"
end

function XmasSplit2023Data:getPools()
    return self.p_pools or {}
end

function XmasSplit2023Data:getGainPoolIndex()
    return self.p_gainPoolIndex
end

function XmasSplit2023Data:getCurPool()
    return self.m_curPool
end

return XmasSplit2023Data
