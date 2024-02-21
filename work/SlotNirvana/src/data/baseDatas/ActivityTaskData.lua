--[[
    活动任务数据
]]
local ActivityTaskDetailData = require("data.baseDatas.ActivityTaskDetailData")
local ActivityTaskData = class("ActivityTaskData")

ActivityTaskData.TASK_STATUS = {
    OVER = 2,
    BEGIN = 1,
    COMING = 0
}

ActivityTaskData.ACTIVITY_NAME = {
    ["Activity_BingoTask"]      = "BINGO",       --bingo任务
    ["Activity_CoinPusherTask"] = "COIN_PUSHER", --推币机任务
    ["Activity_BlastTask"]      = "BLAST",       --blast任务
    ["Activity_WordTask"]       = "WORD",        --word任务
    ["Activity_RichManTask"]    = "RICH_MAN",    --大富翁任务
    ["Activity_DiningRoomTask"] = "DINING_ROOM", --新版餐厅任务
    ["Activity_RedecorTask"]    = "REDECORATE",  --装修任务
    ["Activity_PokerTask"]      = "POKER",       --扑克任务
    ["Activity_WorldTripTask"]  = "WORLD_TRIP",   --新版大富翁任务
    ["Activity_NewCoinPusherTask"]      = "NEW_COIN_PUSHER",       --新版推币机任务
    ["Activity_PipeConnectTask"]      = "PIPE_CONNECT",       --接水管任务
    ["Activity_OutsideCaveTask"]      = "OUTSIDE_CAVE",       --大富翁2023旧版任务
    ["Activity_EgyptCoinPusherTask"] = "COIN_PUSHER_V3", --埃及推币机任务
}

function ActivityTaskData:ctor()
    self.m_parseAllData = false --是否解析过全部的任务数据
    self.m_openTaskView = false --是否打开了任务界面
    self.m_curTaskData  = nil   --当前任务
    self.p_TaskDataList = {}
    self.p_TaskDataClassifyList = {} -----分类后的全部活动数据
end
--活动任务数据解析
function ActivityTaskData:parseTaskData(_data)
    self:parseAllActivityTaskData(_data)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_UPDATE_DATA)
end
--解析全部的活动任务数据
function ActivityTaskData:parseAllActivityTaskData(_data)
    self.p_TaskDataList = {}
    if _data and #_data > 0 then
        self.p_TaskDataList = _data
    end
    if #self.p_TaskDataList > 0 then
        self:setDataFlag(true)
        self:activityDataClassify()
    end
end
--活动数据分类
function ActivityTaskData:activityDataClassify()
    self.p_TaskDataClassifyList = {} -----分类后的全部活动数据
    if #self.p_TaskDataList > 0 then
        for k, v in ipairs(self.p_TaskDataList) do
            local taskData = self:parseDetailData(v, true)
            local key = taskData:getActivityCommonType()
            local taskList = self.p_TaskDataClassifyList[key]
            if taskList then 
                table.insert(taskList, taskData)
            else
                self.p_TaskDataClassifyList[key] = {}
                table.insert(self.p_TaskDataClassifyList[key], taskData)
            end
        end
    end

    for k, v in ipairs(self.p_TaskDataClassifyList) do
        -- 根据阶段的顺序排序一下
        table.sort(
            v,
            function(a, b)
                return tonumber(a:getPhase()) < tonumber(b:getPhase())
            end
        )
    end 
end
--每条任务数据解析
function ActivityTaskData:parseDetailData(_data, _isSaveData)
    local taskObj = ActivityTaskDetailData:create()
    taskObj:parseData(_data, _isSaveData)
    return taskObj
end

--------------------------访问数据接口-----------------------

--根据活动名字获取活动任务
function ActivityTaskData:getTaskListByActivityName(_activityRef)
    local taskName = self.ACTIVITY_NAME[_activityRef]
    if taskName then 
        return self.p_TaskDataClassifyList[taskName]
    else
        return nil
    end
end
--检测是否打开任务入口
function ActivityTaskData:checkTaskData(_activityRef)
    local taskList = self:getTaskListByActivityName(_activityRef)
    if taskList and #taskList > 0 then 
        return true
    end

    return false
end
--根据活动名字获取活动正在进行的任务
function ActivityTaskData:getCurrentTaskByActivityName(_activityRef)
    local taskList = self:getTaskListByActivityName(_activityRef)
    if taskList and #taskList > 0 then 
        for i, v in ipairs(taskList) do
            if v:getStatus() == self.TASK_STATUS.BEGIN then
                return v
            end
        end
    end
    return nil
end
--根据活动名字,当前任务获取下个要开启的任务
function ActivityTaskData:getNextTaskByNameAndTask(_activityRef, _taskData)
    local lastTime = nil
    local nextTaskData = nil
    if _activityRef and _taskData then
        local taskList = self:getTaskListByActivityName(_activityRef)
        local comingTask = {}
        if taskList and #taskList > 0 then  
            for i, v in ipairs(taskList) do
                if v:getStatus() == self.TASK_STATUS.COMING and v:getPhase() > _taskData:getPhase() then
                    comingTask[#comingTask + 1] = v
                end
            end
        end
        for i = 1, #comingTask do
            local taskData = comingTask[i]
            local starTimer = taskData:getStart()
            if lastTime == nil or (starTimer < lastTime) then
                lastTime = starTimer
                nextTaskData = taskData
            end
        end
    end
    return nextTaskData
end

function ActivityTaskData:setDataFlag(_flag)
    self.m_parseAllData = _flag
end
function ActivityTaskData:setOpenFlag(_flag)
    self.m_openTaskView = _flag
end
return ActivityTaskData
