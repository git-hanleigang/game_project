local DailyTaskLevelEnter = class("DailyTaskLevelEnter", util_require("base.BaseView"))
local Task_State = {
    lock = "lock",
    unComplete = "idle",
    complete = "complete",
    collected = "collected"
}
local eveAddNum = 10 / 9
--增加值固定 每秒涨动30次

local MISSION_TYPE = {
    DAILY_MISSION = 1,
    SEASON_MISSION = 2
}

--toComplete
function DailyTaskLevelEnter:initUI()
    local csbName = "GameNode/GameBottomTaskNode.csb"
    local bOpenDeluxe = globalData.slotRunData.isDeluexeClub
    if bOpenDeluxe then
        csbName = "GameNode/GameBottomTaskNode_1.csb"
    end
    self:createCsbNode(csbName)
    -- self:addClick(self:findChild("btn_mission"))
    -- self:addClick(self:findChild("btn_mission_lock"))

    self.m_currMissionType = nil

    self:initProgress()
    self:initTask(true)
    self:initRefreshTimer()
end

function DailyTaskLevelEnter:onEnter()
    -- 更新进度条
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新每日任务进度条
            -- self:setTasksBarPercent(params)
            self:initTask(false)
        end,
        ViewEventType.NOTIFY_UPDATE_BAR
    )

    -- gLobalNoticManager:addObserver(self,function(Target,mailCount)
    --     self:refreshMissionTip()
    -- end, ViewEventType.NOTIFY_MISSION_REFRESH)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新每日任务进度条
            self:autoCollectMission()
        end,
        ViewEventType.NOTIFY_DAILYPASS_AUTOCOLLECT_MSG
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params) --
            self:initTask(false)
            self:refreshTimer()
        end,
        ViewEventType.NOTIFY_DAILYPASS_SEASONMISSON_REFRESH
    )

    if not gLobalDailyTaskManager:isCanShowLayer() then
        gLobalNoticManager:addObserver(
            self,
            function(target, percent)
                -- spin 过程中如果下载完毕后,需要更新状态
                self.m_curState = Task_State.unComplete
                self:initTask(false)
            end,
            "DL_Complete" .. ACTIVITY_REF.NewPass
        )
    end
end

function DailyTaskLevelEnter:onExit()
    if self.m_schdDule then
        self:stopAction(self.m_schdDule)
        self.m_schdDule = nil
    end

    -- csc 2021-07-12 设置变量为空
    gLobalDailyTaskManager:setAutoColectFlag(false)

    gLobalNoticManager:removeAllObservers(self)
end

function DailyTaskLevelEnter:initTask(isInit)
    --未解锁状态 or 当前每日任务相关资源没有下载好  csc 2021-10-23
    if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_DAILYMISSION or not gLobalDailyTaskManager:isCanShowLayer() then
        self.m_curState = Task_State.lock
        self:runCsbAction("lock")
        return
    end

    -- 得当前是需要展示每日任务进度 还是 season mission 进度
    self.m_missionData = self:getCurrMissionData()
    local newState = self:convertState(self.m_missionData)
    if not newState then
        return
    end
    if self.m_curState then
        if self.m_curState == newState then --前后一致 只更新进度
            if self.m_curState ~= Task_State.collected and self.m_curState ~= Task_State.complete then
                -- update
                self.m_playToComplete = false
                self:setTasksBarPercent(isInit)
            end
        else
            --未完成 到完成 播放变化动画
            if self.m_curState == Task_State.unComplete and newState == Task_State.complete then
                self.m_playToComplete = true
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_BOTTOM_FORCE_SWITCH, 1)
                self:setNewState(newState, isInit)
                -- csc 2021-07-12 设置变量通知当前需要进行自动收集
                gLobalDailyTaskManager:setAutoColectFlag(true)
            else
                self.m_playToComplete = false
                self:setNewState(newState, isInit)
            end
        end
    else
        self.m_playToComplete = false
        self:setNewState(newState, isInit)
    end
end

--初始化time
function DailyTaskLevelEnter:initRefreshTimer()
    --未解锁状态 or 当前每日任务相关资源没有下载好  csc 2021-10-23
    if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_DAILYMISSION or not gLobalDailyTaskManager:isCanShowLayer() then
        return
    end

    local dayTime, weekTime = self.m_missionData:getLeftTime()
    local lab_left_time = self:findChild("lbs_state3")
    local mleftTime = util_count_down_str(dayTime)
    lab_left_time:setString(mleftTime)
    -- 实时更新游戏状态
    self.m_freshSchedule =
        schedule(
        self,
        function()
            -- 距离刷新还有多少秒
            dayTime = self:getUpdateTimerData()
            if dayTime <= 0 then
                self:stopAction(self.m_freshSchedule)
                self.m_freshSchedule = nil
                performWithDelay(
                    self,
                    function()
                        self:initTask(false)
                    end,
                    3
                )
            end
            mleftTime = util_count_down_str(dayTime)
            lab_left_time:setString(mleftTime)
        end,
        1
    )
