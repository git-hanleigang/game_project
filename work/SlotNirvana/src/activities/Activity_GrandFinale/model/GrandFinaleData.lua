-- 赛季末返新卡

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local GemChallengeData = class("GemChallengeData", BaseActivityData)

-- message GrandFinale {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated GrandFinaleTask taskList = 4;//任务列表
--     optional bool payUnlock = 5;//是否解锁付费奖励
--     optional string price = 6;
--     optional string key = 7;
--     optional string keyId = 8;
--   }
function GemChallengeData:parseData(_data)
    GemChallengeData.super.parseData(self, _data)

    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_payUnlock = _data.payUnlock
    self.p_taskList = self:parseTaskList(_data.taskList)
end

-- message GrandFinaleTask {
--     optional int32 index = 1;
--     optional int32 taskId = 2;
--     optional GrandFinaleReward freeReward = 3;//免费奖励
--     optional GrandFinaleReward payReward = 4;//付费奖励
--     optional int64 params = 5;//任务参数
--     optional int64 progress = 6;//任务进度
--     optional string description = 7;//任务描述
--     optional bool completed = 8;//是否完成
--   }
function GemChallengeData:parseTaskList(_data)
    local reward = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local info = {}
            info.p_index = v.index
            info.p_taskId = v.taskId
            info.p_params = tonumber(v.params)
            info.p_progress = tonumber(v.progress)
            info.p_description = v.description
            info.p_completed = v.completed
            info.p_freeReward = self:parseReward(v.freeReward)
            info.p_payReward = self:parseReward(v.payReward)
            table.insert(reward, info)
        end
    end
    return reward
end 

-- message GrandFinaleReward {
--     optional string coins = 1;
--     repeated ShopItem items = 2;
--     optional bool collected = 3;//是否领取
--   }
function GemChallengeData:parseReward(_data)
    local temp = {}
    if _data then
        temp.p_collected = _data.collected
        temp.p_coins = tonumber(_data.coins)
        temp.p_items = self:parseItemData(_data.items)
    end
    return temp
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

function GemChallengeData:getTaskList()
    return self.p_taskList
end

function GemChallengeData:getPayUnlocked()
    return self.p_payUnlock
end 

function GemChallengeData:getKeyId()
    return self.p_keyId
end

function GemChallengeData:getPrice()
    return self.p_price
end

function GemChallengeData:hasReward()
    local flag = false
    
    for i,v in ipairs(self.p_taskList) do
        local payReward = v.p_payReward
        if self.p_payUnlock and v.p_completed and not payReward.p_collected then
            flag = true
            break
        end 
    end

    return flag
end

return GemChallengeData
