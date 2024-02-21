--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-02 16:34:02
    describe:新版大活动任务 管理类
]]
local ActivityTaskNewManager = class("ActivityTaskNewManager", require "network.NetWorkBase")

function ActivityTaskNewManager:ctor()
    if globalData.activityTaskNewData then
        self.m_activityTask = globalData.activityTaskNewData
    end
end

function ActivityTaskNewManager:getInstance()
    if not self._instance then
        self._instance = ActivityTaskNewManager:create()
    end
    return self._instance
end

--根据活动名字获取活动全部任务
function ActivityTaskNewManager:getTaskDataByActivityName(_activityRef)
    local taskDataList = self.m_activityTask:getTaskDataByActivityName(_activityRef)
    return taskDataList
end

--根据活动名字获取活动正在进行的任务
function ActivityTaskNewManager:getCurrentTaskByActivityName(_activityRef)
    return self.m_activityTask:getCurrentTaskByActivityName(_activityRef)
end

--根据活动名字获取活动正在进行的任务
function ActivityTaskNewManager:getLastTaskByActivityName(_activityRef)
    return self.m_activityTask:getLastTaskByActivityName(_activityRef)
end

--根据活动名字,获得需要动画任务列表
function ActivityTaskNewManager:getAniTaskList(_activityRef)
    return self.m_activityTask:getAniTaskList(_activityRef)
end

function ActivityTaskNewManager:clearAniTaskList()
    return self.m_activityTask:clearAniTaskList()
end

function ActivityTaskNewManager:getEntryProgress(_activityRef)
    return self.m_activityTask:getEntryProgress(_activityRef)
end

function ActivityTaskNewManager:checkIsFinish()
    return self.m_activityTask:checkIsFinish()
end

--大活动多主题
function ActivityTaskNewManager:getDyname(activity_taskRef)
    local activity_ref = nil
    if activity_taskRef == ACTIVITY_REF.BlastTaskNew then 
        activity_ref = ACTIVITY_REF.Blast
    end

    if activity_ref then
        local data = G_GetActivityDataByRef(activity_ref)
        if data and data:isRunning() then
            return data:getThemeName()
        end
    end

    return activity_taskRef
end

--检测是否打开任务入口
function ActivityTaskNewManager:checkTaskData(_activityRef)
    if self.m_activityTask and self.m_activityTask:checkTaskData(_activityRef) then
        local taskData = self:getCurrentTaskByActivityName(_activityRef)
        _activityRef = self:getDyname(_activityRef)
        local bDownload = false
        local mgr = G_GetMgr(_activityRef)
        if mgr then
            bDownload = mgr:isDownloadRes()
        else
            bDownload = globalDynamicDLControl:checkDownloaded(_activityRef)
        end
        if taskData and bDownload then
            return true
        end
    end
    return false
end

--检测是否有任务奖励可领取
function ActivityTaskNewManager:checkIsHasTaskReward(_activityRef)
    if _activityRef then
        local taskData = self:getTaskDataByActivityName(_activityRef)
        if taskData and self.m_activityTask:checkIsHasTaskReward(_activityRef) then
            -- 活动剩余时间少于5秒 不打开界面 (做个保护)
            if taskData:getLeftTime() > 5 then
                return true
            end
        end
    end
    return false
end

--得到可领取的任务奖励
function ActivityTaskNewManager:getTaskReward(_activityRef)
    return self.m_activityTask:getTaskReward(_activityRef)
end

--发送领取奖励信息
function ActivityTaskNewManager:requestCumulativeData(_activityRef)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    if not self:checkIsHasTaskReward(_activityRef) then
        return
    end
    local actionData = self:getSendActionData(ActionType.ActivityMissionV2Collect)
    local taskDataList = self.m_activityTask:getTaskDataByActivityName(_activityRef)
    local activityCommonType = taskDataList:getActivityCommonType()
    local stage = self.m_activityTask:getStageStr(_activityRef)

    local params = {}
    params.CommonType = activityCommonType
    params.rewardStages = stage
    actionData.data.params = json.encode(params)

    local collectSuccess = function(_target, _resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_SUCCESS)
    end
    local collectFailed = function(_target, _resData)
        gLobalViewManager:showReConnect()
    end

    self:sendMessageData(actionData, collectSuccess, collectFailed)
end

return ActivityTaskNewManager
