--[[
    圣诞聚合 -- pass
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local HolidayTaskData = require("activities.Activity_HolidayNewChallenge.HolidayPass.model.HolidayTaskData")
local HolidayPointData = require("activities.Activity_HolidayNewChallenge.HolidayPass.model.HolidayPointData")
local HolidayPassData = class("HolidayPassData", BaseActivityData)

--[[
    message HolidayNewChallengePass {
        optional string activityId = 1; // 活动的id
        optional string activityName = 2;// 活动的名称
        optional string begin = 3;// 活动的开启时间
        optional int64 expireAt = 4; // 活动倒计时
        optional int32 curProgress = 5; // 当前进度
        optional bool paid = 6; // 是否已经付费
        optional string key = 7;// 对应的档位
        optional string keyId = 8; // 对应的支付连接
        optional string price = 9; // 价格
        repeated HolidayNewChallengePassTask taskDataList = 10; // 任务数据
        repeated HolidayNewChallengePassPoint pointDataList = 11;// 奖励数据
        optional int32 totalProgress = 12; // 总进度
    }
]]
function HolidayPassData:parseData(_data)
    HolidayPassData.super.parseData(self, _data)
    self.p_curProgress = _data.curProgress
    self.p_paid = _data.paid
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_totalProgress = _data.totalProgress
    if not self.p_preProgress then
        self.p_preProgress = self.p_curProgress
    end

    self.p_taskDataList = {}
    if _data.taskDataList and #_data.taskDataList > 0 then
        for i = 1, #_data.taskDataList do
            local task = HolidayTaskData:create()
            task:parseData(_data.taskDataList[i])
            table.insert(self.p_taskDataList, task)
        end
    end

    self.m_pointList = {}
    self.p_pointDataList = {}
    if _data.pointDataList and #_data.pointDataList > 0 then
        for i = 1, #_data.pointDataList do
            local task = HolidayPointData:create()
            task:parseData(_data.pointDataList[i], _data.curProgress, _data.paid)
            table.insert(self.p_pointDataList, task)
            table.insert(self.m_pointList, task:getProgress())
        end
    end
end

-- 本地记录数据 上次进度
function HolidayPassData:getPreProgress()
    return self.p_preProgress
end

-- 刷新上次进度为最新
function HolidayPassData:refreshPreProgress()
    self.p_preProgress = self.p_curProgress
end

-- 获得增加的进度
function HolidayPassData:getAddProgress()
    local addProgress = self.p_curProgress - self.p_preProgress
    return addProgress or 0
end

function HolidayPassData:setCurProgress(_progress)
    self.p_curProgress = _progress
    for i, v in ipairs(self.p_pointDataList) do
        v:setCurProgress(_progress)
    end
end

function HolidayPassData:getCurProgress()
    return self.p_curProgress
end

function HolidayPassData:getTotalProgress()
    return self.p_totalProgress
end

function HolidayPassData:getIsPay()
    return self.p_paid
end

function HolidayPassData:getKeyId()
    return self.p_keyId
end

function HolidayPassData:getPrice()
    return self.p_price
end

function HolidayPassData:getTaskDataList()
    local taskList = {}
    if #self.p_taskDataList > 0 then
        local completeList = {}
        for i, v in ipairs(self.p_taskDataList) do
            if v:getCompleted() then
                table.insert(completeList, v)
            else
                table.insert(taskList, v)
            end
        end
        table.insertto(taskList, completeList)
    end
    return taskList
end

function HolidayPassData:getPointDataList()
    return self.p_pointDataList
end

function HolidayPassData:hasPassCompleteReward()
    local isComplete = false
    for i, v in ipairs(self.p_pointDataList) do
        if self.p_curProgress >= v:getProgress() and self.p_preProgress < v:getProgress() then
            if v:hasPassCompleteReward() then
                isComplete = true
                break
            end
        end
    end
    return isComplete
end

function HolidayPassData:getPassCurLevelIndex()
    for i, v in ipairs(self.p_pointDataList) do
        if self.p_curProgress <= v:getProgress() then
            return i
        end
    end
    return 0
end

function HolidayPassData:getPassPreLevelIndex()
    for i, v in ipairs(self.p_pointDataList) do
        if self.p_preProgress <= v:getProgress() then
            return i
        end
    end
    return 0
end

function HolidayPassData:getPointList()
    return self.m_pointList
end

return HolidayPassData
