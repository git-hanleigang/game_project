local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_DailyMissionNode = class("LobbyBottom_DailyMissionNode", BaseLobbyNodeUI)

-- 节点特殊ui 配置相关 --
function LobbyBottom_DailyMissionNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/LobbyBottomDailyMissionNode.csb")

    self:initView()

    -- 特殊组件
    self.m_label_mission_num = self:findChild("label_mission_num")
    self.m_sprite_mission_tip = self:findChild("sprite_mission_tip")

    self:initMission()
    self:refreshMissionTip()
    self:initTasksLeftTimes()
end

-- function LobbyBottom_DailyMissionNode:initView( )

-- end

function LobbyBottom_DailyMissionNode:updateView()
    -- 单纯重写 防止父类调用
    self.m_lockIocn:setVisible(false)
    self.m_lock:setVisible(false)
    self.m_sp_new:setVisible(false)
    self.m_timeBg:setVisible(false)
    self.m_tipsNode_downloading = self:findChild("tipsNode_downloading")
end

function LobbyBottom_DailyMissionNode:getBottomName()
    return "MISSION"
end

function LobbyBottom_DailyMissionNode:getDownLoadKey()
    local key = nil
    local newPassMgr = G_GetMgr(ACTIVITY_REF.NewPass)
    local actData = newPassMgr:getRunningData()
    if actData and actData:isNewUserPass() then
        key = "Activity_NewPass_New"
    elseif actData then
        key = newPassMgr:getThemeName()
    end
    return key
end

function LobbyBottom_DailyMissionNode:getProgressPath()
    return "Activity_LobbyIconRes/lobbyNode/map_btn_dailybonus_up.png"
end

function LobbyBottom_DailyMissionNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function LobbyBottom_DailyMissionNode:endProcessFunc()
    self:initMission()
end

function LobbyBottom_DailyMissionNode:initMission()
    -- csc 2021-10-23  未解锁状态 显示锁 ，or 当前每日任务相关资源没有下载好 显示loading
    if not self:isOpenByLevel() then
        self.m_lock:setVisible(true)
        self.m_timeBg:setVisible(false)
        self:updateDownLoad(false)
    elseif not gLobalDailyTaskManager:isCanShowLayer() then
        self.m_timeBg:setVisible(false)
        self:updateDownLoad(true)
    else
        self.m_timeBg:setVisible(true)
        self.m_lock:setVisible(false)
        self:updateDownLoad(true)
    end
end

function LobbyBottom_DailyMissionNode:refreshMissionTip()
    local count = 0
    if self:isOpenByLevel() then
        -- local totalNum = globalData.missionRunData.p_totalMissionNum or 0
        -- local curNum = globalData.missionRunData.p_currMissionID or 0
        -- count = totalNum - curNum + 1
        -- local taskInfo = globalData.missionRunData.p_taskInfo
        -- if totalNum == curNum and taskInfo and taskInfo.p_taskCompleted and taskInfo.p_taskCollected then
        --     count = 0
        -- end
        -- 新的大厅个数判断
        count = gLobalDailyTaskManager:getLobbyBottomNum()
    end
    local ct = 0
    if G_GetMgr(G_REF.Flower) then
        ct = G_GetMgr(G_REF.Flower):getFlowerData()
    end
    count = count + ct
    if count <= 0 then
        self.m_label_mission_num:setVisible(false)
        self.m_sprite_mission_tip:setVisible(false)
    else
        self.m_label_mission_num:setVisible(true)
        self.m_sprite_mission_tip:setVisible(true)
        self.m_label_mission_num:setString(tostring(count))
        util_scaleCoinLabGameLayerFromBgWidth(self.m_label_mission_num, 26)
    end
end

function LobbyBottom_DailyMissionNode:initTasksLeftTimes()
    self.m_isFinish = false
    self.m_daily_mission_text = self.m_djsLabel
    self.m_daily_mission_finished = self:findChild("daily_mission_finished")
    self.m_daily_mission_finished:setVisible(false)

    self:updateTaskBar()

    if self.m_isFinish == true then
        return
    end

    self:showDownTimer()
end

function LobbyBottom_DailyMissionNode:updateTaskBar()
    if globalData.tasksDailyData then
        local finishNum = 0

        if globalData.tasksDailyData["TasksOne"] == 3 then
            finishNum = finishNum + 1
        end
        if globalData.tasksDailyData["TasksTwo"] == 3 then
            finishNum = finishNum + 1
        end
        if globalData.tasksDailyData["TasksThree"] == 3 then
            finishNum = finishNum + 1
        end
        if finishNum >= 3 then
            self.m_isFinish = true
        end
    end
    if self.m_isFinish == true then
        self:stopTimerAction()
        self.m_daily_mission_text:setVisible(false)
        self.m_daily_mission_finished:setVisible(true)
    end
end

-- 节点特殊处理逻辑 --
function LobbyBottom_DailyMissionNode:clickLobbyNode()
    --
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- csc 2021-10-23  未解锁状态 or 当前每日任务相关资源没有下载好  不允许打开
    if not self:isOpenByLevel() then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_unlockValue:setString(globalData.constantData.OPENLEVEL_DAILYMISSION)
        self:showTips(self.m_tips_msg)
        return
    end

    if not gLobalDailyTaskManager:isCanShowLayer() then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    if globalData.missionRunData:isSleeping() then
        --剩余时间小于两秒不让进了
        return
    end

    if globalPlatformManager.sendFireBaseLogDirect then
        globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.click_DailyQuest)
    end
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "downDailyMissionIcon")

    gLobalDailyTaskManager:createDailyMissionPassMainLayer()
    self:openLayerSuccess()

    -- 发送点击事件 关闭merge node 节点
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MISSION_MERGE_NODE_CLICK)
end

function LobbyBottom_DailyMissionNode:getGameData()
    -- 这是不需要活动数据的关卡 直接返回nil
    return nil
end

function LobbyBottom_DailyMissionNode:updateLeftTime()
    local leftTime = globalData.missionRunData:getLeftTime()
    self:updateLabelSize({label = self.m_daily_mission_text}, 85)
    self.m_daily_mission_text:setString(util_count_down_str(leftTime))
end

-- onEnter
function LobbyBottom_DailyMissionNode:onEnter()
    BaseLobbyNodeUI.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(Target, mailCount)
            self:refreshMissionTip()
        end,
        ViewEventType.NOTIFY_MISSION_REFRESH
    )

    -- 更新进度条
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新每日任务进度条
            self:updateTaskBar()
        end,
        ViewEventType.NOTIFY_UPDATE_BAR
    )
end

-- function LobbyBottom_DailyMissionNode:onExit()
--     BaseLobbyNodeUI.onExit(self)
-- end

function LobbyBottom_DailyMissionNode:isOpenByLevel()
    local open = false
    if globalData.userRunData.levelNum >= globalData.constantData.OPENLEVEL_DAILYMISSION then
        open = true
    end
    return open
end

return LobbyBottom_DailyMissionNode
