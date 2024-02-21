--
-- quest 管理
--
--quest地图节点坐标
GD.QUEST_MAPCELL_LIST = {}
--qeust地图虚线坐标
GD.QUEST_MAPLINE_LIST = {}
--quest地图宝箱坐标
GD.QUEST_MAPBOX_LIST = {}
--是否初始化
GD.QUEST_MAPCONFIG_INIT = false
--代码路径
GD.QUEST_CODE_PATH = {}
--资源路径
GD.QUEST_RES_PATH = {}
-- 参数配置
GD.QUEST_CONFIGS = {}
local LuaList = require("common.LuaList")
local QuestConfig = require("baseQuestCode.lobby.QuestConfig")
local QuestManager = class("QuestManager", BaseActivityControl)
local QuestPassNet = require("activities.Activity_Quest.net.QuestPassNet")

-- QuestManager.m_instance = nil
-- 构造函数
function QuestManager:ctor()
    QuestManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Quest)
    self:initData()
end

function QuestManager:initData()
    self.m_lastThemeName = nil
    self:clearData()

    self.m_isNewUserQuestCompleted = false
    self.m_isFinishQuestTask = false

    self.m_passNet = QuestPassNet:getInstance()
end
--初始化数据
function QuestManager:clearData()
    self.m_showViewList = LuaList.new()
    self.m_showViewCount = -1
end

--下载成功后刷新配置文件
function QuestManager:checkUpdateConfig(key)
    local themeName = ""
    local _data = self:getRunningData()
    if _data then
        themeName = _data:getThemeName()
    end
    --修复只下载base或者code第一次不能进入bug
    if key == themeName or key == themeName .. "Code" or key == themeName .. "_Code" or key == "Activity_QuestBase" then
        self:updateQuestConfig()
    end
end

function QuestManager:getConfigPath()
    local themeName = ""
    local _data = self:getRunningData()
    if _data then
        themeName = _data:getThemeName()
    end
    if self:isNewUserQuest() then
        self.m_lastThemeName = "Activity_QuestNewUser"
    else
        if self.m_lastThemeName and self.m_lastThemeName == themeName then
            return
        end
        self.m_lastThemeName = themeName
    end

    local len = string.len("Activity_Quest") + 1
    local themeName_fix = string.sub(themeName, len)
    local filePath = "Quest" .. themeName_fix .. "Code/" .. themeName_fix .. "Config"
    if self:isNewUserQuest() then
        local groupName = self:getGroupName()
        if groupName == "GroupB" then
            filePath = "QuestNewUserCode/GroupB/NewUserConfigB"
        elseif groupName == "GroupA" then
            filePath = "QuestNewUserCode/GroupA/NewUserConfigA"
        elseif groupName == "GroupC" then
            filePath = "QuestNewUserCode/GroupC/NewUserConfigC"
        end
    end
    return filePath
end
--更新quest配置文件 切换主题、切换新手和普通都需要调用
function QuestManager:updateQuestConfig()
    if not self:isDownloadRes(true) then
        return
    end

    local filePath = self:getConfigPath()
    if not filePath then
        return
    end
    --找不到资源不能切换
    if not util_IsFileExist(filePath .. ".lua") and not util_IsFileExist(filePath .. ".luac") then
        return
    end

    --重置基础配置
    QUEST_MAPCONFIG_INIT = false
    QUEST_CODE_PATH = {}
    QUEST_RES_PATH = {}
    QUEST_PLIST_PATH = {}

    self:updateCodeInfo(QuestConfig.code)
    self:updateResInfo(QuestConfig.res)
    self:updateConfigInfo(QuestConfig.config)

    table.merge(QUEST_PLIST_PATH, QuestConfig.plist or {})

    local themeConfig = util_require(filePath)
    if not themeConfig then
        return
    end
    self:updateCodeInfo(themeConfig.code)
    self:updateResInfo(themeConfig.res)
    self:updateConfigInfo(themeConfig.config)

    table.merge(QUEST_PLIST_PATH, themeConfig.plist or {})
end

function QuestManager:getGroupName()
    local newuserTheme = globalData.constantData.QUEST_NEWUSER_THEME or 0
    if newuserTheme == 0 or newuserTheme == "0" then
        return "GroupA"
    elseif newuserTheme == 1 or newuserTheme == "1" then
        return "GroupB"
    elseif newuserTheme == 2 or newuserTheme == "2" then
        return "GroupC"
    end
end

--子类重写lua文件更新路径
function QuestManager:updateCodeInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            QUEST_CODE_PATH[key] = value
        end
    end
end

--子类修改资源路径
function QuestManager:updateResInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            QUEST_RES_PATH[key] = value
        end
    end
end
--子类修改配置参数
function QuestManager:updateConfigInfo(configs)
    if configs then
        for key, value in pairs(configs) do
            QUEST_CONFIGS[key] = value
        end
    end