end

--设置状态
function DailyTaskLevelEnter:setNewState(state, isInit)
    self.m_curState = state
    self:setTasksBarPercent(isInit)
end

--设置进度
function DailyTaskLevelEnter:setTasksBarPercent(isInit)
    local missionData = self.m_missionData
    if self.m_curState == Task_State.unComplete then
        self:findChild("lbs_state1"):setString("SPIN!")
        if missionData.p_taskInfo.p_taskType == 1011 then
            local leftSpins = missionData.p_taskInfo.p_taskParams[2] - missionData.p_taskInfo.p_taskProcess[2]
            if missionData.p_taskInfo.p_taskId == "35" then
                self:findChild("lbs_state1"):setString(util_formatCoins(tonumber(leftSpins),3,nil,nil,nil,true))
            else
                self:findChild("lbs_state1"):setString(tostring(leftSpins))
            end
        elseif missionData.p_taskInfo.p_taskType == 2006 then
            local leftSpins = missionData.p_taskInfo.p_taskParams[3] - missionData.p_taskInfo.p_taskProcess[3]
            self:findChild("lbs_state1"):setString(tostring(leftSpins))
        end
    end

    local m_numPercent, m_endValue = missionData.p_taskInfo:getTaskSchedule()
    -- 进度条更新
    local loadingPercent = tonumber(m_numPercent)/ tonumber(m_endValue) * 100
    if loadingPercent > 100 then
        -- body
        loadingPercent = 100
    end

    if loadingPercent < 0.1 then
        loadingPercent = 0.1
    end

    if isInit then
        self.curValue = loadingPercent
        self.m_loadingProgress:setPercentage(loadingPercent)
        self:changeStateEnd()
    else
        if missionData.p_allMissionCompleted then
            self.m_loadingProgress:setPercentage(100)
            self:changeStateEnd()
        else
            if self:checkCanUpdate(loadingPercent) then
                self:addCountTimer(loadingPercent)
            else
                self:changeStateEnd()
            end
        end
    end
