-- 现实任务数据

local BaseActivityData = require "baseActivity.BaseActivityData"
local DIYFeatureMissionTaskData = class("DIYFeatureMissionTaskData", BaseActivityData)
local DIYFeatureMissionRewardBuffData = util_require("activities.Activity_DIYFeatureMission.model.DIYFeatureMissionRewardBuffData")
-- message DiyFeatureMissionTask {
--     optional string taskId = 1; //任务id
--     optional string text = 2; //任务文本
--     optional string textB = 3; //任务文本b
--     optional string param = 4; //参数
--     optional int32 times = 5; //任务总次数
--     optional int32 curTimes = 6; //当前次数
--     optional string point = 7; //完成点数
--     optional string total = 8; //当前点数
--     optional bool finish = 9; //本次任务是否完成
--     optional bool over = 10; //任务是否全部完成
--     repeated DiyFeatureBuff rewardBuff = 11; //奖励buff
--     optional int32 rewardPoint = 12; //奖励点数
--     optional int32 rewardCount = 13; //可领取次数
-- }
function DIYFeatureMissionTaskData:parseData(data)
    DIYFeatureMissionTaskData.super.parseData(self, data)
    self.m_taskId = data.taskId
    self.m_text = data.text
    self.m_textB = data.textB
    self.m_param = data.param
    self.m_times = tonumber(data.times)
    self.m_curTimes = tonumber(data.curTimes)
    self.m_point = data.point
    self.m_total = data.total
    self.m_finish = data.finish
    self.m_over = data.over
    self.m_rewardBuff = self:parseBuffData(data.rewardBuff)
    self.m_rewardPoint = data.rewardPoint
    self.m_rewardCount = data.rewardCount
end

function DIYFeatureMissionTaskData:parseBuffData(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local taskData = DIYFeatureMissionRewardBuffData:create()
            taskData:parseData(v)
            table.insert(list, taskData)
        end
    end
    return list
end

function DIYFeatureMissionTaskData:getTaskId()
    return  self.m_taskId
end

function DIYFeatureMissionTaskData:getTask()
    return  self.m_text 
end

function DIYFeatureMissionTaskData:getTaskB()
    return  self.m_textB
end

function DIYFeatureMissionTaskData:getParam()
    return  self.m_param
end

function DIYFeatureMissionTaskData:getTimes()
    return  self.m_times
end

function DIYFeatureMissionTaskData:getCurTimes()
    return  self.m_curTimes 
end

function DIYFeatureMissionTaskData:getPoint()
    return  self.m_point
end

function DIYFeatureMissionTaskData:getTotal()
    return  self.m_total
end

function DIYFeatureMissionTaskData:getFinish()
    return  self.m_finish
end

function DIYFeatureMissionTaskData:getOver()
    return  self.m_over
end

function DIYFeatureMissionTaskData:getRewardBuff()
    return  self.m_rewardBuff
end

function DIYFeatureMissionTaskData:getRewardPoint()
    return  self.m_rewardPoint
end

function DIYFeatureMissionTaskData:getRewardCount()
    return  self.m_rewardCount
end

--获取任务剩余次数
function DIYFeatureMissionTaskData:getResidualDegree()
    local num = 0
    -- 任务总次数 任务当前序号
    if not self.m_over then
        num = self.m_times - self.m_curTimes + 1
    end
    return  num
end

function DIYFeatureMissionTaskData:unpdateHardTaskData()
    self.m_total = self.m_point
    self.m_finish = true
    self.m_over = false
end


return DIYFeatureMissionTaskData
