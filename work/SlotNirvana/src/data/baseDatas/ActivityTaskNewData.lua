--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https:--www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-02 16:13:26
    describe:新版大活动任务数据
]]
local ActivityTaskDetailNewData = require("data.baseDatas.ActivityTaskDetailNewData")
local ActivityTaskNewData = class("ActivityTaskNewData")

ActivityTaskNewData.TASK_STATUS = {
    INIT = "INIT",
    PROCESSING = "PROCESSING",
    FINISH = "FINISH",
}

ActivityTaskNewData.ACTIVITY_NAME = {
    ["Activity_BlastTaskNew"]      = "BLAST",       --blast任务
    ["Activity_CoinPusherMissionNew"]      = "COIN_PUSHER",       --推币机任务
    ["Activity_WordTaskNew"]       = "WORD",       --word任务
    ["Activity_OutsideCaveMissionNew"]       = "OUTSIDE_CAVE",       --大富翁任务
}

function ActivityTaskNewData:ctor()
    self.m_curTaskData  = nil   --当前任务
    self.m_oldCompleteList = {} --旧任务完成列表
    self.m_newCompleteList = {} --新任务完成列表
    self.m_aniTaskList = {} --动画任务列表
    self.p_TaskDataList = nil --任务全部数据
end

--活动任务数据解析
function ActivityTaskNewData:parseTaskData(_data)
    self:parseDetailData(_data)
    self:parseCompleteTaskIndex()
    self:parseAniTaskList()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_UPDATE_DATA)
end

--每条任务数据解析
function ActivityTaskNewData:parseDetailData(_data)
    if not self.p_TaskDataList then
        self.p_TaskDataList = ActivityTaskDetailNewData:create()
    end
    self.p_TaskDataList:parseData(_data)
end

--解析完成任务的索引
function ActivityTaskNewData:parseCompleteTaskIndex()
    local taskList = self.p_TaskDataList
    if taskList then 
        local normalTaskList = taskList:getMissionList()
        self.m_newCompleteList = normalTaskList
        if #self.m_oldCompleteList == 0 then
            self.m_oldCompleteList = normalTaskList
        end
    end
end

--获得需要动画的任务列表
function ActivityTaskNewData:parseAniTaskList()
    if self:checkIsFinish() then
        return
    end
    for i = 1, #self.m_newCompleteList do
        local oldData = self.m_oldCompleteList[i]
        local newData = self.m_newCompleteList[i]
        
        if oldData.missionId ~= newData.missionId then
            table.insert(self.m_aniTaskList, {index = i, data = oldData, newData = newData})
        end
    end
    if #self.m_aniTaskList <= 0 then
        self.m_oldCompleteList = self.m_newCompleteList
    end
end

-- 进度是否收集满
function ActivityTaskNewData:checkIsFinish()
    local taskList = self.p_TaskDataList
    local isFinish = true
    if taskList then 
        local stageRewardList = taskList:getStageRewardList()
        for i, v in ipairs(stageRewardList) do
            if v.finish == false or v.collect == false then
                isFinish = false
                break
            end
        end
    end

    return isFinish
end

--------------------------访问数据接口-----------------------

--根据活动名字获取活动任务
function ActivityTaskNewData:getTaskDataByActivityName(_activityRef)
    local taskName = self.ACTIVITY_NAME[_activityRef]
    local key = ""
    if self.p_TaskDataList then
        key = self.p_TaskDataList:getActivityCommonType()
    end
    if taskName and key ~= "" and key == taskName then 
        return self.p_TaskDataList
    else
        return nil
    end
end

--检测是否打开任务入口
function ActivityTaskNewData:checkTaskData(_activityRef)
    local taskList = self:getTaskDataByActivityName(_activityRef)
    if taskList then 
        return true
    end

    return false
end

--根据活动名字获取活动正在进行的任务
function ActivityTaskNewData:getCurrentTaskByActivityName(_activityRef)
    local taskList = self:getTaskDataByActivityName(_activityRef)
    if not taskList then
        return nil
    end
    local normalTaskList = taskList:getMissionList()
    if #normalTaskList > 0 then
        return normalTaskList
    end
    return nil
end

--根据活动名字获取活动上一个完成的任务
function ActivityTaskNewData:getLastTaskByActivityName(_activityRef)
    local taskList = self:getTaskDataByActivityName(_activityRef)
    if not taskList then
        return nil
    end
    return self.m_oldCompleteList
end

--根据活动名字检测是否有任务奖励可领取
function ActivityTaskNewData:checkIsHasTaskReward(_activityRef)
    local taskList = self:getTaskDataByActivityName(_activityRef)
    if taskList then 
        local stageRewardList = taskList:getStageRewardList()
        for i, v in ipairs(stageRewardList) do
            if v.finish == true and v.collect == false then
                return true
            end
        end
    end

    return false
end

--根据活动名字获得完成的任务列表
function ActivityTaskNewData:getAniTaskList(_activityRef)
    local taskList = self:getTaskDataByActivityName(_activityRef)
    if taskList then
        return self.m_aniTaskList
    end
    return {}
end

function ActivityTaskNewData:clearAniTaskList()
    self.m_aniTaskList = {}
    self.m_oldCompleteList = self.m_newCompleteList
end

-- 得到可领取的任务奖励列表
function ActivityTaskNewData:getTaskReward(_activityRef)
    local list = {coins = 0, itemList = {}}
    local taskList = self:getTaskDataByActivityName(_activityRef)
    if taskList then
        local index = 0
        local stageRewardList = taskList:getStageRewardList()
        for i, v in ipairs(stageRewardList) do
            if v.finish == true and v.collect == false then
                list.coins = list.coins + v.coins
                for i = 1, #v.itemList do
                    table.insert(list.itemList, v.itemList[i])
                end
                if i == #stageRewardList then
                    index = 1
                end
                list.index = index
            end
        end
    end
    return list
end

-- 得到可领取任务的阶段字符（以分号隔开 "1;2;3"）
function ActivityTaskNewData:getStageStr(_activityRef)
    local stageStr = ""
    local taskList = self:getTaskDataByActivityName(_activityRef)
    if taskList then
        local stageRewardList = taskList:getStageRewardList()
        for i, v in ipairs(stageRewardList) do
            if v.finish == true and v.collect == false then
                if stageStr == "" then
                    stageStr = stageStr .. v.stage
                else
                    stageStr = stageStr .. ";" .. v.stage
                end
            end
        end
    end
    return stageStr
end

-- 得到任务入口进度
function ActivityTaskNewData:getEntryProgress(_activityRef)
    local progress = 0
    local minPoint = 0
    local maxPoint = 0
    local taskList = self:getTaskDataByActivityName(_activityRef)
    if taskList then
        local curPoints = taskList:getCurrentPoints()
        local stageRewardList = taskList:getStageRewardList()
        for i, v in ipairs(stageRewardList) do
            if v.needPoints <= curPoints then
                minPoint = v.needPoints
            else
                maxPoint = v.needPoints
                break
            end
        end
        progress = (curPoints - minPoint) / (maxPoint - minPoint) * 100
    end
    return math.floor(progress), maxPoint, minPoint
end

return ActivityTaskNewData
