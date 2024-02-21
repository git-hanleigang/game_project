-- Created by jfwang on 2019-05-21.
-- 大厅入口
--
local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local Activity_QuestNewLobbyNode = class("Activity_QuestNewLobbyNode", BaseLobbyNodeUI)

function Activity_QuestNewLobbyNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/Activity_QuestNewLobbyNode.csb")
    self.m_curActivityId = ""
    if data and data.activityId then
        self.m_curActivityId = data.activityId
    end

    self.m_timeBg = self:findChild("timebg")
    self.m_djsLabel = self:findChild("timeValue")
    self.btn_icon = self:findChild("Button_1")
    self.m_lock = self:findChild("lock")
    self.m_unlockValue = self:findChild("unlockValue")
    self.m_sp_new = self:findChild("sp_new")
    self.m_tips_msg = self:findChild("tipsNode")
    self.m_tips_msg:setVisible(false)
    self.m_nodeSizePanel = self:findChild("node_sizePanel")
    self.m_tips_commingsoon_msg = self:findChild("tipsNode_comingsoon")
    self.m_tipsNode_downloading = self:findChild("tipsNode_downloading")
    if self.m_tips_commingsoon_msg then
        self.m_tips_commingsoon_msg:setVisible(false)
    end
    if self.m_tipsNode_downloading then
        self.m_tipsNode_downloading:setVisible(false)
    end

    self:initView()
end

--刷新界面
function Activity_QuestNewLobbyNode:initView()
    Activity_QuestNewLobbyNode.super.initView(self)
    --解锁等级
    local unLockLevel = globalData.constantData.OPENLEVEL_NEWQUEST or 30
    self.m_unlockValue:setString(unLockLevel)

    local bl_showNew = self:getCanShowNewIcon()
    self.m_sp_new:setVisible(bl_showNew)

    if not G_GetMgr(ACTIVITY_REF.QuestNew):isRunning() then
        self.m_timeBg:setVisible(false)
        self.m_lock:setVisible(true)
        self:updateDownLoad(false)
    else
        self.m_lock:setVisible(false)
        self:updateDownLoad(true)
        self:showDownTimer()
    end
end

-- 是否等级锁
function Activity_QuestNewLobbyNode:isLevelLock()
    if G_GetMgr(ACTIVITY_REF.QuestNew):isNewUserQuestCompleted() then
        return false
    end

    local unLockLevel = globalData.constantData.OPENLEVEL_NEWQUEST or 30
    local curLevel = globalData.userRunData.levelNum
    if curLevel < unLockLevel then
        return true
    else
        return false
    end
end

function Activity_QuestNewLobbyNode:getCanShowNewIcon()
    local questMgr = G_GetMgr(ACTIVITY_REF.QuestNew)
    if not questMgr then
        return false
    end

    local questConfig = questMgr:getRunningData()
    if not questConfig or questConfig:getLeftTime() <= 0 then
        return false
    end

    local bl_download = questMgr:isDownloadRes()
    local newCount = gLobalDataManager:getNumberByField("Activity_QuestNew_New", 0)
    if not bl_download or newCount >= 3 then
        return false
    end

    return true
end

--显示倒计时
function Activity_QuestNewLobbyNode:showDownTimer()
    local questConfig = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    if not questConfig or questConfig:getLeftTime() <= 0 then
        self:showCommingSoon()
        return
    end

    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function Activity_QuestNewLobbyNode:updateLeftTime()
    local questConfig = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    local expireTime = nil

    if questConfig then
        expireTime = questConfig:getLeftTime()
    end

    if not expireTime or expireTime <= 0 then
        --活动结束，关闭入口
        if self.closeLobbyNode then
            self:closeLobbyNode()
        end
        self:stopTimerAction()
        local bl_showNew = self:getCanShowNewIcon()
        self.m_sp_new:setVisible(bl_showNew)
    else
        --活动剩余24小时，请求刷新数据
        local questConfig = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
        if questConfig and questConfig.p_questExtraPrize and expireTime == questConfig.p_questExtraPrize then
            if self.onUpdateActivityStart then
                self:onUpdateActivityStart()
            end
        end
        if self.m_djsLabel and self.m_djsLabel.setString then
            self.m_djsLabel:setString(util_daysdemaining1(expireTime))
        end
    end