end

function QuestManager:isNewUserQuest()
    local _data = self:getData()
    if _data then
        return _data:isNewUserQuest()
    else
        return false
    end
end

-- 设置新手Quest完成状态
function QuestManager:setNewUserQuestCompleted(isCompleted)
    self.m_isNewUserQuestCompleted = isCompleted
end

function QuestManager:isNewUserQuestCompleted()
    if self:isNewUserQuest() then
        return self:getData():checkIsLastRound()
    else
        return self.m_isNewUserQuestCompleted
    end
end

--是否正在普通quest关卡
function QuestManager:isNormalQuestGame()
    local _data = self:getRunningData()
    if _data and not _data:isNewUserQuest() and _data.m_IsQuestLogin then
        return true
    end

    return false
end

--是否下载过主题了系统还没更新
function QuestManager:isOnlyDownloadingBase()
    if self:isDownloadRes(true) and not self:checkDownloaded("Activity_QuestBase") then
        return true
    end
    return false
end

-- 是否已下载资源
function QuestManager:isDownloadRes(ignoreBase)
    if self:isNewUserQuest() then
        return true
    end

    if not ignoreBase and not self:checkDownloaded("Activity_QuestBase") then
        return false
    end

    return QuestManager.super.isDownloadRes(self)
end

function QuestManager:isDownloadLobbyRes()
    if self:isNewUserQuest() then
        return true
    end

    -- 弹板、hall、slide、资源在loading内
    return self:isDownloadLoadingRes()
end

function QuestManager:getEntryModule()
    if not self:isDownloadRes() then
        return ""
    end

    local _module = ""
    if self.m_lastThemeName and table.nums(QUEST_CODE_PATH) > 0 and string.len(QUEST_CODE_PATH.QuestEntryNode) > 0 then
        _module, _ = string.gsub(QUEST_CODE_PATH.QuestEntryNode, "/", ".")
    end
    return _module
end

function QuestManager:getLobbyBottomName()
    if globalData.constantData.NOVICE_NEW_QUEST_OPEN and globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_NEWUSERQUEST or self:getThemeName() == "Activity_QuestNewUser" then
        return "Activity_QuestNewUserLobbyNode"
    else
        return QuestManager.super.getLobbyBottomName(self)
    end
end

--获得主界面节点
function QuestManager:getQuestMainView(_isAutoPop)
    if not self:isRunning() then
        return
    end

    if not self.m_lastThemeName then
        return
    end

    if not QUEST_CODE_PATH or not QUEST_CODE_PATH.QuestMainView then
        return
    end

    local uiView = util_createFindView(QUEST_CODE_PATH.QuestMainView, _isAutoPop)
    if uiView ~= nil then
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "questBtn", DotUrlType.UrlName, true, DotEntrySite.DownView, DotEntryType.Lobby)
        end

        if uiView.m_dotLog then
            uiView.onHangExit = function()
                if gLobalSendDataManager.getLogPopub then
                    gLobalSendDataManager:getLogPopub():removeUrlKey(uiView.__cname)
                end
            end
            -- 界面名字  类型是url
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():pushUrlKey(uiView.__cname, DotUrlType.ViewName, false)
            end
        end
    end

    return uiView
end

--[[ 2023年06月14日14:19:11
    cxc 新手期quest 优化：
        登录到大厅直接进入 quest 界面(第一章未完成)
        扩圈 > 大厅 > slots. 
]] 
function QuestManager:needShowInLobby(_bLoginToLobby)
    local quest_cada = self:getRunningData()
    if quest_cada then
        if not _bLoginToLobby then
            return quest_cada.m_IsQuestLogin
        end

        local bShow = quest_cada:checkNewUserLoginShowQuest(_bLoginToLobby)
        if bShow then
            return bShow
        end
        return quest_cada.m_IsQuestLogin
    end
    return false
end

--显示quest主界面
function QuestManager:showMainLayer(isJumpToPhase, _isAutoPop)
    if not self:isCanShowLayer() or not self:checkDownloaded("Activity_QuestBase") then
        return
    end

    local questMainView = gLobalViewManager:getViewByExtendData("QuestMainLayer")
    if questMainView then
        return
    end

    -- gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER, false)
    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)

    local questConfig = self:getRunningData()
    local uiView = self:getQuestMainView(_isAutoPop)
    if uiView then
        questConfig.class.m_IsQuestLogin = false
        questConfig.m_isQuestLobby = true
        if isJumpToPhase then
            uiView:setShowActionEnabled(false)
        end

        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
        -- 记录打开次数
        local newCount = gLobalDataManager:getNumberByField("Activity_Quest_New", 0)
        newCount = newCount + 1
        gLobalDataManager:setNumberByField("Activity_Quest_New", newCount)

        local uiName = "QuestLobby"
        local themeName = ""
        local quest_data = self:getRunningData()
        if quest_data and quest_data:getThemeName() == "Activity_QuestIsland" then
            uiName = "islandQuestLobby"
            themeName = "IslandQuestPage"
        end
        gLobalSendDataManager:getLogQuestActivity():sendQuestUILog(uiName, "Open", themeName)
        return true
    end
