-- Created by jfwang on 2019-05-21.
-- 大厅入口
--
local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local Activity_QuestLobbyNode = class("Activity_QuestLobbyNode", BaseLobbyNodeUI)

local res_config = {
    -- 常规主题
    Activity_QuestIsland = {
        common_icon = "Activity_LobbyIconRes/ui/Quest_Island_Logo.png",
        pressed_icon = "Activity_LobbyIconRes/ui/Quest_Island_Logo2.png"
    }
}

function Activity_QuestLobbyNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/Activity_QuestLobbyNode.csb")
    if G_GetMgr(ACTIVITY_REF.Quest):checkQuestUlkLobbyBtmGuide() then
        G_GetMgr(ACTIVITY_REF.Quest):setLobbyBtmQuestUI(self)
    end
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
function Activity_QuestLobbyNode:initView()
    Activity_QuestLobbyNode.super.initView(self)

    local themeName = self:getThemeName()
    local theme_res = res_config[themeName]
    if theme_res then
        self.btn_icon:loadTextureNormal(theme_res.common_icon, UI_TEX_TYPE_LOCAL)
        self.btn_icon:loadTexturePressed(theme_res.pressed_icon, UI_TEX_TYPE_LOCAL)
        self.btn_icon:loadTextureDisabled(theme_res.pressed_icon, UI_TEX_TYPE_LOCAL)
        local size = self.btn_icon:getNormalTextureSize()
        self.btn_icon:setContentSize(size)
        self.m_lockIocn:setTexture(theme_res.common_icon)
    end

    local bl_showNew = self:getCanShowNewIcon()
    self.m_sp_new:setVisible(bl_showNew)

    if not G_GetMgr(ACTIVITY_REF.Quest):isRunning() then
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
function Activity_QuestLobbyNode:isLevelLock()
    if G_GetMgr(ACTIVITY_REF.Quest):isNewUserQuestCompleted() then
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

function Activity_QuestLobbyNode:getCanShowNewIcon()
    local questMgr = G_GetMgr(ACTIVITY_REF.Quest)
    if not questMgr then
        return false
    end

    local questConfig = questMgr:getRunningData()
    if not questConfig or questConfig:getLeftTime() <= 0 then
        return false
    end

    local bl_download = questMgr:isDownloadRes()
    local newCount = gLobalDataManager:getNumberByField("Activity_Quest_New", 0)
    if not bl_download or newCount >= 3 then
        return false
    end

    return true
end

--显示倒计时
function Activity_QuestLobbyNode:showDownTimer()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not questConfig or questConfig:getLeftTime() <= 0 then
        self:showCommingSoon()
        return
    end

    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function Activity_QuestLobbyNode:updateLeftTime()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
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
        local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if questConfig and questConfig.p_questExtraPrize and expireTime == questConfig.p_questExtraPrize then
            if self.onUpdateActivityStart then
                self:onUpdateActivityStart()
            end
        end
        if self.m_djsLabel and self.m_djsLabel.setString then
            self.m_djsLabel:setString(util_daysdemaining1(expireTime))
        end
        self.m_lock:setVisible(false)
        self.m_timeBg:setVisible(true)
    end
end

function Activity_QuestLobbyNode:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
    self.m_timeBg:setVisible(false)
    self.m_lock:setVisible(true) -- 锁定icon
end

--点击了活动node
function Activity_QuestLobbyNode:onClickLobbyNode()
    local openLv = self:getSysOpenLv()
    -- 服务器端的定义 开启等级大于这个等级表明当前处于新手quest刚刚结束阶段 显示文本策划重定义了
    if openLv >= 25000 then
        self:showTips(self.m_tips_msg)
        local str = self:getDefaultUnlockDesc()
        self.m_unlockValue:setString(str)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        return
    end

    local isLock = false
    if self.m_commingSoon then
        self:showTips(self.m_tips_commingsoon_msg)
        isLock = true
    end

    -- if self.m_LockState then
    if self:isLevelLock() then
        self:showTips(self.m_tips_msg)
        local act_data = G_GetMgr(ACTIVITY_REF.Quest):getData()
        local str = self:getDefaultUnlockDesc()
        self.m_unlockValue:setString(str)
        isLock = true
    end

    if not G_GetMgr(ACTIVITY_REF.Quest):isDownloadRes() then
        self:showTips(self.m_tipsNode_downloading)
        isLock = true
    end

    if isLock then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        return
    end

    --打点
    gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("lobbyActivityIcon")
    --打开quest活动主界面

    G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
    self:openLayerSuccess()
