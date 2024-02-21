--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2020-12-22 16:34:05
]]
--fixNewIos
local ActivityTaskManager = class("ActivityTaskManager", require "network.NetWorkBase")

function ActivityTaskManager:ctor()
    if globalData.activityTaskData then
        self.m_activityTask = globalData.activityTaskData
        self.m_isOpenBubble = false -- 是否自动打开过气泡
        self.m_isRefresh = false -- 是否刷新过阶段
    end
end

function ActivityTaskManager:getInstance()
    if not self._instance then
        self._instance = ActivityTaskManager:create()
    end
    return self._instance
end
--根据活动名字获取活动全部任务
function ActivityTaskManager:getTaskListByActivityName(_activityRef)
    local taskDataList = self.m_activityTask:getTaskListByActivityName(_activityRef)
    return taskDataList
end
--根据活动名字获取活动正在进行的任务
function ActivityTaskManager:getCurrentTaskByActivityName(_activityRef)
    return self.m_activityTask:getCurrentTaskByActivityName(_activityRef)
end
--根据活动名字,当前任务获取下个要开启的任务
function ActivityTaskManager:getNextTaskByNameAndTask(_activityRef, _taskData)
    return self.m_activityTask:getNextTaskByNameAndTask(_activityRef, _taskData)
end

function ActivityTaskManager:getDyname(activity_taskRef)
    local activity_ref = nil
    if activity_taskRef == ACTIVITY_REF.BlastTask then
        activity_ref = ACTIVITY_REF.Blast
    elseif activity_taskRef == ACTIVITY_REF.RedecorTask then
        activity_ref = ACTIVITY_REF.Redecor
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
function ActivityTaskManager:checkTaskData(_activityRef)
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

--检测是否完成当前任务
function ActivityTaskManager:checkTaskCompleted(_activityRef)
    if _activityRef then
        local taskData = self:getCurrentTaskByActivityName(_activityRef)
        if taskData and taskData:getCompleted() and not taskData:getReward() then
            -- 活动剩余时间少于5秒 不打开界面 (做个保护)
            if taskData:getLeftTime() > 5 then
                return true
            end
        end
    end
    return false
end
--打开推币机任务界面
-- function ActivityTaskManager:openCoinPusherTaskView(_params)
--     if gLobalViewManager:getViewByExtendData("CoinPusherTaskMainLayer") == nil then
--         local CoinPusherTaskMainLayer = util_createFindView("Activity/CoinPusherTask/CoinPusherTaskMainLayer", _params)
--         if CoinPusherTaskMainLayer ~= nil then
--             gLobalViewManager:showUI(CoinPusherTaskMainLayer, ViewZorder.ZORDER_UI)
--         end
--     end
-- end
--打开bingo任务界面
function ActivityTaskManager:openBingoTaskView()
    if gLobalViewManager:getViewByExtendData("BingoTaskMainLayer") == nil then
        local BingoTaskMainLayer = util_createFindView("Activity/BingoTaskMainLayer")
        if BingoTaskMainLayer ~= nil then
            gLobalViewManager:showUI(BingoTaskMainLayer, ViewZorder.ZORDER_UI)
        end
    end
end

--打开blast任务界面
-- function ActivityTaskManager:openBlastTaskView()
--     if gLobalViewManager:getViewByExtendData("BlastTaskMainLayer") == nil then
--         local BlastTaskMainLayer = util_createFindView("Activity/BlastTaskMainLayer")
--         if BlastTaskMainLayer ~= nil then
--             gLobalViewManager:showUI(BlastTaskMainLayer, ViewZorder.ZORDER_UI)
--         end
--     end
-- end

--打开word任务界面
-- function ActivityTaskManager:openWordTaskView()
--     G_GetMgr(ACTIVITY_REF.WordTask):showMainLayer()
-- end
--打开大富翁任务界面
-- function ActivityTaskManager:openRichManTaskView()
--     if gLobalViewManager:getViewByExtendData("RichManTaskMainLayer") == nil then
--         local RichManTaskMainLayer = util_createFindView("Activity/RichManTaskMainLayer")
--         if RichManTaskMainLayer ~= nil then
--             gLobalViewManager:showUI(RichManTaskMainLayer, ViewZorder.ZORDER_UI)
--         end
--     end
-- end
--打开装修任务界面
-- function ActivityTaskManager:openRedecorTaskView(_isResumeCor)
--     if gLobalViewManager:getViewByExtendData("RedecorTaskMainLayer") == nil then
--         local ui = util_createFindView("Activity/RedecorTaskMainLayer", _isResumeCor)
--         if ui ~= nil then
--             gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
--         end
--     end
-- end
--打开DiningRoom任务界面
function ActivityTaskManager:openDiningRoomTaskView()
    if gLobalViewManager:getViewByExtendData("DiningRoomTaskMainLayer") == nil then
        local DiningRoomTaskMainLayer = util_createFindView("Activity/DiningRoomTaskMainLayer")
        if DiningRoomTaskMainLayer ~= nil then
            gLobalViewManager:showUI(DiningRoomTaskMainLayer, ViewZorder.ZORDER_UI)
        end
    end
end
--发送领取奖励信息
function ActivityTaskManager:requestCumulativeData(_activityCommonType, _activityTaskPhase)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionData = self:getSendActionData(ActionType.ActivityMissionReward)

    local params = {}
    params.CommonType = _activityCommonType
    params.phase = _activityTaskPhase
    actionData.data.params = json.encode(params)

    local collectSuccess = function(_target, _resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_SUCCESS)
    end
    local collectFailed = function(_target, _resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_FAILED)
    end

    self:sendMessageData(actionData, collectSuccess, collectFailed)
end
--刷新阶段数据
function ActivityTaskManager:refreshTaskData()
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima()
    local udid = globalData.userRunData.userUdid
    local queryTaskReq = GameProto_pb.FeaturesResultRequest()
    queryTaskReq.udid = udid
    queryTaskReq.activity = "ActivityMission"

    -- local bodyData = queryTaskReq:SerializeToString()
    -- local httpSender = xcyy.HttpSender:createSender()
    local url = DATA_SEND_URL .. RUI_INFO.QUERY_ACTIVITY_TASK -- 拼接url 地址
    local featuresData = BaseProto_pb.FeaturesData()

    local success_call_fun = function(featuresData)
        gLobalViewManager:removeLoadingAnima()
        -- local featuresData = BaseProto_pb.FeaturesData()
        -- local responseStr = self:parseResponseData(responseTable)
        -- featuresData:ParseFromString(responseStr)

        -- 活动任务
        if featuresData.activityMissions ~= nil and #featuresData.activityMissions > 0 then
            globalData.activityTaskData:parseTaskData(featuresData.activityMissions)
        end
        -- httpSender:release()
    end

    local faild_call_fun = function(errorCode, errorData)
        -- httpSender:release()
        gLobalViewManager:showReConnect()
    end

    -- local offset = self:getOffsetValue()
    -- local token = globalData.userRunData.loginUserData.token
    -- local serverTime = globalData.userRunData.p_serverTime
    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, queryTaskReq, featuresData, success_call_fun, faild_call_fun)
end

function ActivityTaskManager:setOpenBubbleFlag(_flag)
    self.m_isOpenBubble = _flag
end
function ActivityTaskManager:getOpenBubbleFlag()
    return self.m_isOpenBubble
end
function ActivityTaskManager:setRefreshFlag(_flag)
    self.m_isRefresh = _flag
end
function ActivityTaskManager:getRefreshFlag()
    return self.m_isRefresh
end

return ActivityTaskManager
