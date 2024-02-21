--新手任务管理类
local NewbieTaskManager = class("NewbieTaskManager")
local NewbieTaskData = util_require("views.newbieTask.NewbieTaskData")

NewbieTaskManager.m_instance = nil
NewbieTaskManager.m_currentTaskList = nil --当前任务
NewbieTaskManager.m_newbieIndex = nil --进度 -1 结束
NewbieTaskManager.m_serverData = nil

function NewbieTaskManager:getInstance()
    if NewbieTaskManager.m_instance == nil then
        NewbieTaskManager.m_instance = NewbieTaskManager.new()
    end
    return NewbieTaskManager.m_instance
end

-- 构造函数
function NewbieTaskManager:ctor()
    self.m_currentTaskList = {} --当前任务
    self.m_newbieIndex = nil --是否已经开启
    self.m_serverData = nil --服务器存储数据
end

function NewbieTaskManager:parseNewbieData(content)
    self.m_currentTaskList = {} --当前任务
    for key, var in ipairs(content) do
        if var and tonumber(var[1]) then
            local data = NewbieTaskData:create()
            data:parseData(var)
            self.m_currentTaskList[key] = data
        end
    end
end

function NewbieTaskManager:initServerData(extraData)
    local path = nil
    -- if globalData.GameConfig:checkNewUserCoins() then
    path = "Csv/newbieTaskData.csv"
    -- else
    --     path = "Csv/newbieTaskDataB.csv"
    -- end
    local content = gLobalResManager:parseCsvDataByName(path)
    self:parseNewbieData(content)

    if extraData and extraData.index then
        self.m_newbieIndex = extraData.index
        self.m_serverData = extraData.taskData
        if self.m_newbieIndex ~= -1 then
            self:readServerData()
        end
    else
        if globalNoviceGuideManager:isNoobUsera() then
            self.m_newbieIndex = 1
            self:changeTaskData()
        else
            self.m_newbieIndex = -1
        end
    end

    -- 有新版 用新版任务数据
    local sysNoviceTaskMgr = G_GetMgr(G_REF.SysNoviceTask)
    if sysNoviceTaskMgr and sysNoviceTaskMgr:checkEnabled() then
        self.m_newbieIndex = -1
    end
end

--读取服务器数据
function NewbieTaskManager:readServerData()
    local newTaskData = self:getCurrentTaskData()
    if newTaskData then
        newTaskData:readServerData()
    end
end

--改变任务信息
function NewbieTaskManager:changeTaskData()
    local newTaskData = self.m_currentTaskList[self.m_newbieIndex]
    if newTaskData then
        newTaskData:changeServerData()
    end
end

--获得当前正在执行的任务
function NewbieTaskManager:getCurrentTaskData()
    if self.m_newbieIndex == -1 then
        return nil
    end
    if self.m_newbieIndex > #self.m_currentTaskList then
        self.m_newbieIndex = -1
        return nil
    end
    return self.m_currentTaskList[self.m_newbieIndex]
end

--检测是否是最后一个任务,是否已经完成，是否为升级任务
function NewbieTaskManager:checkOverTask()
    local taskData = self:getCurrentTaskData()
    if taskData and taskData:checkUnclaimed() and taskData.p_targetType == NewbieTaskType.reach_level then
        if self.m_newbieIndex >= #self.m_currentTaskList then
            return true
        end
    end
    return false
end
--获取任务进度
function NewbieTaskManager:getServerData(id)
    -- return self.m_serverData[id]
    return self.m_serverData
end
--保存任务进度
function NewbieTaskManager:setServerData(id, data)
    -- self.m_serverData[id] = data
    self.m_serverData = data
end

--type类型NewbieTaskType pool增加进度  levelName关卡 rewardValue赢钱倍数
function NewbieTaskManager:increasePool(type, pool, levelName, awardValue)
    if self.m_newbieIndex == -1 then
        return
    end
    local taskData = self.m_currentTaskList[self.m_newbieIndex]
    if taskData then
        taskData:increasePool(type, pool, levelName, awardValue)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWBIE_TASK_UPDATE, taskData:getPercent())
    end
end

--完成任务弹特效
function NewbieTaskManager:completeTask(gameEffFunc)
    if gameEffFunc then
        gameEffFunc()
    end
    local taskData = self.m_currentTaskList[self.m_newbieIndex]
    if not taskData then
        taskData = self.m_currentTaskList[#self.m_currentTaskList]
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWBIE_TASK_REWARD)
    -- gLobalSendDataManager:getLogFeature():sendNewTask(taskData.p_id, taskData.p_rewardCoins)
end

--成功完成任务刷新界面
function NewbieTaskManager:recvRewardCoins(func)
    local taskData = self.m_currentTaskList[self.m_newbieIndex]
    if taskData then
        taskData:doComplete()
        self.m_serverData = nil
        self.m_newbieIndex = self.m_newbieIndex + 1
        if self.m_newbieIndex > #self.m_currentTaskList then
            self.m_newbieIndex = -1
        else
            self:changeTaskData()
        end
    end
    globalNewbieTaskManager:upLoadTaskData(
        taskData.p_rewardCoins,
        function()
            globalData.userRunData:setCoins(globalData.userRunData.coinNum + taskData.p_rewardCoins)
            -- 引导打点：新手任务-1.任务触发
            local __taskData = globalNewbieTaskManager:getCurrentTaskData()
            if __taskData then
                gLobalSendDataManager:getLogGuide():setGuideParams(
                    2,
                    {
                        guideId = NOVICEGUIDE_ORDER.noobTaskStart1.id,
                        isForce = NOVICEGUIDE_ORDER.noobTaskStart1.force,
                        isRepeat = NOVICEGUIDE_ORDER.noobTaskStart1.repetition,
                        taskId = __taskData and __taskData.p_id
                    }
                )
                gLobalSendDataManager:getLogGuide():sendGuideLog(2, 1)
            end
            if func then
                func()
            end
        end,
        function()
            gLobalViewManager:showReConnect()
        end
    )
end

--更新任务进度 或领取奖励
function NewbieTaskManager:upLoadTaskData(rewardCoin, funcOk, funcFail)
    local extraData = {}
    extraData.taskData = self.m_serverData
    extraData.index = self.m_newbieIndex
    if rewardCoin and rewardCoin > 0 then
        gLobalSendDataManager:getNetWorkFeature():sendNewbieTaskReward(extraData, funcOk, funcFail)
    else
        gLobalSendDataManager:getNetWorkFeature():sendNewbieTaskUpdate(extraData)
    end
end

--根据不同关卡修改位置
function NewbieTaskManager:changeNodePos(node, moduleName)
    local bangHeight = 0
    if globalData.slotRunData.isPortrait == false then
        bangHeight = util_getBangScreenHeight()
    end

    local xPos = 80 + bangHeight
    if device.platform == "mac" or device.platform == "ios" then
        node:setScale(0.8)
        xPos = xPos * 0.85
    end
    if globalData.slotRunData.isPortrait == true then
        node:setPosition(xPos, display.cy)
    else
        node:setPosition(xPos, display.cy - 35)
    end
end

function NewbieTaskManager:getRewardId(index)
    if index == -1 then
        local count = #self.m_currentTaskList
        return "newUserTask" .. count
    else
        return "newUserTask" .. (index - 1) --当前进行的任务减1
    end
end

return NewbieTaskManager
