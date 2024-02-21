--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-06-28 12:22:29
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-06-28 15:53:01
FilePath: /SlotNirvana/src/activities/Activity_NoviceTrail/model/ActNoviceTrailData.lua
Description: 新手期三日任务 总数据
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ActNoviceTrailData = class("ActNoviceTrailData", BaseActivityData)
local ActNoviceTrailTaskData = import(".ActNoviceTrailTaskData")
local ActNoviceTrailProgRewardData = import(".ActNoviceTrailProgRewardData")
local ActNoviceTrailConfig = util_require("activities.Activity_NoviceTrail.config.ActNoviceTrailConfig")

function ActNoviceTrailData:ctor()
    ActNoviceTrailData.super.ctor(self)

    self.m_dayTaskList = {} -- 3日任务列表
    self.m_progRewardList = {} -- 进度条奖励列表
    self.m_curPoints = 0 -- 当前累计点数
    self.m_canColCountList = {0,0,0} -- 可领取的任务数量

end

function ActNoviceTrailData:parseData(_data)
    if not _data then
        return
    end
    ActNoviceTrailData.super.parseData(self, _data)

    -- 当前累计点数
    self.m_curPoints = _data.points or 0
    -- 3日任务列表
    self:parseDayTaskList(_data.tasks or {})
    -- 进度条奖励列表
    self:parseProgRewardList(_data.rewards or {})
end

-- 3日任务列表
function ActNoviceTrailData:parseDayTaskList(_list)
    local oldDailTaskList = clone(self.m_dayTaskList)
    local updateTaskData = nil
    local openDay = self:getOpenDay()

    self.m_dayTaskList = {} 
    self.m_canColCountList = {0,0,0}
    for i=1, #_list do
        local taskData = ActNoviceTrailTaskData:create(_list[i], self)
        local day = taskData:getDay()
        if not self.m_dayTaskList[day] then
            self.m_dayTaskList[day] = {}
        end
        if taskData:getStatus() == ActNoviceTrailConfig.TASK_STATUS.DONE then
            self.m_canColCountList[day] = self.m_canColCountList[day] + 1
        end
        table.insert(self.m_dayTaskList[day], taskData)

        -- 检查老任务更新情况
        if not updateTaskData and day <= openDay and oldDailTaskList[day] then
            for _, oldTaskData in ipairs(oldDailTaskList[day]) do
                if oldTaskData:getTaskId() == taskData:getTaskId() then
                    updateTaskData = self:checkUpdateTaskData(oldTaskData, taskData)
                end
            end
        end
    end

    -- 任务排序
    self:sortTaskList()

    if updateTaskData then
        -- 通知任务更新 气泡
        gLobalNoticManager:postNotification(ActNoviceTrailConfig.EVENT_NAME.NOTIFY_NOVICE_TRAIL_TASK_UPDATE, updateTaskData)
    end
    self.m_curDoneTaskData = updateTaskData -- 未完成到完成
end
-- 在线跨天解锁下一天， 并刷新任务状态
function ActNoviceTrailData:updateTaskStatus()
    self.m_canColCountList = {0,0,0}
    for _day, taskDataList in pairs(self.m_dayTaskList) do
        for _, taskData in pairs(taskDataList) do
            if taskData:getStatus() == ActNoviceTrailConfig.TASK_STATUS.DONE then
                self.m_canColCountList[_day] = self.m_canColCountList[_day] + 1
            end
        end
    end
end
-- 进度条奖励列表
function ActNoviceTrailData:parseProgRewardList(_list)
    self.m_progRewardList = {} 
    for i=1, #_list do
        local progRewardData = ActNoviceTrailProgRewardData:create(_list[i])
        table.insert(self.m_progRewardList, progRewardData)
    end
end

-- spin 更新任务数据
function ActNoviceTrailData:updateTaskList(_list)
    if type(_list) ~= "table" then
        return
    end

    local updateTaskData = nil
    local openDay = self:getOpenDay()

    for i, serverData in ipairs(_list) do
        local oldTaskData, newTaskData 
        if serverData.day and serverData.id then
            oldTaskData, newTaskData = self:updateTaskData(serverData)
        end

        -- 检查老任务更新情况
        local day = serverData.day
        if not updateTaskData and oldTaskData and newTaskData and day <= openDay then
            updateTaskData = self:checkUpdateTaskData(oldTaskData, newTaskData)
        end
    end

    if updateTaskData then
        -- 通知任务更新 气泡
        gLobalNoticManager:postNotification(ActNoviceTrailConfig.EVENT_NAME.NOTIFY_NOVICE_TRAIL_TASK_UPDATE, updateTaskData)
    end
    self.m_curDoneTaskData = updateTaskData -- 未完成到完成
    -- 任务排序
    self:sortTaskList()
