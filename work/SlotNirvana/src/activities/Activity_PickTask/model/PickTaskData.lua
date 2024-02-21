--[[
    2周年
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require("baseActivity.BaseActivityData")
local PickTaskData = class("PickTaskData",BaseActivityData)

-- message OptionalTask {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated OptionalTaskTaskInfo tasks = 4; // 任务
--     optional int32 rewardStatus = 5; // 奖励状态，0，不可领，1，可领，2，已领
--     repeated ShopItem itemReward = 6; // 奖励
--     repeated int32 finishCount = 7; // 已完成任务数量
--   }
function PickTaskData:parseData(_data)
    PickTaskData.super.parseData(self, _data)

    self.p_finishMax = 3
    self.p_rewardStatus = _data.rewardStatus
    self.p_finishCount = _data.finishCount
    self.p_tasks = self:parseTasks(_data.tasks)
    self.p_itemReward = self:parseItemReward(_data.itemReward)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PICK_TASK_COMPLETE)
end

-- message OptionalTaskTaskInfo {
--     optional string taskId = 1; //任务id
--     optional bool taskFinish = 2; //任务是否完成
--     optional int64 param = 3; //任务参数
--     optional int64 process = 4; //任务进度
--     optional string text = 5; //text
--     optional string textB = 6; //textB
--     optional string icon = 7; // icon
--   }
function PickTaskData:parseTasks(_data)
    -- 通用道具
    local taskData = {}
    local taskStatus = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_taskId = v.taskId
            tempData.p_taskFinish = v.taskFinish
            tempData.p_param = tonumber(v.param)
            tempData.p_process = tonumber(v.process)
            tempData.p_text = v.text
            tempData.p_textB = v.textB
            tempData.p_icon = v.icon
            table.insert(taskData, tempData)
            taskStatus[v.icon] = v.taskFinish
        end
    end
    G_GetMgr(ACTIVITY_REF.PickTask):setTaskStatus(taskStatus)
    return taskData
end

function PickTaskData:parseItemReward(_data)
    -- 通用道具
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

function PickTaskData:getRewardStatus()
    return self.p_rewardStatus
end

function PickTaskData:getFinishCount()
    return self.p_finishCount
end

function PickTaskData:getFinishMax()
    return self.p_finishMax
end

function PickTaskData:getTasks()
    return self.p_tasks    
end

function PickTaskData:getItemReward()
    return self.p_itemReward
end

function PickTaskData:checkTaskBegan()
    local flag = false
    for i,v in ipairs(self.p_tasks) do
        if v.p_taskFinish or v.p_process > 0 then
            flag = true
            break
        end
    end

    return flag
end

function PickTaskData:isRunning()
    if self.p_rewardStatus and self.p_rewardStatus == 2 then
        return false
    else
        return PickTaskData.super.isRunning(self)
    end
end

return PickTaskData
