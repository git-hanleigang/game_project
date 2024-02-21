-- 活动任务(只是一个弹板， 有这个活动open 就为true)
local BaseActivityData = require("baseActivity.BaseActivityData")
local ActivityTaskPushViewData = class("ActivityTaskPushViewData", BaseActivityData)

function ActivityTaskPushViewData:ctor()
    ActivityTaskPushViewData.super.ctor(self)

    self.m_curTaskData = nil
    self.p_open = true
end

function ActivityTaskPushViewData:parseData(_data)
    ActivityTaskPushViewData.super.parseData(self, _data)
end

function ActivityTaskPushViewData:setCurTaskData(_taskData)
    self.m_curTaskData = _taskData
end

function ActivityTaskPushViewData:getCurTaskData()
    if not self.m_curTaskData then 
        self.m_curTaskData = globalData.activityTaskData:getCurrentTaskByActivityName(self:getRefName())
    end

    return self.m_curTaskData
end

return ActivityTaskPushViewData