end

-- 显示章节界面
function QuestManager:showPhaseView(phase_idx)
    if not self:isCanShowLayer() then
        return false
    end

    -- 指定了章节界面文件 跳转到章节界面
    if not QUEST_CODE_PATH.QuestIslandPhaseView then
        return false
    end

    local quest_data = self:getRunningData()
    if not quest_data then
        return false
    end

    if gLobalViewManager:getViewByExtendData("QuestIslandPhaseView") then
        return true
    end

    if not phase_idx then
        phase_idx = quest_data:getPhaseIdx()
    -- local record_data = self:getRecordStageInfo()
    -- if record_data and record_data.phaseIdx then
    --     phase_idx = record_data.phaseIdx
    -- end
    end
    local phaseView = util_createView(QUEST_CODE_PATH.QuestIslandPhaseView, phase_idx)
    if not phaseView then
        return false
    end

    self:showMainLayer()
    local questMainView = gLobalViewManager:getViewByExtendData("QuestMainLayer")
    if questMainView then
        questMainView:setShowActionEnabled(false)
    end

    local bl_showInLobby = self:needShowInLobby()
    if bl_showInLobby then
        phaseView:setShowActionEnabled(false)
    end

    gLobalSendDataManager:getLogQuestActivity():sendQuestUILog("islandQuesGametLobby", "Open", "IslandQuestPage")
    gLobalViewManager:showUI(phaseView, ViewZorder.ZORDER_UI)
    return true
end

function QuestManager:jumpToPhaseViewAndWait()
    self:jumpToPhaseView(true)
end
-- 直接跳转到章节界面
function QuestManager:jumpToPhaseView(bl_wait)
    if not self:isCanShowLayer() then
        return false
    end

    if self:isNewUserQuest() then
        return false
    end

    -- 指定了章节界面文件 跳转到章节界面
    if not QUEST_CODE_PATH.QuestIslandPhaseView then
        return false
    end

    local quest_data = self:getRunningData()
    if not quest_data then
        return false
    end

    if gLobalViewManager:getViewByExtendData("QuestIslandPhaseView") then
        return true
    end

    if bl_wait == nil then
        bl_wait = false
    end
    local phase_idx = quest_data:getPhaseIdx()
    local record_data = self:getRecordStageInfo()

    if record_data and record_data.phaseIdx then
        phase_idx = record_data.phaseIdx
    end

    local phaseView = util_createView(QUEST_CODE_PATH.QuestIslandPhaseView, phase_idx)
    if not phaseView then
        return false
    end
    phaseView:setShowActionEnabled(false)
    phaseView:setWait(bl_wait)
    self:showMainLayer(true)
    local questMainView = gLobalViewManager:getViewByExtendData("QuestMainLayer")
    if questMainView then
        questMainView:setVisible(false)
        questMainView:setWait(true)
    end

    gLobalSendDataManager:getLogQuestActivity():sendQuestUILog("islandQuesGametLobby", "Open", "IslandQuestPage")
    gLobalViewManager:showUI(phaseView, ViewZorder.ZORDER_UI)
    return true
end

function QuestManager:checkShowPassLayer()
    local actDate = self:getRunningData()
    if not actDate then
        return false
    end
    local passData = actDate:getPassData()
    if not passData then
        return false
    end
    local currentBigIndex = passData:getCurrentPassBigIndex()
    if not self.m_currentBigIndex then
        self.m_currentBigIndex = gLobalDataManager:getNumberByField("QuestPassCheckShow", 0)
    end
    if currentBigIndex > self.m_currentBigIndex then
        self.m_currentBigIndex = currentBigIndex
        gLobalDataManager:setNumberByField("QuestPassCheckShow", currentBigIndex)
        return true
    end
    return false
end

-- pass
function QuestManager:showPassLayer(_params)
    if not self:isCanShowLayer() then
        return false
    end

    if gLobalViewManager:getViewByExtendData("QuestPassLayer") == nil then
        local passLayer = util_createFindView(QUEST_CODE_PATH.QuestPassLayer, _params)
        if passLayer then
            self:showLayer(passLayer, ViewZorder.ZORDER_UI)
        end
    end
end