end

function Activity_QuestLobbyNode:onUpdateActivityStart()
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

function Activity_QuestLobbyNode:onUpdateActivityEnd()
    gLobalNoticManager:postNotification(ViewEventType.UPDATE_SLIDEANDHALL_FINISH)
end

function Activity_QuestLobbyNode:onEnter()
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

function Activity_QuestLobbyNode:onExit()
    BaseLobbyNodeUI.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

    if self.m_schduleCheckActivityLobbyID then
        scheduler.unscheduleGlobal(self.m_schduleCheckActivityLobbyID)
        self.m_schduleCheckActivityLobbyID = nil
    end
end

function Activity_QuestLobbyNode:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        self:onClickLobbyNode()
    end
end

function Activity_QuestLobbyNode:showCommingSoon()
    self.m_commingSoon = true
    self.m_tips_msg:setVisible(false)
    self.m_tips_commingsoon_msg:setVisible(false)
    self.m_lock:setVisible(true)
    self.m_timeBg:setVisible(false)
    self:findChild("name"):setString("COMING SOON")
    self:updateDownLoad(false)
end

function Activity_QuestLobbyNode:getThemeName()
    local themeName = ""
    local config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if config then
        themeName = config:getThemeName()
    end
    return themeName
end

function Activity_QuestLobbyNode:getDownLoadKey()
    --主题下载过了 只有系统需要更新
    if G_GetMgr(ACTIVITY_REF.Quest):isOnlyDownloadingBase() then
        return "Activity_QuestBase"
    end
    local config = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.Quest, ACTIVITY_TYPE.COMMON)
    if config then
        return config:getThemeName()
    end

    return ""
end

function Activity_QuestLobbyNode:getProgressPath()
    local themeName = self:getThemeName()
    local theme_res = res_config[themeName]
    if theme_res then
        return theme_res.common_icon
    end
    return "Activity_LobbyIconRes/ui/QuestLink_dating.png"
end

function Activity_QuestLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_QuestLobbyNode:getBottomName()
    return "QUEST"
end

--下载结束回调
function Activity_QuestLobbyNode:endProcessFunc()
    local bl_showNew = self:getCanShowNewIcon()
    self.m_sp_new:setVisible(bl_showNew)

    G_GetMgr(ACTIVITY_REF.Quest):checkUpdateConfig(self:getDownLoadKey())
end

-- 获取活动引用名
function Activity_QuestLobbyNode:getActRefName()
    return ACTIVITY_REF.Quest
end

-- 获取默认的解锁文本
function Activity_QuestLobbyNode:getDefaultUnlockDesc()
    local openLv = self:getSysOpenLv()
    -- 服务器端的定义 开启等级大于这个等级表明当前处于新手quest刚刚结束阶段 显示文本策划重定义了
    if openLv >= 25000 then
        return "COMPLETE NOVICE ALBUM TO UNLOCK"
    end
    return "UNLOCK QUEST AT LEVEL " .. self:getSysOpenLv()
end

function Activity_QuestLobbyNode:getSysOpenLv()
    local lv = Activity_QuestLobbyNode.super.getSysOpenLv(self)
    local refName = self:getActRefName()
    if not refName then
        return lv
    end

    local actConfig = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.Quest)
    if actConfig and actConfig.p_openLevel then
        lv = actConfig.p_openLevel
    end

    return lv
end

return Activity_QuestLobbyNode