end
function DailyTaskLevelEnter:checkCanUpdate(loadingPercent)
    if loadingPercent == nil then
        return false
    end
    if self.m_loadingProgress:getPercentage() == loadingPercent then
        return false
    end
    if self.m_countList and #self.m_countList > 0 then
        if self.m_countList[#self.m_countList] >= loadingPercent then
            return false
        end
        for i = 1, #self.m_countList do
            if self.m_countList[i] == loadingPercent then
                return false
            end
        end
    end
    return true
end

function DailyTaskLevelEnter:showNextCount()
    if not self.m_playIng and self.m_countList and #self.m_countList > 0 then
        self.m_playIng = true
        local loadingPercent = self.m_countList[1]
        local time = (loadingPercent - self.m_loadingProgress:getPercentage()) * 2 / 100
        local actionList = {}
        actionList[#actionList + 1] = cc.ProgressTo:create(time, loadingPercent)
        actionList[#actionList + 1] =
            cc.CallFunc:create(
            function()
                if self.m_countList and #self.m_countList > 0 then
                    table.remove(self.m_countList, 1)
                end
                self.m_playIng = false
                if self and self.showNextCount then
                    self:showNextCount()
                end
            end
        )
        local seq = cc.Sequence:create(actionList)
        self.m_loadingProgress:runAction(seq)
    else
        self:changeStateEnd()
    end
end

--计时器
function DailyTaskLevelEnter:addCountTimer(loadingPercent)
    if not self.m_countList then
        self.m_countList = {}
    end
    self.m_countList[#self.m_countList + 1] = loadingPercent
    self:showNextCount()
end

--播放最终函数
function DailyTaskLevelEnter:changeStateEnd()
    if self.m_playToComplete then
        self:runCsbAction(
            "toComplete",
            false,
            function()
                self:runCsbAction(self.m_curState, true)
            end
        )
    else
        self:runCsbAction(self.m_curState, true)
    end
end

function DailyTaskLevelEnter:initProgress()
    -- 创建进度条
    local rateImg = self:findChild("jindu_tiao")
    rateImg:setVisible(false)
    local img = util_createSprite("GameNode/ui_challengeTask/2020_spin_jindu.png")
    self.m_loadingProgress = cc.ProgressTimer:create(img)
    self.m_loadingProgress:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    self.m_loadingProgress:setPercentage(0)
    -- self.m_loadingProgress:setAnchorPoint(0.5,0)
    self.m_loadingProgress:setPosition(cc.p(0, 0))
    self.m_loadingProgress:setScaleX(img:getScaleX())
    self.m_loadingProgress:setScaleY(img:getScaleY())
    self:findChild("clipping_node"):addChild(self.m_loadingProgress, 1)
end

function DailyTaskLevelEnter:convertState(missionData)
    local state = nil
    if missionData.p_allMissionCompleted == true and missionData.p_taskInfo.p_taskCollected == true then --全部完成
        state = Task_State.collected
    else
        if missionData.p_taskInfo.p_taskCompleted == true then --已经完成
            state = Task_State.complete
        else --未完成
            state = Task_State.unComplete
        end
    end
    return state
end

function DailyTaskLevelEnter:clickFunc(sender)
    -- local senderName = sender:getName()
    -- self:findChild("btn_mission"):setEnabled(false)
    -- self:findChild("btn_mission_lock"):setEnabled(false)
    -- performWithDelay(self,function()
    --     self:findChild("btn_mission"):setEnabled(true)
    --     self:findChild("btn_mission_lock"):setEnabled(true)
    -- end,0.4)
    -- if "btn_mission" == senderName then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BOTTOM_TASKCLICK,1)
    -- elseif "btn_mission_lock" == senderName then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BOTTOM_TASKCLICK,0)
    -- end
end

function DailyTaskLevelEnter:getCurrMissionData()
    -- 区分当前mission  优先级先判断每日任务
    -- local _currPageType = MISSION_TYPE.DAILY_MISSION
    local _currPageType = gLobalDailyTaskManager:checkIncreaseProgressTask()
    local missionData = globalData.missionRunData
    local newState = self:convertState(missionData)
    if _currPageType == MISSION_TYPE.SEASON_MISSION or newState == Task_State.collected then
        -- 当前mission 任务已经全部完成 判断当前是否有task 任务
        local taskData = G_GetMgr(ACTIVITY_REF.NewPass):getSeasonMission()
        if taskData and not taskData:getInCd() then
            missionData = taskData
            _currPageType = MISSION_TYPE.SEASON_MISSION
        end
    end
    if self.m_currPageType == nil or self.m_currPageType ~= _currPageType then
        self.m_currPageType = _currPageType
        self:changeIcon(_currPageType)
    end

    return missionData
end

function DailyTaskLevelEnter:getUpdateTimerData()
    local missionTime = globalData.missionRunData:getLeftTime()

    local seasonCdTime = 0
    if G_GetMgr(ACTIVITY_REF.NewPass):getSeasonMission() and G_GetMgr(ACTIVITY_REF.NewPass):getSeasonMission():getInCd() then
        seasonCdTime = G_GetMgr(ACTIVITY_REF.NewPass):getSeasonMission():getLeftTime()
    else
        seasonCdTime = missionTime
    end
    local leftTime = math.min(missionTime, seasonCdTime)
    -- print("----csc left time = "..util_count_down_str(leftTime))
    return leftTime
end

function DailyTaskLevelEnter:changeIcon(_currPageType)
    -- 切换icon
    local icon = self:findChild("sp_icon")
    if not icon then
        return
    end
    if self.m_currPageType == MISSION_TYPE.DAILY_MISSION then
        util_changeTexture(icon, "GameNode/ui_challengeTask/2020_spin_baoxiang.png")
    elseif self.m_currPageType == MISSION_TYPE.SEASON_MISSION then
        util_changeTexture(icon, "GameNode/ui_challengeTask/taskentry_season_gift.png")
    end
end

-- 自动收集接口
function DailyTaskLevelEnter:autoCollectMission()
    -- 触发的动效的时候添加遮罩层（主要是为了防止用户点击按钮）
    gLobalViewManager:addLoadingAnima(true)

    gLobalDailyTaskManager:setAutoColectFlag(false)
    -- spine 动画是横版的，竖版进行 -X 翻转
    local spinePath = DAILYPASS_RES_PATH.AUTO_COLLECT_SPINE_PATH
    self.m_autoEffect = util_spineCreate(spinePath, false, true, 1)
    local pos = self:getParent():convertToWorldSpace(cc.p(self:getPosition()))
    self.m_autoEffect:setPosition(pos)
    gLobalViewManager:getViewLayer():addChild(self.m_autoEffect, ViewZorder.ZORDER_SPECIAL)

    if globalData.slotRunData.isPortrait == true then
        self.m_autoEffect:setScaleX(1)
    else
        self.m_autoEffect:setScaleX(-1)
    end

    util_spinePlay(self.m_autoEffect, "actionframe", false)
    util_spineEndCallFunc(
        self.m_autoEffect,
        "actionframe",
        function()
            util_nextFrameFunc(
                function()
                    if self.m_autoEffect ~= nil then
                        self.m_autoEffect:removeFromParent()
                        self.m_autoEffect = nil
                    end
                end
            )
            -- 自动收集的时候需要自检
            local bl_success = gLobalDailyTaskManager:autoCollectMission()
            if not bl_success then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            end
        end
    )
    -- 定时计算删掉遮罩
    performWithDelay(
        self,
        function()
            gLobalViewManager:removeLoadingAnima()
        end,
        2
    )
end

-- 重置定时器
function DailyTaskLevelEnter:refreshTimer()
    if self.m_freshSchedule then
        self:stopAction(self.m_freshSchedule)
        self.m_freshSchedule = nil
    end
    self:initRefreshTimer()
end

return DailyTaskLevelEnter