function QuestManager:showPassBuyTicketRewardPreviewLayer()
    if not self:isCanShowLayer() then
        return false
    end

    local actDate = self:getRunningData()
    if not actDate then
        return false
    end
    local passData = actDate:getPassData()
    if not passData then
        return false
    end

    if passData:isWillShowBuyTicketLayer() and gLobalViewManager:getViewByExtendData("QuestPassRewardPreviewLayer") == nil then
        local passLayer = util_createFindView(QUEST_CODE_PATH.QuestPassBuyTicketRewardPreviewLayer)
        if passLayer then
            self:showLayer(passLayer, ViewZorder.ZORDER_UI)
        end
        passData:clearWillShowBuyTicketLayer()
    end
end

function QuestManager:showPassRuleLayer()
    if not self:isCanShowLayer() then
        return false
    end

    local ruleView = util_createFindView(QUEST_CODE_PATH.QuestPassRuleView)
    if ruleView then
        self:showLayer(ruleView, ViewZorder.ZORDER_UI)
    end
end

function QuestManager:showPassBuyTicketLayer()
    if not self:isCanShowLayer() then
        return false
    end

    local buyTicketLayer = util_createFindView(QUEST_CODE_PATH.QuestPassBuyTicket)
    if buyTicketLayer then
        self:showLayer(buyTicketLayer, ViewZorder.ZORDER_UI)
    end
end

-- 显示玩法简介
function QuestManager:showInfo()
    if not self:isCanShowLayer() then
        return false
    end

    local QuestIslandInfoView = util_createView(QUEST_CODE_PATH.QuestInfo)
    if QuestIslandInfoView then
        gLobalViewManager:showUI(QuestIslandInfoView, ViewZorder.ZORDER_UI)
    end
end

-- 显示关卡信息界面
function QuestManager:showStageTips(phase_idx, stage_idx)
    if not phase_idx or not stage_idx then
        return
    end
    local islandCellTips = util_createView("QuestIslandCode.IslandCellTips", phase_idx, stage_idx)
    if islandCellTips then
        gLobalViewManager:showUI(islandCellTips, ViewZorder.ZORDER_UI)
    end
end

-- 显示开启弹板
function QuestManager:showOpenLayer(callback)
    if gLobalViewManager:isLobbyView() or gLobalViewManager:isLoadingView() then
        return nil
    end

    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if self:isNewUserQuest() then
        -- view = util_createView(QUEST_CODE_PATH.QuestOpenView, callback)
        if not view or globalData.GameConfig:checkUseNewNoviceFeatures() then
            view = util_createView(QUEST_CODE_PATH.QuestLoginView, callback)
        end

        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end
-- 解锁新手 quest
function QuestManager:createQuestOpenFlyEf()
    if not self:isCanShowLayer() or not self:isNewUserQuest()then
        return
    end

    local flyEfView = util_createView("QuestNewUserCode.QuestNewUserOpenFlyEfUI")
    return flyEfView
end

-- 显示结束弹板
function QuestManager:showOverLayer(callback, isCompleted)
    if isCompleted and self:getGroupName() == "GroupB" then
        util_restartGame()
        return
    end
    local view = gLobalViewManager:getViewByName("QuestNewUserClose")
    if not view then
        if isCompleted and globalData.GameConfig:checkUseNewNoviceFeatures() then
             --[[ 2023年06月14日14:20:02
                cxc 新手quest完成 功能解锁弹板不显示： 直接走重登
            ]]
            self:questNoviceOverRestartGame()
            -- view = util_createView("QuestNewUserCode.QuestNewUserCloseViewNew")
        else
            view =
                util_createView(
                "QuestNewUserCode.QuestNewUserCloseView",
                function()
                    if callback then
                        callback()
                    end
                    if isCompleted then
                        G_DelActivityDataByRef(self:getRefName())
                    end
                end,
                isCompleted
            )
            view:setName("QuestNewUserClose")
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end

    return view
end
function QuestManager:questNoviceOverRestartGame()
    globalData.userRunData:saveLeveToLobbyRestartInfo()
    if globalData.slotRunData.isPortrait == true then
        globalData.slotRunData.isChangeScreenOrientation = true
        globalData.slotRunData:changeScreenOrientation(false)
    end

    gLobalDataManager:setBoolByField("QuestUlkLobbyBtmGuide", true)
    util_restartGame()
end
function QuestManager:checkQuestUlkLobbyBtmGuide()
    local bNeedGuide = gLobalDataManager:getBoolByField("QuestUlkLobbyBtmGuide", false)
    return bNeedGuide and self:isRunning()
end
function QuestManager:setLobbyBtmQuestUI(_node)
    if self.m_lobbyBtmQuestUI then
        return
    end
    self.m_lobbyBtmQuestUI = _node
end
function QuestManager:getLobbyBtmQuestUI()
    return self.m_lobbyBtmQuestUI
end
function QuestManager:setLobbyBtmBigActUI(_node)
    if self.m_lobbyBtmBigActUI then
        return
    end
    self.m_lobbyBtmBigActUI = _node
end
function QuestManager:getLobbyBtmBigActUI()
    return self.m_lobbyBtmBigActUI
