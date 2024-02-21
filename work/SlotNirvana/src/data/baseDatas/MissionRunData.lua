--- 每日任务 管理

local MissionRunData = class("MissionRunData")
local MissionTaskRunData = require "data.baseDatas.MissionTaskRunData"

local ShopItem = util_require("data.baseDatas.ShopItem")

MissionRunData.p_totalMissionNum = nil -- 任务总数
MissionRunData.p_currMissionID = nil -- 当前任务 id
MissionRunData.p_allMissionCompleted = nil -- 是否完成所有任务
MissionRunData.p_taskInfo = nil -- 当前任务 信息
MissionRunData.p_weekTaskInfo = nil -- 周任务信息
MissionRunData.p_weekEnd = nil -- 周任务结束时间
MissionRunData.p_sysTime = nil
MissionRunData.p_bIsPopTip = nil
MissionRunData.p_rewards = nil -- 奖励信息

function MissionRunData:ctor()
    self.p_taskInfo = MissionTaskRunData:create()

    self.m_lastQueryTs = 0
    self.m_queryCount = 0
end

--之前未完成  新数据完成情况下发送日志
function MissionRunData:checkCompleteTask(isComplete)
    if isComplete ~= nil and isComplete == false and self.p_taskInfo and self.p_taskInfo.p_taskCompleted then
        local logFeature = gLobalSendDataManager:getLogFeature()
        if logFeature and logFeature.sendDailyMissionLog then
            logFeature:sendDailyMissionLog(nil, nil, "TaskFinish")
        end
    end
end

function MissionRunData:parseData(data)
    if not data.total or data.total <= 0 then
        return
    end
    self.p_totalMissionNum = data.total -- 任务总数
    self.p_currMissionID = data.current -- 当前任务 id
    self.p_allMissionCompleted = data.completed -- 是否完成所有任务

    -- 解析reward
    self.p_rewards = {}
    local rewardInfo = data.rewards
    if rewardInfo then
        for k, v in ipairs(rewardInfo) do
            local shopItem = ShopItem:create()
            shopItem:parseData(v.rewards[1])
            local newData = {taskPosition = v.taskPosition, rewards = shopItem}
            table.insert(self.p_rewards, newData)
        end
    end

    local isComplete = nil
    if self.p_taskInfo then
        isComplete = self.p_taskInfo.p_taskCompleted
    end
    self.p_taskInfo:parseData(data.task) -- 当前任务 信息
    self:checkCompleteTask(isComplete)

    -- 这里做了判断处理，避免服务器数据发过来为nil的情况 wuxi update on 2019-12-24 15:31:29
    self.p_weekEnd = tonumber(data.weekEnd) or 0

    self.p_gems = tonumber(data.gems) or 0
    self.p_refreshGems = tonumber(data.refreshGems) or 0

    self.p_weekTaskInfo = {}
    for i = 1, #data.weekTask, 1 do
        local weekTaskInfo = MissionTaskRunData:create()
        weekTaskInfo:parseData(data.weekTask[i])
        self.p_weekTaskInfo[#self.p_weekTaskInfo + 1] = weekTaskInfo
    end
    self.p_sysTime = globalData.userRunData.p_serverTime / 1000
    self.p_bIsPopTip = self:isUpdateDayMissionData()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MISSION_REFRESH)
end

function MissionRunData:getLeftTime()
    if self.p_sysTime == nil then
        return 0
    end
    local times = globalData.userRunData.p_serverTime / 1000 - self.p_sysTime
    local dayTime = self.p_taskInfo.p_taskExpire - times
    local weekTime = self.p_weekTaskInfo[1].p_taskExpire - times

    if dayTime <= 0 then
        dayTime = 0
    end
    if dayTime == 0 then
        local curTs = globalData.userRunData.p_serverTime / 1000

        if self.m_queryCount < 10 and (curTs - self.m_queryCount) > 15 then
            -- if self:getNewDay() == true then
            --     return dayTime, weekTime
            -- end
            -- self:setNewDay(true)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILY_TASK_UI_CLOSE)
            gLobalSendDataManager:getNetWorkFeature():sendQueryMission()
            self.m_queryCount = self.m_queryCount + 1
            self.m_lastQueryTs = curTs
        end
    else
        self.m_queryCount = 0
    end
    return dayTime, weekTime
