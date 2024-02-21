-- FIX IOS 150 v464
local BaseActivityData = require "baseActivity.BaseActivityData"
local QuestNewActivityRushData = class("QuestNewActivityRushData", BaseActivityData)

-- message QuestNewChallenge {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //截止时间
--     optional int64 expire = 3; //剩余时间
--     repeated int64 params = 4; //任务参数
--     repeated int64 process = 5; //任务进度
--     repeated QuestNewChallengePhase phaseResult = 6;//阶段数据
--     optional int64 taskId = 7; //任务类型
--     optional int32 difficulty = 8;//难度条件
-- }
function QuestNewActivityRushData:parseData(_data)
    QuestNewActivityRushData.super.parseData(self, _data)
    self.taskId = tostring(_data.taskId)  -- 任务类型
    self.difficulty = _data.difficulty  -- 难度条件
    self.m_process = _data.process or {} -- 当前任务进度
    self.m_rewardsData = self:parseRewardsData(_data.phaseResult, _data.params) -- 任务阶段奖励数据
    -- 计算当前处于哪个阶段
    self.m_curStep = nil
    for idx,data in ipairs(self.m_rewardsData) do
        if not self.m_curStep or self.m_curStep < data.phase then
            self.m_curStep = data.phase
        end
        if data.completed == false then
            break
        end
    end
    if not self.m_oldData then
        self:resetOldData()
    end
end

-- message QuestNewChallengePhase {
--     optional int32 phase = 1;//奖励阶段
--     optional bool completed = 2; //完成标识
--     optional int64 coins = 3;      //金币奖励
--     repeated ShopItem itemResults = 4;//物品奖励
--     optional bool collected = 5; //领取标识
-- }
function QuestNewActivityRushData:parseRewardsData( _data, _dataEx )
    local base = 0
    local rewardsData = {}
    if _data then
        for idx, _rewardData in ipairs(_data) do
            local rewardData = {}
            rewardData.phase          = _rewardData.phase           -- 奖励阶段
            rewardData.completed      = _rewardData.completed       -- 完成标识
            rewardData.coins          = _rewardData.coins           -- 金币奖励
            rewardData.itemResults    = _rewardData.itemResults     -- 物品奖励
            rewardData.collected      = _rewardData.collected       -- 领取标识
            rewardData.condition      = _dataEx[idx]                -- 完成条件
            rewardData.base           = base
            table.insert(rewardsData, rewardData)
            base = _dataEx[idx]
        end
    end
    return rewardsData
end

-- 获取任务划分为几个阶段
function QuestNewActivityRushData:getRushParts()
    if self.m_rewardsData then
        return table.nums(self.m_rewardsData)
    end
    return 0
end

-- 获取任务对应阶段的起始条件
function QuestNewActivityRushData:getBaseByIdx(_idx)
    if self.m_rewardsData[_idx] then
        return self.m_rewardsData[_idx].base
    end
    return 0
end

-- 获取任务对应阶段的完成条件
function QuestNewActivityRushData:getConditionByIdx(_idx)
    if self.m_rewardsData[_idx] then
        return self.m_rewardsData[_idx].condition
    end
    return 0
end

-- 获取总体任务完成条件
function QuestNewActivityRushData:getRushCompleteCondition()
    if next(self.m_rewardsData) then
        return self.m_rewardsData[#self.m_rewardsData].condition
    end
    return 0
end

-- 获取老数据的data process
function QuestNewActivityRushData:getOldDataProcess()
    if self.m_oldData then 
        return self.m_oldData.process
    else 
        return nil 
    end
end

-- 获取老数据的 进度
function QuestNewActivityRushData:getPreProcess()
    local process = self:getOldDataProcess()

    if not process or not next(process) then
        return self:getCurProcess()
    end

    return tonumber(process[1])
end

-- 获取新数据的 process
function QuestNewActivityRushData:getCurProcess()
    local condition = 0
    if self.m_process and next(self.m_process) then
        condition = self.m_process[1]
    end
    return tonumber(condition)
end

-- 获取奖励 集合
function QuestNewActivityRushData:getRewardsInfoList() 
    return self.m_rewardsData
end
-- 获取奖励 信息 _idx 
function QuestNewActivityRushData:getRewardDataByIdx(_idx)
    return self.m_rewardsData[_idx] or {}
end

-- 更新老数据
function QuestNewActivityRushData:resetOldData()
    local data = self:getData()
    self.m_oldData = data
    if self.m_oldData then
        self.m_oldStep = nil
        for idx,phase in ipairs(self.m_oldData.phaseResult) do
            if not self.m_oldStep or self.m_oldStep < phase.phase then
                self.m_oldStep = phase.phase
            end
            if phase.completed == false then
                break
            end
        end
    end
end

-- 活动类型
function QuestNewActivityRushData:getRushType()
    if self.taskId ~= nil and self.taskId ~= "nil" then
        return self.taskId
    else
        return "1001"
    end
end

-- 难度系数 -1忽略难度  1简单  2普通  3困难
function QuestNewActivityRushData:getDifficulty()
    return self.difficulty or 0
end

-- 当前任务进行到哪个阶段
function QuestNewActivityRushData:getCurrentStep()
    return self.m_curStep or 1
end

function QuestNewActivityRushData:getPreStep()
    return self.m_oldStep
end

return QuestNewActivityRushData