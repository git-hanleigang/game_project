-- LEVEL UP PASS

local LevelUpPassConfig = require("activities.Activity_LevelUpPass.config.LevelUpPassConfig")
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local LevelUpPassData = class("LevelUpPassData", BaseActivityData)

-- message LevelUpPass {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated LevelUpPassStage stageList = 4;
--     optional string key = 5;
--     optional string keyId = 6;
--     optional string price = 7;
--     optional bool payUnlocked = 8;//付费奖励解锁标识
--     optional int32 totalLevel = 9;//总需提升等级数
--     optional int32 currentLevel = 10;//当前提升等级数
--     repeated LevelUpPassStage freeReward = 11;
--     repeated LevelUpPassStage payReward = 12;
--   }

function LevelUpPassData:parseData(_data)
    LevelUpPassData.super.parseData(self, _data)

    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_payUnlocked = _data.payUnlocked
    self.p_totalPoints = tonumber(_data.totalLevel)
    self.p_currentPoints = tonumber(_data.currentLevel)

    self.p_pointList = self:parsePointList(_data.stageList)
    self.p_freeReward = self:parsePointList(_data.freeReward)
    self.p_payReward = self:parsePointList(_data.payReward)
    gLobalNoticManager:postNotification(LevelUpPassConfig.notify_data_update)
end

-- message LevelUpPassStage {
--     optional int32 index = 1;//索引
--     optional int32 level = 2;//所需等级
--     optional string coins = 3;
--     repeated ShopItem items = 4;
--     optional bool collected = 5;
--     optional bool payReward = 6;//是否是付费奖励
--   }
function LevelUpPassData:parsePointList(_data)
    local reward = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local info = {}
            info.p_index = v.index
            info.p_points = tonumber(v.level)
            info.p_coins = toLongNumber(0)
            if v.coins and v.coins ~= "" then
                info.p_coins:setNum(v.coins)
            end
            info.p_collected = v.collected
            info.p_payReward = v.payReward
            info.p_items = self:parseItemData(v.items)
            table.insert(reward, info)
        end
    end
    return reward
end 

function LevelUpPassData:parseItemData(_items)
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

function LevelUpPassData:getCanCollectCount()
    local count = 0

    for i,v in ipairs(self.p_freeReward) do
        if v.p_points <= self.p_currentPoints and not v.p_collected and (v.p_coins > toLongNumber(0) or #v.p_items > 0) then
            count = count + 1
        end
    end

    if self.p_payUnlocked then
        for i,v in ipairs(self.p_payReward) do
            if v.p_points <= self.p_currentPoints and not v.p_collected and (v.p_coins > toLongNumber(0) or #v.p_items > 0) then
                count = count + 1
            end
        end
    end

    return count
end

function LevelUpPassData:getPointList()
    return self.p_pointList
end

function LevelUpPassData:getCurPoints()
    return self.p_currentPoints
end

function LevelUpPassData:getTotalPoints()
    return self.p_totalPoints
end

function LevelUpPassData:getPayUnlocked()
    return self.p_payUnlocked
end 

function LevelUpPassData:getKeyId()
    return self.p_keyId
end

function LevelUpPassData:getPrice()
    return self.p_price
end

function LevelUpPassData:getFreeReward()
    return self.p_freeReward
end

function LevelUpPassData:getPayReward()
    return self.p_payReward
end

return LevelUpPassData
