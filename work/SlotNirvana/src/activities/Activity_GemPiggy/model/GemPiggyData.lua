--[[
    钻石小猪数据
]]

local GemPiggyPriceData = util_require("activities.Activity_GemPiggy.model.GemPiggyPriceData")
local BaseActivityData = require("baseActivity.BaseActivityData")
local GemPiggyData = class("GemPiggyData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")

GemPiggyData.m_lastPrice = nil --存储的实际价值

function GemPiggyData:ctor()
    GemPiggyData.super.ctor(self)
    self:setRefName(ACTIVITY_REF.GemPiggy)
end

-- message PigGems{
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional PigGemsPrice price = 4; //付费价格
--     optional PigGemsPrice originPrice = 5; //折扣原付费价格
--     optional bool hasDiscount = 6; //是否折扣
--     optional int64 total = 7; //水池容量
--     optional int64 progress = 8; //进度
-- }
function GemPiggyData:parseData(data)
    GemPiggyData.super.parseData(self, data)

    self.p_price = nil
    if data.price and data:HasField("price") then
        local priceData = GemPiggyPriceData:create()
        priceData:parseData(data.price)
        self.p_price = priceData
    end

    self.p_originPrice = nil
    if data.originPrice and data:HasField("originPrice") then
        local priceData = GemPiggyPriceData:create()
        priceData:parseData(data.originPrice)
        self.p_originPrice = priceData
    end

    self.p_hasDiscount = data.hasDiscount -- 是否折扣
    self.p_totalPoints = tonumber(data.total) -- 总点数
    self.p_currentPoints = tonumber(data.progress) -- 当前点数
end

function GemPiggyData:getTotalPoints()
    return self.p_totalPoints or 0
end

function GemPiggyData:getCurrentPoints()
    return self.p_currentPoints or 0
end

function GemPiggyData:getPriceData()
    return self.p_price
end

function GemPiggyData:getOriginPriceData()
    return self.p_originPrice
end

function GemPiggyData:hasDiscount()
    return self.p_hasDiscount
end

-- 付费前记录一下金币
function GemPiggyData:setRewardGem(_rewardGem)
    self.m_rewardGem = _rewardGem
end

function GemPiggyData:getRewardGem()
    return self.m_rewardGem or 0
end

function GemPiggyData:setSavePrice(_price)
    self.m_savePrice = _price
end

function GemPiggyData:getSavePrice()
    return self.m_savePrice or 0
end

-- function GemPiggyData:setSavePhaseReward(_items)
--     self.m_rewardItems = _items
-- end

-- function GemPiggyData:getSavePhaseReward()
--     return self.m_rewardItems or {}
-- end

function GemPiggyData:isMax()
    return (self.p_currentPoints > 0) and (self.p_currentPoints >= self.p_totalPoints)
end

return GemPiggyData