end

function QuestManager:showLobbyBtmGuideLayer()
    if not self:isCanShowLayer() or not self.m_lobbyBtmQuestUI then
        return
    end
    
    local gudieView = util_createView("activities.Activity_Quest.views.QuestLobbyBtmGuideLayer")
    self:showLayer(gudieView)
    return gudieView
end
function QuestManager:dealLobbyBtmGuide()
    local guideView = gLobalViewManager:getViewByName("QuestLobbyBtmGuideLayer")
    if guideView then
        guideView:startGuide()
        return true
    end
    gLobalDataManager:setBoolByField("QuestUlkLobbyBtmGuide", false)
    return false
end

--进入关卡显示任务界面
function QuestManager:showEnterLayer()
    local uiView = util_createFindView(QUEST_CODE_PATH.QuestEnterLayer)
    if uiView ~= nil then
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "Push", DotUrlType.UrlName, true, DotEntrySite.LeftView, DotEntryType.Game)
        end
        self:showLayer(uiView, ViewZorder.ZORDER_UI)
    end
end

--关卡中判断是否完成任务
function QuestManager:isTaskDone()
    local quest_data = self:getRunningData()
    if not quest_data or not quest_data.m_IsQuestLogin then
        return false
    end
    local phase_idx = quest_data:getPhaseIdx()
    local stage_idx = quest_data:getStageIdx()
    return quest_data:IsTaskFinish(phase_idx, stage_idx)
end

--关卡中判断是否弹出跳关购买弹板
function QuestManager:isShowSkipSaleView()
    local quest_data = self:getRunningData()
    if not quest_data or not quest_data.m_IsQuestLogin then
        return false
    end
    return quest_data:getIsShowSkipSaleView()
end

--显示任务完成界面
function QuestManager:showTaskDoneView()
    if gLobalViewManager:getViewByExtendData("QuestTaskDoneLayer") ~= nil then
        return
    end

    local uiView = util_createFindView(QUEST_CODE_PATH.QuestTaskDoneLayer)
    if uiView ~= nil then
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "Push", DotUrlType.UrlName, true, DotEntrySite.LeftView, DotEntryType.Game)
        end
        self:showLayer(uiView, ViewZorder.ZORDER_UI)
    else
        util_sendToSplunkMsg("QuestTaskDone", "创建界面失败 没有资源")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
    end
    return uiView
end

--是否需要弹出选择难度
function QuestManager:IsNeedShowDifficultyView(phase)
    local quest_data = self:getRunningData()
    if not quest_data then
        return false
    end

    if not phase then
        phase = quest_data:getPhaseIdx()
    end
    if quest_data:getCurDifficulty(phase) == -1 then
        return true
    end

    return false
end

function QuestManager:getCurDifficulty()
    local quest_data = self:getRunningData()
    if not quest_data then
        return 0
    end
    return quest_data:getCurDifficulty(quest_data:getPhaseIdx())
end

--显示选择难度
function QuestManager:showDifficultyView()
    local diffView = gLobalViewManager:getViewByExtendData("QuestDifficultyLayer")
    if diffView then
        -- 界面已存在
        return
    end

    --请求quest关卡难度+奖励
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_ACTIVITY_QUEST_PHASEREWARD)
            local uiView = util_createFindView(QUEST_CODE_PATH.QuestDifficultyLayer)
            if uiView ~= nil then
                if gLobalSendDataManager.getLogPopub then
                    gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "Push", DotUrlType.UrlName, false)
                end
                uiView:updateView(params)
                self:showLayer(uiView, ViewZorder.ZORDER_UI)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_PHASEREWARD
    )
    gLobalSendDataManager:getNetWorkFeature():sendActionQuestPhaseReward()
end

--显示下一章节
-- function QuestManager:showNextPhase()
--     --请求quest关卡难度+奖励
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_ACTIVITY_QUEST_PHASEREWARD)
--             -- 抛出消息 过度到下一章节
--         end,
--         ViewEventType.NOTIFY_ACTIVITY_QUEST_PHASEREWARD
--     )
--     gLobalSendDataManager:getNetWorkFeature():sendActionQuestPhaseReward()
-- end

--打开排行榜
function QuestManager:showRankView(clickName)
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", clickName)
    local uiView = util_createFindView(QUEST_CODE_PATH.QuestRankLayer)
    if uiView ~= nil then
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(uiView, clickName, DotUrlType.UrlName, false)
        end
        self:showLayer(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end

-- 显示跳关促销界面
function QuestManager:showSkipSaleView(isGameEffect, isAutoClose)
    --self:recordStageInfo()
    local questConfig = self:getRunningData()
    if not questConfig then
        return 
    end
    local view_path = QUEST_CODE_PATH.QuestSkipSaleView
    if questConfig:isHaveSkipSale_PlanB() then
        view_path = QUEST_CODE_PATH.QuestSkipSaleView_PlanB
    end
    local uiView = util_createFindView(view_path, isGameEffect)
    if uiView ~= nil then
        self:showLayer(uiView, ViewZorder.ZORDER_UI)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TASK_CHOICE_VIEW_CLOSE)
        if isGameEffect then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
        end
    end
