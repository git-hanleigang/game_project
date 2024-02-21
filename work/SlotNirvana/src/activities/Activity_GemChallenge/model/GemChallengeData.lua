-- 第二货币消耗挑战

local GemChallengeConfig = require("activities.Activity_GemChallenge.config.GemChallengeConfig")
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local GemChallengeData = class("GemChallengeData", BaseActivityData)

-- message GemChallenge {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated GemChallengePoint pointList = 4;
--     optional string key = 5;
--     optional string keyId = 6;
--     optional string price = 7;
--     optional bool payUnlocked = 8;//付费奖励解锁标识
--     optional int64 totalPoints = 9;//总点数
--     optional int64 currentPoints = 10;//当前点数
--     optional int64 usedGems = 11;//累记消耗
--   }
function GemChallengeData:parseData(_data)
    GemChallengeData.super.parseData(self, _data)

    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_payUnlocked = _data.payUnlocked
    self.p_totalPoints = tonumber(_data.totalPoints)
    self.p_currentPoints = tonumber(_data.currentPoints)
    self.p_usedGems = tonumber(_data.usedGems)

    self.p_pointList = self:parsePointList(_data.pointList)
    gLobalNoticManager:postNotification(GemChallengeConfig.notify_data_update)
end

-- message GemChallengePoint {
--     optional int32 index = 1;//索引
--     optional int64 points = 2;//所需点数
--     optional int64 coins = 3;
--     repeated ShopItem items = 4;
--     optional bool collected = 5;
--     optional bool payReward = 6;//是否是付费奖励
--   }
function GemChallengeData:parsePointList(_data)
    local reward = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local info = {}
            info.p_index = v.index
            info.p_points = tonumber(v.points)
            info.p_coins = tonumber(v.coins)
            info.p_collected = v.collected
            info.p_payReward = v.payReward
            info.p_items = self:parseItemData(v.items)
            table.insert(reward, info)
        end
    end
    return reward
end 

function GemChallengeData:parseItemData(_items)
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

function GemChallengeData:getCanCollectCount()
    local count = 0
    for i,v in ipairs(self.p_pointList) do
        if v.p_points <= self.p_currentPoints and not v.p_collected and (not v.p_payReward or self.p_payUnlocked) then
            count = count + 1
        end
    end

    return count
end

function GemChallengeData:getPointList()
    return self.p_pointList
end

function GemChallengeData:getCurPoints()
    return self.p_currentPoints
end 

function GemChallengeData:setCurPoints(_points)
    self.p_currentPoints = _points
    gLobalNoticManager:postNotification(GemChallengeConfig.notify_data_update)
end

function GemChallengeData:getTotalPoints()
    return self.p_totalPoints
end

function GemChallengeData:getPayUnlocked()
    return self.p_payUnlocked
end 

function GemChallengeData:getKeyId()
    return self.p_keyId
end

function GemChallengeData:getPrice()
    return self.p_price
end

function GemChallengeData:getUsedGems()
    return self.p_usedGems
end

function GemChallengeData:getPositionBar()
    return 1
end

return GemChallengeData