end
function ActNoviceTrailData:updateTaskData(_serverData)
    local dayTaskList = self.m_dayTaskList[_serverData.day]
    if not dayTaskList then
        return
    end
    local uTaskData
    for _, taskData in pairs(dayTaskList) do
        local id = taskData:getTaskId()
        if tonumber(_serverData.id)  == id then
            uTaskData = taskData
            break
        end
    end
    if not uTaskData then
        return
    end
    local bCheckDone = false
    if uTaskData:getStatus() == ActNoviceTrailConfig.TASK_STATUS.UN_DONE then
        bCheckDone = true
    end
    local oldTaskData = clone(uTaskData)
    uTaskData:parseData(_serverData)
    if bCheckDone and uTaskData:getStatus() == ActNoviceTrailConfig.TASK_STATUS.DONE then
        self.m_canColCountList[_serverData.day] = self.m_canColCountList[_serverData.day] + 1
    end
    return oldTaskData, uTaskData
end

-- 任务排序
function ActNoviceTrailData:sortTaskList()
    for _, dayTaskList in ipairs(self.m_dayTaskList) do
        table.sort(dayTaskList, function(a, b)
            local statusA = a:getStatus()
            local statusB = b:getStatus()

            if statusA == ActNoviceTrailConfig.TASK_STATUS.DONE then
                return statusA ~= statusB
            elseif statusA == ActNoviceTrailConfig.TASK_STATUS.UN_DONE then
                if statusA == statusB then
                    local progA = a:getProg()
                    local progB = b:getProg()
                    return progA > progB
                elseif statusB ~= ActNoviceTrailConfig.TASK_STATUS.DONE then
                    return true
                end
            end

            return false
        end)
    end
end

-- 当前累计点数
function ActNoviceTrailData:getCurPoints()
    return self.m_curPoints
end
-- 3日任务列表
function ActNoviceTrailData:getDayTaskList()
    return self.m_dayTaskList
end
-- 进度条奖励列表
function ActNoviceTrailData:getProgRewardList()
    return self.m_progRewardList
end

-- 可领取的任务数量
function ActNoviceTrailData:getCanColCount(_day)
    if not _day then
        return self.m_canColCountList[1] + self.m_canColCountList[2] +self.m_canColCountList[3]
    end
    return self.m_canColCountList[_day]
end

function ActNoviceTrailData:getOpenDay()
    local days = util_leftDays(self:getExpireAt(), true)
    return math.max(3 - days, 1)
end

--获取入口位置 1：左边，0：右边
function ActNoviceTrailData:getPositionBar()
    return 1
end


---------------- 查看任务更新情况
function ActNoviceTrailData:checkUpdateTaskData(_oldTaskData, _newTaskData)
    local updateTaskData = nil
    local oldStatus = _oldTaskData:getStatus()
    local newStatus = _newTaskData:getStatus()

    -- local oldProg = _oldTaskData:getCurProg()
    -- local newProg = _newTaskData:getCurProg()

    -- -- 任务进行中 查看进度是否增加
    -- if oldStatus == ActNoviceTrailConfig.TASK_STATUS.UN_DONE and oldStatus == newStatus then
    --     if oldProg < newProg then
    --         updateTaskData = _newTaskData
    --     end
    -- elseif newStatus == ActNoviceTrailConfig.TASK_STATUS.DONE and oldStatus == ActNoviceTrailConfig.TASK_STATUS.UN_DONE then
    if newStatus == ActNoviceTrailConfig.TASK_STATUS.DONE and oldStatus == ActNoviceTrailConfig.TASK_STATUS.UN_DONE then
        -- 任务完成
        updateTaskData = _newTaskData
    end

    return updateTaskData
end

function ActNoviceTrailData:getCurSpinDoneTaskData()
    return self.m_curDoneTaskData
end
return ActNoviceTrailData