end

--完成quest关卡后弹窗
function QuestManager:checkShowFinishView(updateCellFunc)
    local infoList = {}
    --弹窗
    return self:checkShowView(infoList, updateCellFunc)
end

--进入quest弹窗
function QuestManager:checkShowEnterView(updateCellFunc)
    local questConfig = self:getRunningData()
    if not questConfig then
        return false
    end
    local infoList = {}
    --展示排行榜
    if questConfig and questConfig.m_isAutoShowTop then
        questConfig.m_isAutoShowTop = false
        infoList[#infoList + 1] = {path = QUEST_CODE_PATH.QuestRankLayer}
    end
    -- questRush活动
    local entrySite = gLobalSendDataManager:getLogQuestActivity():getQuestEntrySite()
    if entrySite ~= "gameBackLobby" then
        infoList[#infoList + 1] = {func = handler(self, self.showQuestRushPanel)}
    end
    --弹窗
    return self:checkShowView(infoList, updateCellFunc)
end

--展示一系列弹窗
function QuestManager:checkShowView(infoList, updateCellFunc)
    if not infoList or #infoList == 0 then
        if updateCellFunc then
            updateCellFunc()
        end
        return false
    end
    --正在弹窗
    if not self.m_showViewList:empty() or self.m_showViewCount ~= -1 then
        if updateCellFunc then
            updateCellFunc()
        end
        return false
    end
    self.m_showViewCount = 0
    for i = 1, #infoList do
        self.m_showViewList:push(infoList[i])
    end
    self:setShowViewCallBack(updateCellFunc)
    return self:showViewNext()
end

--显示下一个弹窗
function QuestManager:showViewNext()
    --界面关闭了
    if not self.m_showViewList then
        return false
    end
    --结束条件
    if self.m_showViewList:empty() then
        self:showViewFinish()
        return false
    end
    local info = self.m_showViewList:pop()
    if info then
        if info.func then
            --执行一个方法
            self.m_showViewCount = self.m_showViewCount + 1
            info.func(handler(self, self.showViewNext))
            return true
        elseif info.path then
            --打开一个界面
            local uiView = util_createFindView(info.path, info.data)
            if uiView ~= nil then
                self.m_showViewCount = self.m_showViewCount + 1
                if gLobalSendDataManager.getLogPopub then
                    gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "Push", DotUrlType.UrlName, false)
                end
                self:showLayer(uiView, ViewZorder.ZORDER_UI)
                uiView:setOverFunc(handler(self, self.showViewNext))
                return true
            else
                return self:showViewNext()
            end
        else
            return self:showViewNext()
        end
    else
        return self:showViewNext()
    end
end

--接受回调
function QuestManager:setShowViewCallBack(func)
    self.m_showViewFunc = func
end

--完成弹窗
function QuestManager:showViewFinish()
    self.m_showViewList:clear()
    if self.m_showViewCount > 0 and self.m_showViewFunc then
        self.m_showViewFunc()
        self.m_showViewFunc = nil
    end
    self.m_showViewCount = -1
end

-- 显示quest挑战活动面板
function QuestManager:showQuestRushPanel(_cb)
    G_GetMgr(ACTIVITY_REF.QuestRush):showMainView(_cb)
end

--制作点击区域
function QuestManager:makeTouch(size, btnName)
    if not size or not btnName then
        return
    end
    local touch = ccui.Layout:create()
    touch:setName(btnName)
    touch:setTag(-10)
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(true)
    touch:setAnchorPoint(0.5000, 0.5000)
    touch:setContentSize(size)
    touch:setClippingEnabled(false)
    touch:setBackGroundColorOpacity(0)
    return touch
end

--拷贝到对应主题的资源目录中
function QuestManager:writeQuestMapConfig(path)
    --读取地图配置csb
    local test = util_createAnimation(path)
    --初始化数据
    local data = {}

    --地图关卡获取
    local nodeCell = test:findChild("node_cell")
    if nodeCell then
        local childs1 = nodeCell:getChildren()
        data.cell = {}
        for i = 1, #childs1 do
            data.cell[i] = cc.p(childs1[i]:getPosition())
        end
    end

    --地图连线获取
    local nodeDian = test:findChild("node_dian")
    if nodeDian then
        local childs2 = nodeDian:getChildren()
        data.dian = {}
        for i = 1, #childs2 do
            local dianNode = childs2[i]
            data.dian[i] = {}
            local childs3 = dianNode:getChildren()
            local pos = cc.p(dianNode:getPosition())
            for j = 1, #childs3 do
                data.dian[i][j] = ccpAdd(pos, cc.p(childs3[j]:getPosition()))
            end
        end
    end

    --地图宝箱获取
    local nodeBox = test:findChild("Node_box")
    if nodeBox then
        local childs4 = nodeBox:getChildren()
        data.Box = {}
        local boxPos = cc.p(nodeBox:getPosition())
        for i = 1, #childs4 do
            data.Box[i] = ccpAdd(boxPos, cc.p(childs4[i]:getPosition()))
        end
    end

    --写入json文件
    local jsonData = cjson.encode(data)
    local path = device.writablePath .. "questMapConfig.json"
    local file = io.open(path, "wb+")
    file:write(jsonData)
    file:flush()
    file:close()
end

--读取questMapConfig如果修改了地图配置需要跑writeQuestMapConfig重新写配置
function QuestManager:checkReadMapConfig()
    if not QUEST_MAPCONFIG_INIT then
        local content = cc.FileUtils:getInstance():getStringFromFile(QUEST_CODE_PATH.QuestMapConfig)
        if string.len(content) == 0 then
            return
        end
        local luaConfig = cjson.decode(content)
        if luaConfig then
            QUEST_MAPCELL_LIST = luaConfig.cell or {}
            QUEST_MAPLINE_LIST = luaConfig.dian or {}
            QUEST_MAPBOX_LIST = luaConfig.Box or {}
            QUEST_MAPCONFIG_INIT = true
        end
    end
end

-- 获得折扣
function QuestManager:getDiscount()
    local _data = self:getRunningData()
    if _data then
        return _data:getDiscount()
    else
        return 0
    end
end

function QuestManager:getRewardVipBoostItem(_rewardData)
    local item = nil
    if _rewardData.p_items and #_rewardData.p_items > 0 then
        for i = 1, #_rewardData.p_items do
            local itemData = _rewardData.p_items[i]
            if itemData.p_icon == "VipBoost" then
                item = itemData
                break
            end
        end
    end
    return item
end

function QuestManager:isCanShowHall()
    if self:isNewUserQuest() then
        return false
    else
        return QuestManager.super.isCanShowHall(self)
    end
end

function QuestManager:isCanShowSlide()
    if self:isNewUserQuest() then
        return false
    else
        return QuestManager.super.isCanShowSlide(self)
    end
end

function QuestManager:isCanShowInEntrance()
    if self:isNewUserQuest() then
        return false
    end
    return QuestManager.super.isCanShowInEntrance(self)
end

-- 完成关卡时 记录章节信息 用于和服务器数据做对比 表现完成动画
function QuestManager:recordStageInfo()
    local record_datas = {}

    local quest_data = self:getRunningData()
    if quest_data then
        record_datas.phaseIdx = quest_data:getPhaseIdx()
        record_datas.stageIdx = quest_data:getStageIdx()
        record_datas.phase_data = clone(quest_data:getPhaseData(record_datas.phaseIdx))
        local stage_data = record_datas.phase_data.p_stages[record_datas.stageIdx]
        self.record_datas = record_datas
    end
end

function QuestManager:getRecordStageInfo()
    return self.record_datas
end

function QuestManager:clearRecordStageInfo()
    self.record_datas = nil
end

function QuestManager:clearRecordJackpot()
    local quest_data = self:getRunningData()
    if quest_data then
        quest_data.m_lastBoxJackpot = nil
    end
end

function QuestManager:setRecordRewardData(data)
    self.record_rewardsData = data
end

function QuestManager:getRecordRewardData()
    return self.record_rewardsData
end

function QuestManager:clearRecordRewardData()
    self.record_rewardsData = nil
end

function QuestManager:willShowEnded()
    local quest_data = self:getData()
    -- 非quest关卡 不执行此逻辑
    if quest_data and quest_data.class.m_IsQuestLogin == false then
        return false
    end
    
    if self:isRunning() then
        self.bl_showEnded = false
    elseif self.bl_showEnded == false then
        self.bl_showEnded = nil
        return true
    end
    return false
end

function QuestManager:isStageComplete()
    local quest_data = self:getRunningData()
    if not quest_data then
        return false
    end

    local phase_idx = quest_data:getPhaseIdx()
    local phase_data = quest_data:getPhaseData(phase_idx)
    if not phase_data then
        return false
    end

    for stage_idx, stage_data in ipairs(phase_data.p_stages) do
        if stage_data and stage_data.p_status == "FINISHED" or stage_data.p_status == "REWARD" then
            return true
        end
    end
    return false
end

function QuestManager:setRequestFlag(_flag)
    self.m_flag = _flag
end

function QuestManager:getRequestFlag()
    return self.m_flag
end

function QuestManager:getPopLayerLevelIcons()
    local theme_name = self:getGroupName()
    if theme_name == "GroupA" then
        local ICONS = {
            ["A"] = {
                "QuestNewUser/Activity/newUser_ui/icons2.png",
                "QuestNewUser/Activity/newUser_ui/icons5.png",
                "QuestNewUser/Activity/newUser_ui/icons1.png",
                "QuestNewUser/Activity/newUser_ui/icons4.png",
                "QuestNewUser/Activity/newUser_ui/icons7.png",
                "QuestNewUser/Activity/newUser_ui/icons8.png"
            },
            ["B"] = {
                "QuestNewUser/Activity/newUser_ui/icons3.png",
                "QuestNewUser/Activity/newUser_ui/icons2.png",
                "QuestNewUser/Activity/newUser_ui/icons1.png",
                "QuestNewUser/Activity/newUser_ui/icons9.png",
                "QuestNewUser/Activity/newUser_ui/icons5.png",
                "QuestNewUser/Activity/newUser_ui/icons8.png"
            },
            ["C"] = {
                "QuestNewUser/Activity/newUser_ui/icons2.png",
                "QuestNewUser/Activity/newUser_ui/icons5.png",
                "QuestNewUser/Activity/newUser_ui/icons1.png",
                "QuestNewUser/Activity/newUser_ui/icons4.png",
                "QuestNewUser/Activity/newUser_ui/icons7.png",
                "QuestNewUser/Activity/newUser_ui/icons8.png"
            }
        }
        local group_type = globalData.constantData.NOVICE_FEATURES_GROUP
        return ICONS[group_type]
    elseif theme_name == "GroupB" then
        local ICONS = {
            "QuestNewUser/Activity/newUser_ui/icons10.png",
            "QuestNewUser/Activity/newUser_ui/icons11.png",
            "QuestNewUser/Activity/newUser_ui/icons12.png",
            "QuestNewUser/Activity/newUser_ui/icons13.png",
            "QuestNewUser/Activity/newUser_ui/icons14.png",
            "QuestNewUser/Activity/newUser_ui/icons15.png"
        }
        return ICONS
    elseif theme_name == "GroupC" then
        local ICONS = {
            "QuestNewUser/Activity/newUser_ui_GroupC/icons1.png",
            "QuestNewUser/Activity/newUser_ui_GroupC/icons2.png",
            "QuestNewUser/Activity/newUser_ui_GroupC/icons3.png"
        }
        return ICONS
    end
end

function QuestManager:sendPassCollect(_data, _type)
    self.m_passNet:sendPassCollect(_data, _type)
end

function QuestManager:sendPassBoxCollect(_data, _type)
    self.m_passNet:sendPassBoxCollect(_data, _type)
end

function QuestManager:buyPassUnlock(_data)
    self.m_passNet:buyPassUnlock(_data)
end

-- 1 minor  2 major  3 grand
function QuestManager:updateQuestGoldIncrease(forceInit,data)
    local activityData = self:getRunningData()
    local timeOut = false
    if activityData then
        if activityData:updateQuestGoldIncrease(forceInit,data) then
            timeOut = true
        end
    end
    if timeOut then
        self:requestGetPool()
    end
end

-- 第二个返回值 是否是展示名字
function QuestManager:getRuningGoldByType(type)
    local activityData = self:getRunningData()
    if activityData then
        return activityData:getRunGoldCoinByType(type)
    end
    return 111111111
end

function QuestManager:requestGetPool(isFirstEnter)
    local quest_data = self:getRunningData()
    if not quest_data then
        return 
    end
    -- 是否选了难度
    local diff = self:getCurDifficulty()
    if diff == -1 then
        return
    end
    if self.m_requestGetPool then
        return
    end
    if not self.m_isFirstEnter then
        self.m_isFirstEnter = true
    elseif isFirstEnter and self.m_isFirstEnter then
        return
    end
    self.m_requestGetPool = true
    self.m_passNet:requestGetPool()
end

function QuestManager:clearRequestGetPool()
    self.m_requestGetPool = false
end

-- 奖励
function QuestManager:showRewardLayer(layerType,_rewardCoins, _rewardGems, _rewardItems,_over)
    if gLobalViewManager:getViewByName("QuestJackpotRewardLayer") ~= nil then
        return nil
    end

    local view = util_createView(QUEST_CODE_PATH.QuestJackpotWheelRewardLayer, _rewardCoins, _rewardGems, _rewardItems,_over,layerType)
    view:setExtendData("QuestJackpotRewardLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function QuestManager:showJackpotRuleLayer()
    if gLobalViewManager:getViewByName("QuestJackpotRuleLayer") ~= nil then
        return nil
    end

    local view = util_createView(QUEST_CODE_PATH.QuestJackpotRuleLayer)
    view:setExtendData("QuestJackpotRuleLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

return QuestManager
