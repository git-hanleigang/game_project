local BaseActivityData = require "baseActivity.BaseActivityData"
local TimeLimitExpansionData = class("TimeLimitExpansionData", BaseActivityData)

function TimeLimitExpansionData:ctor()
    TimeLimitExpansionData.super.ctor(self)
end

--[[
    message TimeLimitExpansion {
        optional string activityId = 1; // 活动的id
        optional string activityName = 2;// 活动的名称
        optional string begin = 3;// 活动的开启时间
        optional string end = 4;// 活动的结束时间
        optional int64 expireAt = 5; // 活动倒计时
        optional int32 totalExpansion = 6;// 活动总膨胀数
        optional TimeLimitTaskResult timeLimitTaskResult = 7;// 免费的任务
        repeated TimeLimitTaskResult timeLimitActiveTask = 8;// 活跃任务
        repeated TimeLimitTaskResult timeLimitPayTask = 9;// 付费任务
        optional string payTotalProcess = 10;// 付费任务的总进度
        optional bool clientActiveTaskFinish = 11;// 通知客户端活跃任务完成
    }
]]
function TimeLimitExpansionData:parseData(data)
    BaseActivityData.parseData(self, data)
    self.p_totalExpansion = data.totalExpansion -- 活动总膨胀数
    self.p_timeLimitActiveTask = self:parseTaskList(data.timeLimitActiveTask)
    self.p_timeLimitPayTask = self:parseTaskList(data.timeLimitPayTask)
    if not self.p_lastActiveTaskList then
        self.p_lastActiveTaskList = self.p_timeLimitActiveTask
    end
    if not self.p_lastPayTaskList then
        self.p_lastPayTaskList = self.p_timeLimitPayTask
    end
end

--[[
    message TimeLimitTaskResult {
        optional int32 seq = 1; // 任务序号
        optional string params = 2;// 任务参数
        optional string process = 3;// 进度条
        optional int32 expansion = 4; // 任务完成时增加的膨胀系数
        optional bool finish = 5;// 任务是否完成
        optional string description = 6;// 任务描述
    }
]]
--解析任务数据
function TimeLimitExpansionData:parseTaskList(data, type)
    local infoList = {}
    for i, v in ipairs(data) do
        local info = {}
        info.seq = tonumber(v.seq)
        info.params = tonumber(v.params)
        info.process = tonumber(v.process)
        info.expansion = tonumber(v.expansion)
        info.finish = v.finish
        info.description = v.description
        info.isLast = tonumber(i) == #data -- 是否是最后一个任务
        table.insert(infoList, info)
    end
    return infoList
end

-- 活跃任务
function TimeLimitExpansionData:getActiveTask()
    return self.p_timeLimitActiveTask
end

-- 付费任务
function TimeLimitExpansionData:getPayTask()
    return self.p_timeLimitPayTask
end

-- 活动膨胀数
function TimeLimitExpansionData:getTotalExpansion()
    return self.p_totalExpansion or 0
end

-- 刷新活动任务数据
function TimeLimitExpansionData:refreshActivityTaskList()
    self.p_lastActiveTaskList = self.p_timeLimitActiveTask
end

-- 刷新付费任务数据
function TimeLimitExpansionData:refreshPayTaskList()
    self.p_lastPayTaskList = self.p_timeLimitPayTask
end

-- return 是否完成新任务， 上一个任务数据， 当前任务数据
function TimeLimitExpansionData:getLastAndFinishTask(_type)
    local isComplete = false
    if _type == "active" then
        local previousTaskData = self.p_lastActiveTaskList[#self.p_lastActiveTaskList]
        local curTaskData = self.p_timeLimitActiveTask[#self.p_timeLimitActiveTask]
        for i = #self.p_lastActiveTaskList, 1, -1 do
            local lastTask = self.p_lastActiveTaskList[i]
            local curTask = self.p_timeLimitActiveTask[i]
            if not lastTask.finish then
                previousTaskData = lastTask
            end
            if not curTask.finish then
                curTaskData = curTask
            end
        end
        if curTaskData.seq > previousTaskData.seq then
            isComplete = true
        else
            if curTaskData.finish and not previousTaskData.finish then
                isComplete = true
            end
        end
        return isComplete, previousTaskData, curTaskData
    elseif _type == "pay" then
        local previousTaskData = self.p_lastPayTaskList[#self.p_lastPayTaskList]
        local curTaskData = self.p_timeLimitPayTask[#self.p_timeLimitPayTask]
        for i = #self.p_lastPayTaskList, 1, -1 do
            local lastTask = self.p_lastPayTaskList[i]
            local curTask = self.p_timeLimitPayTask[i]
            if not lastTask.finish then
                previousTaskData = lastTask
            end
            if not curTask.finish then
                curTaskData = curTask
            end
        end
        if curTaskData.seq > previousTaskData.seq then
            isComplete = true
        else
            if curTaskData.finish and not previousTaskData.finish then
                isComplete = true
            end
        end
        return isComplete, previousTaskData, curTaskData
    end
    return false, nil, nil
end

return TimeLimitExpansionData