end

function Activity_QuestNewLobbyNode:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

--点击了活动node
function Activity_QuestNewLobbyNode:onClickLobbyNode()
    local isLock = false
    if self.m_commingSoon then
        self:showTips(self.m_tips_commingsoon_msg)
        isLock = true
    end

    -- if self.m_LockState then
    if self:isLevelLock() then
        self:showTips(self.m_tips_msg)
        isLock = true
    end

    if not G_GetMgr(ACTIVITY_REF.QuestNew):isDownloadRes() then
        self:showTips(self.m_tipsNode_downloading)
        isLock = true
    end

    if isLock then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        return
    end

    --打点
    gLobalSendDataManager:getLogQuestNewActivity():sendQuestEntrySite("lobbyActivityIcon")
    --打开quest活动主界面

    G_GetMgr(ACTIVITY_REF.QuestNew):showMainLayer()
    self:openLayerSuccess()
end

function Activity_QuestNewLobbyNode:onUpdateActivityStart()
    --请求更新难度数据
    if not self.m_isRequest then
        self.m_isRequest = true
        performWithDelay(
            self,
            function()
                gLobalSendDataManager:getNetWorkFeature():sendActivityConfig()
            end,
            2
        )
    end
end

function Activity_QuestNewLobbyNode:onUpdateActivityEnd()
    gLobalNoticManager:postNotification(ViewEventType.UPDATE_SLIDEANDHALL_FINISH)
end

function Activity_QuestNewLobbyNode:onEnter()
    BaseLobbyNodeUI.onEnter(self)
    --更新活动配置成功
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:onUpdateActivityEnd()
        end,
        ViewEventType.UPDATE_ACTIVITY_CONFIG_FINISH
    )
end

function Activity_QuestNewLobbyNode:onExit()
    BaseLobbyNodeUI.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

    if self.m_schduleCheckActivityLobbyID then
        scheduler.unscheduleGlobal(self.m_schduleCheckActivityLobbyID)
        self.m_schduleCheckActivityLobbyID = nil
    end
end

function Activity_QuestNewLobbyNode:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        self:onClickLobbyNode()
    end
end

function Activity_QuestNewLobbyNode:showCommingSoon()
    self.m_commingSoon = true
    self.m_tips_msg:setVisible(false)
    self.m_tips_commingsoon_msg:setVisible(false)
    self.m_lock:setVisible(true)
    self.m_timeBg:setVisible(false)
    self:findChild("name"):setString("COMING SOON")
    self:updateDownLoad(false)
end

function Activity_QuestNewLobbyNode:getThemeName()
    local themeName = ""
    local config = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    if config then
        themeName = config:getThemeName()
    end
    return themeName
end

function Activity_QuestNewLobbyNode:getDownLoadKey()
    --主题下载过了 只有系统需要更新
    if G_GetMgr(ACTIVITY_REF.QuestNew):isOnlyDownloadingBase() then
        return "Activity_QuestNewBase"
    end
    local config = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.QuestNew, ACTIVITY_TYPE.COMMON)
    if config then
        return config:getThemeName()
    end

    return ""
end

function Activity_QuestNewLobbyNode:getProgressPath()
    local themeName = self:getThemeName()
    return "Activity_LobbyIconRes/ui/QuestNew.png"
end

function Activity_QuestNewLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_QuestNewLobbyNode:getBottomName()
    return "QUEST"
end

--下载结束回调
function Activity_QuestNewLobbyNode:endProcessFunc()
    local bl_showNew = self:getCanShowNewIcon()
    self.m_sp_new:setVisible(bl_showNew)

    G_GetMgr(ACTIVITY_REF.QuestNew):checkUpdateConfig(self:getDownLoadKey())
end

-- 获取活动引用名
function Activity_QuestNewLobbyNode:getActRefName()
    return ACTIVITY_REF.QuestNew
end

return Activity_QuestNewLobbyNode