end

function MissionRunData:setNewDay(isNewDay)
    self.m_isNewDay = isNewDay
end

function MissionRunData:getNewDay()
    return self.m_isNewDay
end

function MissionRunData:getWeekMissionTimes()
    local strTime, isOver = util_daysdemaining(self.p_weekEnd / 1000)
    return strTime, isOver
end

function MissionRunData:checkIsFirstOpen()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local nowTb = {}
    nowTb.year = tonumber(os.date("%Y", curTime))
    nowTb.month = tonumber(os.date("%m", curTime))
    nowTb.day = tonumber(os.date("%d", curTime))
    local key = "MISSION_OPEN_" .. nowTb.year .. nowTb.month .. nowTb.day
    local curShowTime = gLobalDataManager:getNumberByField(key, 0)
    if curShowTime < 1 then
        gLobalDataManager:setNumberByField(key, 1)
        return true
    end
    return false
end

function MissionRunData:checkIsFirstTip()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local nowTb = {}
    nowTb.year = tonumber(os.date("%Y", curTime))
    nowTb.month = tonumber(os.date("%m", curTime))
    nowTb.day = tonumber(os.date("%d", curTime))
    local key = "MISSION_TIP_" .. nowTb.year .. nowTb.month .. nowTb.day
    local curShowTime = gLobalDataManager:getNumberByField(key, 0)
    if curShowTime < 1 then
        gLobalDataManager:setNumberByField(key, 1)
        return true
    end
    return false
end

function MissionRunData:isUpdateWeekMissionData()
    if self.p_weekEnd == nil then
        return false
    end
    local lastWeekEnd = tonumber(gLobalDataManager:getStringByField("lastWeekEndTime", "0"))
    if lastWeekEnd == nil then
        lastWeekEnd = 0
    end
    local nowTime = globalData.userRunData.p_serverTime or os.time() * 1000
    if lastWeekEnd > 0 then
        if nowTime > lastWeekEnd then
            gLobalDataManager:setStringByField("lastWeekEndTime", tostring(self.p_weekEnd))
            return true
        end
    elseif self.p_weekEnd ~= nil then
        gLobalDataManager:setStringByField("lastWeekEndTime", tostring(self.p_weekEnd))
    end
    return false
end

function MissionRunData:isUpdateDayMissionData()
    if self.p_taskInfo == nil or self.p_taskInfo.p_taskExpireAt == nil then
        return false
    end
    local lastDate = tonumber(gLobalDataManager:getStringByField("lastDateUpdate", "0"))
    if lastDate == nil then
        lastDate = 0
    end
    local nowDate = self.p_taskInfo.p_taskExpireAt
    if nowDate == nil then
        nowDate = 0
    end
    if lastDate ~= nowDate then
        gLobalDataManager:setStringByField("lastDateUpdate", tostring(nowDate))
        return true
    end
    return false
end

function MissionRunData:isPopTip()
    if self.p_bIsPopTip == true then
        self.p_bIsPopTip = false
        return true
    end
    return false
end

function MissionRunData:hasAdditionCount()
    if self.p_totalMissionNum and self.p_totalMissionNum == AdditionTaskId then
        return true
    end
    return false
end
--检查任务是否有可领取的包括 周任务
function MissionRunData:checkRedPointNum()
    if self.p_taskInfo.p_taskCompleted == true and self.p_taskInfo.p_taskCollected == false then
        return true
    end
    for i = 1, #self.p_weekTaskInfo, 1 do
        local weekTaskInfo = self.p_weekTaskInfo[i]
        if weekTaskInfo.p_taskCompleted == true and weekTaskInfo.p_taskCollected == false then
            return true
        end
    end
    return false
end

-- 睡眠中
function MissionRunData:isSleeping()
    if self:getLeftTime() <= 2 then
        return true
    end

    return false
end

return MissionRunData
