-- 新版新关挑战 数据
local SlotTrialsTaskData = require("activities.Activity_SlotTrials.model.SlotTrialsTaskData")
local BaseActivityData = require "baseActivity.BaseActivityData"
local SlotTrialsData = class("SlotTrialsData", BaseActivityData)

------------------------------------    游戏登录下发数据    ------------------------------------

-- message NewSlotChallengeConfig {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated string gameIdList = 4;//关卡id
--     repeated NewSlotChallengeTask taskList = 5;//任务列表
--     optional int64 minBet = 6;//活动开启最小bet 金币
-- }
-- 解析数据
function SlotTrialsData:parseData(data)
    BaseActivityData.parseData(self, data)

    self.minBetCoins = tonumber(data.minBet) or 0
    self.stage_list = {}
    for i, stage_id in ipairs(data.gameIdList) do
        table.insert(self.stage_list, stage_id)
    end

    self.cur_task = nil
    if not self.task_list then
        self.task_list = {}
    end
    self.task_cur_idx = 0
    self.task_counts = 0
    self.complete_counts = 0
    self.no_collect_counts = 0
    if #data.taskList > 0 then
        for idx, task_data in ipairs(data.taskList) do
            if not self.task_list[idx] then
                self.task_list[idx] = SlotTrialsTaskData:create()
            end
            local task_obj = self.task_list[idx]
            if task_obj then
                task_obj:parseData(task_data)
                if task_obj:getStatus() == "PROCESSING" then
                    self.cur_task = task_obj
                    self.task_cur_idx = idx
                end
                if task_obj:getStatus() == "FINISH" then
                    self.complete_counts = self.complete_counts + 1
                    if not task_obj:isCollected() then
                        self.no_collect_counts = self.no_collect_counts + 1
                    end
                end
            end
        end
        self.task_counts = #data.taskList
    end
    if not self.cur_task then
        self.cur_task = self.task_list[#self.task_list]
        self.task_cur_idx = #self.task_list
    end
    -- 数据刷新事件
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.SlotTrial})
end

function SlotTrialsData:getTaskData()
    return self.task_list
end

function SlotTrialsData:getTaskCounts()
    if self.task_list then
        return #self.task_list
    end
    return 0
end

function SlotTrialsData:getTaskDataByIdx(idx)
    if self.task_list and self.task_list[idx] then
        return self.task_list[idx]
    end
end

function SlotTrialsData:getCurTask()
    return self.cur_task
end

function SlotTrialsData:getMinBetCoins()
    return self.minBetCoins
end

function SlotTrialsData:getTaskProcess()
    return self.complete_counts, self.task_counts
end

function SlotTrialsData:getNoCollectCounts()
    return self.no_collect_counts
end

function SlotTrialsData:getStageList()
    return self.stage_list
end

function SlotTrialsData:getCompleteCounts()
    return self.complete_counts
end

function SlotTrialsData:isAllFinished()
    local complete_counts = self:getCompleteCounts()
    if not complete_counts or complete_counts <= 0 then
        return false
    end
    local task_counts = self:getTaskCounts()
    if not task_counts or task_counts <= 0 then
        return false
    end
    return (complete_counts == task_counts)
end

--获取入口位置 1：左边，0：右边
function SlotTrialsData:getPositionBar()
    return 1
end

function SlotTrialsData:isCanShowEntry()
    if not globalData.slotRunData or not globalData.slotRunData.machineData then
        return false
    end

    local id_list = self:getStageList()
    if id_list and #id_list <= 0 then
        return false
    end
    local id_exit = false
    local level_id = globalData.slotRunData.machineData.p_id
    for i, id in ipairs(id_list) do
        if tonumber(level_id) == tonumber(id) then
            id_exit = true
            break
        end
    end
    return id_exit
end

function SlotTrialsData:onComplete(idx)
    if not idx then
        return
    end

    self.complete_taskId = idx
    if self.complete_taskId > 0 then
        self:setWillPlayAnimation(true)
    end
end

function SlotTrialsData:getCompleteTaskId()
    return self.complete_taskId
end

function SlotTrialsData:setWillPlayAnimation(bl_play)
    self.bl_play = bl_play
end

function SlotTrialsData:getWillPlayAnimation()
    return self.bl_play
end

return SlotTrialsData
