-- 任务数据

local BaseActivityData = require "baseActivity.BaseActivityData"
local DIYFeatureMissionData = class("DIYFeatureMissionData", BaseActivityData)
local DIYFeatureMissionTaskData = util_require("activities.Activity_DIYFeatureMission.model.DIYFeatureMissionTaskData")
-- message DiyFeatureMission {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated DiyFeatureMissionTask simpleTask = 4; //简单任务
--     repeated DiyFeatureMissionTask hardTask = 5; //困难任务
--     optional bool over = 6; //任务全部完成标识
--     optional int32 rewardPoint = 7; //简单任务总奖励点数
-- }
local PAGE_TYPE = {
    Simple = 1,
    Hard = 2
}
function DIYFeatureMissionData:ctor()
    DIYFeatureMissionData.super.ctor(self)
    self.m_hardTaskListOld  = nil
    self.m_hardTaskList = nil
end

function DIYFeatureMissionData:parseData(data)
    DIYFeatureMissionData.super.parseData(self, data)
    self.m_activityId = data.activityId
    self.m_simpleTaskList = self:parseTaskData(data.simpleTask)

    --困难任务
    if nil == self.m_hardTaskList then
        self.m_hardTaskListOld = self:parseTaskData(data.hardTask)
    end
    self.m_hardTaskList = self:parseTaskData(data.hardTask)

    self.m_over = data.over
    self.m_rewardPoint = tonumber(data.rewardPoint)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DIYFEATUREMISSION_DATA_UPDATE)
end

function DIYFeatureMissionData:parseTaskData(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local taskData = DIYFeatureMissionTaskData:create()
            taskData:parseData(v)
            table.insert(list, taskData)
        end
    end
    return list
end

function DIYFeatureMissionData:getTaskData(_type)
    if _type == PAGE_TYPE.Simple then
        return self.m_simpleTaskList
    elseif _type == PAGE_TYPE.Hard then
        local mgr = G_GetMgr(ACTIVITY_REF.DIYFeatureMission)
        local type = mgr:getFeature()
        if type then
            return self.m_hardTaskListOld
        else
            return self.m_hardTaskList
        end
    else
        return nil
    end
end

--获取入口位置 1：左边，0：右边
function DIYFeatureMissionData:getPositionBar()
    return 1
end

-- 获取可领取任务
function DIYFeatureMissionData:getTaskCompleteNum()
    local num = 0
    for i,v in ipairs(self.m_simpleTaskList) do
        -- 获取每条任务的可领取次数
        local completeNum = v:getRewardCount()
        num = num + completeNum
    end
    --特殊任务完成就领取 不需计数
    return num
end

--获取总点数
function DIYFeatureMissionData:getTotalPoints()
    return self.m_rewardPoint
end

function DIYFeatureMissionData:getHardTaskListOld()
    return self.m_hardTaskListOld
end

function DIYFeatureMissionData:updataHardTaskListOld()
    self.m_hardTaskListOld = self.m_hardTaskList
end

function DIYFeatureMissionData:getIsOver()
    --需判断旧数据是否都完成
    if self.m_hardTaskListOld then
        for k,v in ipairs(self.m_hardTaskListOld) do
            local isOver = v:getOver()
            if not isOver then
                return false
            end
        end
    end
    return self.m_over
end

function DIYFeatureMissionData:hardTaskHandle()
    --self.m_hardTaskList 
    --self.m_hardTaskListOld
    --比较差异 是否有任务完成
    --local list = {}
    local task = nil
    for k,v in ipairs(self.m_hardTaskListOld) do
        local taskId = v:getTaskId()
        local finish = v:getFinish()
        for k2,v2 in ipairs(self.m_hardTaskList) do
            local taskIdNew = v2:getTaskId()
            if taskIdNew == taskId and not finish and v2:getFinish() then
                task = v
                task.index = k
                -- 设置旧数据任务，但不能置为任务结束状态（不能压暗） 
                --v:unpdateHardTaskData()
                break
            end
        end
        if task ~= nil then
            break
        end
    end
    return task
end

--是否结束活动
function DIYFeatureMissionData:checkCompleteCondition()
    local val = DIYFeatureMissionData.super.checkCompleteCondition(self)
    if not val then
        val = self:getIsOver()
    end
    return val
end


return DIYFeatureMissionData
