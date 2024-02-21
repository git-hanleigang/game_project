--[[
    钻石挑战通关挑战
]]

local DiamondManiaConfig = require("activities.Activity_DiamondMania.config.DiamondManiaConfig")
local BaseActivityData = require("baseActivity.BaseActivityData")
local DiamondManiaData = class("DiamondManiaData", BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"

-- message DiamondMania {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated DiamondManiaStage stageList = 4;//阶段信息
--     optional int32 currentPoints = 5;//当前点数
--     optional int32 totalPoints = 6;//总点数
--     optional string group = 7;//ab组
--   }
function DiamondManiaData:parseData(_data)
    DiamondManiaData.super.parseData(self,_data)
    
    self.p_curPoints = _data.currentPoints
    self.p_totalPoints = _data.totalPoints
    self.p_group = _data.group
    self.p_stageData  = self:parseStageData(_data.stageList)  

    gLobalNoticManager:postNotification(DiamondManiaConfig.notify_data_update)
end


-- message DiamondManiaStage {
--     optional int32 index = 1;
--     optional DiamondManiaStageReward reward = 2;
--     optional DiamondManiaStageReward limitReward = 3;//限时奖励
--     optional int64 expireAt = 4;//限时到期时间戳
--     optional bool collected = 5;
--     optional bool expired = 6;//是否过期
--   }
function DiamondManiaData:parseStageData(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_points = v.index
            temp.p_collected = v.collected
            temp.p_expired = v.expired
            temp.p_expireAt = tonumber(v.expireAt)
            temp.p_reward = self:parseRewardData(v.reward)
            temp.p_limitReward = self:parseRewardData(v.limitReward)
            table.insert(list, temp)
        end
    end
    return list
end

-- message DiamondManiaStageReward {
--     optional int64 coins = 1;
--     repeated ShopItem items = 2;
--   }
function DiamondManiaData:parseRewardData(_data)
    local rewardData = {}
    if _data then 
        local temp = {}
        rewardData.p_coins = tonumber(_data.coins) or 0
        rewardData.p_items = self:parseItemsData(_data.items)
    end
    return rewardData
end

-- 解析道具数据
function DiamondManiaData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function DiamondManiaData:getCurPoints()
    return self.p_curPoints
end

function DiamondManiaData:getTotalPoints()
    return self.p_totalPoints
end

function DiamondManiaData:getStageData()
    return self.p_stageData
end

function DiamondManiaData:getGroup()
    return self.p_group
end

function DiamondManiaData:getCanCollectReward()
    local idxList = {}
    for i,v in ipairs(self.p_stageData) do
        if self.p_curPoints >= v.p_points and not v.p_collected then
            table.insert(idxList, i)
        end
    end
    return idxList
end

return DiamondManiaData
