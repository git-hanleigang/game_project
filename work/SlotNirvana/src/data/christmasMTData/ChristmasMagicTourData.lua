--[[
    CharistmasMTData
    author:{author}
    time:2020-12-09 11:32:18
]]
-- FIX IOS 139
local BaseActivityData = require("baseActivity.BaseActivityData")
local ChristmasMTRewardData = require("data.christmasMTData.ChristmasMagicTourRewardData")
local ChristmasMTTaskData = require("data.christmasMTData.ChristmasMagicTourTaskData")

local ChristmasMagicTourData = class("ChristmasMagicTourData", BaseActivityData)

function ChristmasMagicTourData:ctor()
    ChristmasMagicTourData.super.ctor(self)
    -- expire 、expireAt、 activityId   ---> goto BaseActivityData 
    -- definition self params
    self.m_maxPoints = 0

    self.m_currentPoints = 0

    self.m_phase = 1

    self.m_taskData = {}

    self.m_rewardData = {}

    self.m_finishAll = false -- 针对整个活动是否已经完成手机了

    self.m_finish = nil -- 针对第一阶段活动结束的判断
end

function ChristmasMagicTourData:parseData(data)
    if not data then
        return
    end
    ChristmasMagicTourData.super.parseData(self, data)

    self.m_maxPoints = data.maxPoints
    self.m_currentPoints = data.currentPoints
    self.m_phase = data.phase
    self.m_finishAll = data.finish
    -- parse Task
    self.m_taskData = {}
    for i = 1, #(data.tasks or {}) do
        local task = data.tasks[i]
        local taskData = ChristmasMTTaskData:create()
        taskData:parseData(task)
        table.insert(self.m_taskData, taskData)
    end
    -- parse Reward
    self.m_rewardData = {}
    for k = 1, #(data.rewards or {}) do
        local rewards = data.rewards[k]
        local rewardData = ChristmasMTRewardData:create()
        rewardData:parseData(rewards)
        table.insert(self.m_rewardData, rewardData)
    end

    print("------ ChristmasMagicTourData:parseData end")
end

function ChristmasMagicTourData:getMaxPoints( )
    return self.m_maxPoints
end

function ChristmasMagicTourData:getCurrentPoints( )
    return self.m_currentPoints
end

function ChristmasMagicTourData:getPhase( )
    return self.m_phase
end

function ChristmasMagicTourData:getTaskData( )
    return self.m_taskData 
end

function ChristmasMagicTourData:getRewardData( )
    return self.m_rewardData
end

function ChristmasMagicTourData:getFinishAll( )
    return self.m_finishAll
end

-- 检查完成条件 (只针对完成第一阶段)
function ChristmasMagicTourData:checkCompleteCondition()
    if #self.m_rewardData == 1 then
        -- if self.m_rewardData[1]:getCollected() == true then
            self.m_finish = true
        -- end
    end
    if self.m_finish ~= nil and self.m_finish == true then
        return true
    end    
    return false
end

function ChristmasMagicTourData:getEntranceName( )
    local keyName = "Activity_ChristmasMagicTour"
    if gLobalChristmasMTManager:getIsOpen() then
        if self:getFinishAll() == false then
            -- 需要判断当前的阶段
            if gLobalChristmasMTManager:getIsRewardPhase() then
                keyName = "Activity_ChristmasMagicTour_reward"
            else
                keyName = "Activity_ChristmasMagicTour"
            end
        end
    end
    return keyName
end

function ChristmasMagicTourData:isRunning( )
    if ChristmasMagicTourData.super.isRunning(self) == false then
        return false
    end

    if self:getFinishAll() == true then
        return false
    end

    return true
end


return ChristmasMagicTourData
