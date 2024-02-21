--[[
    大R高性价比礼包促销
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require("baseActivity.BaseActivityData")
local SuperValueData = class("SuperValueData",BaseActivityData)

-- message SuperValue {
--     optional string activityId = 1;//活动id
--     optional int64 expireAt = 2;//过期时间
--     optional int32 expire = 3;//剩余秒数
--     optional string coins = 4;//实际金币
--     optional string originalCoins = 5;//折扣前金币
--     optional string discount = 6;//折扣
--     repeated ShopItem items = 7;//物品
--     optional int32 round = 8;//轮次
--     optional int64 roundExpireAt = 9;//本轮结束时间戳
--     optional int32 remainingTimes = 10;//本轮剩余购买次数
--     optional string key = 11;
--     optional string keyId = 12;
--     optional string price = 13;
--   }
function SuperValueData:parseData(_data)
    SuperValueData.super.parseData(self,_data)

    self.p_coins = tonumber(_data.coins)
    self.p_originalCoins = tonumber(_data.originalCoins)
    self.p_discount = _data.discount
    self.p_round = _data.round
    self.p_roundExpireAt = tonumber(_data.roundExpireAt) or 0
    self.p_remainingTimes = _data.remainingTimes or 0
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_items = self:parseItems(_data.items)
    
    if self.p_remainingTimes <= 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COMPLETED, {id = self:getID(), name = self:getRefName()})
    end
end

function SuperValueData:parseItems(_items)
    -- 通用道具
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function SuperValueData:getCoins()
    return self.p_coins
end

function SuperValueData:getOriginalCoins()
    return self.p_originalCoins
end

function SuperValueData:getDiscount()
    return self.p_discount
end

function SuperValueData:getRoundExpireAt()
    return self.p_roundExpireAt or 0
end

function SuperValueData:getRemainingTimes()
    return self.p_remainingTimes
end

function SuperValueData:getItems()
    return self.p_items
end

function SuperValueData:getKeyId()
    return self.p_keyId
end

function SuperValueData:getPrice()
    return self.p_price
end

function SuperValueData:isRunning()
    local flag = SuperValueData.super.isRunning(self)

    if flag then
        flag = self.p_remainingTimes > 0 and self.p_roundExpireAt > globalData.userRunData.p_serverTime
    end

    return flag
end

return SuperValueData
