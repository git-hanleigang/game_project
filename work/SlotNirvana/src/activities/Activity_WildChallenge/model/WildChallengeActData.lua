--[[
Author: cxc
Date: 2022-03-23 16:07:04
LastEditTime: 2022-03-23 16:07:05
LastEditors: cxc
Description: 3日行为付费聚合活动  数据类
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/model/WildChallengeActData.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local WildChallengeActData = class("WildChallengeActData", BaseActivityData)
local WildChallengeActPhaseData = require("activities.Activity_WildChallenge.model.WildChallengeActPhaseData")

-- message WildChallenge {
--     optional string activityId = 1;
--     optional int32 expire = 2;
--     optional int64 expireAt = 3;
--     optional int32 current = 4; //当前位置 0-5
--     repeated WildChallengeTask tasks = 5;// 任务
--   }
function WildChallengeActData:ctor()
    WildChallengeActData.super.ctor(self)
    self.m_bInit = false
    self.m_bComplete = false
    self.m_hadUncollectedTask = false 
    self.m_current = 1
    self.m_taskList = {}  -- 任务list
end

function WildChallengeActData:parseData(_data)
    if not _data then
        return
    end
    WildChallengeActData.super.parseData(self, _data)
    
    self.m_current = (tonumber(_data.current) or 0) + 1
    self:parsePhaseListData(_data.tasks)
    if not self.m_bInit then
        self:updateCompleteSign()
        self:setOpenFlag(not self.m_bComplete)
    end
    self.m_bInit = true

    -- -- 检查是否完成
    -- if not self:isCompleted() then
    --     self:setCompleted(self:checkCompleteCondition())
    -- end
end

-- 解析任务数据
function WildChallengeActData:parsePhaseListData(_list)
    self.m_taskList = {}  -- 任务list
    self.m_hadUncollectedTask = false
    for _, data in ipairs(_list or {}) do
        local phaseData = WildChallengeActPhaseData:create()
        phaseData:parseData(data)
        -- 任务状态 0初始化 1开启 2完成 3已领取
        if not (phaseData:isFirst() and phaseData:isFree()) then
            if phaseData:getStatus() == 2 then
                self.m_hadUncollectedTask = true
            end
        end
        table.insert(self.m_taskList, phaseData)
    end
end

-- 获取当前解锁的任务 idx
function WildChallengeActData:getCurPhaseIdx()
    return self.m_current
end

-- 获取任务数据
function WildChallengeActData:getPhaseListData()
    return self.m_taskList
end
-- 获取任务数据
function WildChallengeActData:getPhaseListDataByIdx(_idx)
    return self.m_taskList[_idx] or WildChallengeActPhaseData:create()
end

-- 检查是否有可领取的 任务
function WildChallengeActData:setUncollectedTask(_bUncollected)
    self.m_hadUncollectedTask = _bUncollected
end
function WildChallengeActData:checkUncollectedTask()
    return self.m_hadUncollectedTask
end

-- 任务是否都领取完了
function WildChallengeActData:updateCompleteSign()
    if self.m_current < #self.m_taskList then
        return
    end
    local lastPhaseData = self.m_taskList[#self.m_taskList]
    if lastPhaseData and lastPhaseData:getStatus() == 3 then
        self.m_bComplete = true
    end
end

function WildChallengeActData:checkCompleteCondition()
    return self.m_bComplete
end   

function WildChallengeActData:getPositionBar()
    -- 默认右边，修改重写该方法
    return 1
end

return WildChallengeActData
