--
-- quest 管理
--
--代码路径
GD.QUESTNEW_CODE_PATH = {}
--资源路径
GD.QUESTNEW_RES_PATH = {}
-- 参数配置
GD.QUESTNEW_CONFIGS = {}

local LuaList = require("common.LuaList")
local QuestNewConfig = require("baseQuestNewCode.lobby.QuestNewConfig")
local QuestNewNet = require("activities.Activity_QuestNew.net.QuestNewNet")
local QuestNewGuide = require("activities.Activity_QuestNew.controller.QuestNewGuideCtrl")
local QuestNewManager = class("QuestNewManager", BaseActivityControl)
-- QuestNewManager.m_instance = nil
-- 构造函数
function QuestNewManager:ctor()
    QuestNewManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.QuestNew)
    self:initData()
    self.m_net = QuestNewNet:getInstance()
    self.m_guide = QuestNewGuide:getInstance()
end

function QuestNewManager:getGuide()
    return self.m_guide
end

function QuestNewManager:initData()
    self.m_lastThemeName = nil
    self:clearData()

    self.m_isNewUserQuestCompleted = true -- 先强制设置为没有新手Quset
    self.m_isFinishQuestNewTask = false

    --是否初始化
    self.m_isConfigInit = false
end
--初始化数据
function QuestNewManager:clearData()
    self.m_showViewList = LuaList.new()
    self.m_showViewCount = -1
end

--下载成功后刷新配置文件
function QuestNewManager:checkUpdateConfig(key)
    local themeName = ""
    local _data = self:getRunningData()
    if _data then
        themeName = _data:getThemeName()
    end
    --修复只下载base或者code第一次不能进入bug
    if key == themeName or key == themeName .. "Code" or key == themeName .. "_Code" or key == "Activity_QuestNewBase" then
        self:updateQuestConfig()
    end
end
--更新quest配置文件 切换主题、切换新手和普通都需要调用
function QuestNewManager:updateQuestConfig()
    if not self:isDownloadRes(true) then
        return
    end

    local themeName = ""
    local _data = self:getRunningData()
    if _data then
        themeName = _data:getThemeName()
    end
    if self:isNewUserQuestNew() then
        self.m_lastThemeName = "Activity_QuestNewNewUser"
    else
        if self.m_lastThemeName and self.m_lastThemeName == themeName then
            return
        end
        self.m_lastThemeName = themeName
    end

    --重置基础配置
    self.m_isConfigInit = false
    QUESTNEW_CODE_PATH = {}
    QUESTNEW_RES_PATH = {}
    QUEST_PLIST_PATH = {}

    self:updateCodeInfo(QuestNewConfig.code)
    self:updateResInfo(QuestNewConfig.res)
    self:updateConfigInfo(QuestNewConfig.config)

    table.merge(QUEST_PLIST_PATH, QuestNewConfig.plist or {})

    local len = string.len("Activity_Quest") + 1
    local themeName_fix = string.sub(themeName, len)
    local filePath = "QuestNew" .. themeName_fix .. "Code/" .. themeName_fix .. "Config"
    --找不到资源不能切换
    if not util_IsFileExist(filePath .. ".lua") and not util_IsFileExist(filePath .. ".luac") then
        return
    end
    if themeName then
        local themeConfigPath = "QuestNew" .. themeName_fix .. "Code." .. themeName_fix .. "Config"
        local themeConfig = util_require(themeConfigPath)
        self:updateCodeInfo(themeConfig.code)
        self:updateResInfo(themeConfig.res)
        self:updateConfigInfo(themeConfig.config)

        table.merge(QUEST_PLIST_PATH, themeConfig.plist or {})
    end
end

--子类重写lua文件更新路径
function QuestNewManager:updateCodeInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            QUESTNEW_CODE_PATH[key] = value
        end
    end
end

--子类修改资源路径
function QuestNewManager:updateResInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            QUESTNEW_RES_PATH[key] = value
        end
    end
end
--子类修改配置参数
function QuestNewManager:updateConfigInfo(configs)
    if configs then
        for key, value in pairs(configs) do
            QUESTNEW_CONFIGS[key] = value
        end
    end
end

function QuestNewManager:isNewUserQuestNew()
    local _data = self:getData()
    if _data then
        return _data:isNewUserQuestNew()
    else
        return false
    end
end

-- 设置新手QuestNew完成状态
function QuestNewManager:setNewUserQuestCompleted(isCompleted)
    self.m_isNewUserQuestCompleted = isCompleted
end

function QuestNewManager:isNewUserQuestCompleted()
    if self:isNewUserQuestNew() then
        return self:getData():checkIsLastRound()
    else
        return self.m_isNewUserQuestCompleted
    end
end

--是否正在普通quest关卡
function QuestNewManager:isNormalQuestNewGame()
    local _data = self:getRunningData()
    if _data and not _data:isNewUserQuestNew() and _data.m_IsQuestNewLogin then
        return true
    end

    return false
end

--是否下载过主题了系统还没更新
function QuestNewManager:isOnlyDownloadingBase()
    if self:isDownloadRes(true) and not self:checkDownloaded("Activity_QuestNewBase") then
        return true
    end
    local themeName = self:getThemeName()
    if themeName == "Activity_QuestFantasy" then
        return true
    end
    return false
end

-- 是否已下载资源
function QuestNewManager:isDownloadRes(ignoreBase)
    if self:isNewUserQuestNew() then
        return true
    end

    if not ignoreBase and not self:checkDownloaded("Activity_QuestNewBase") then
        return false
    end
    local themeName = self:getThemeName()
    if themeName == "Activity_QuestFantasy" then
        return true
    end

    return QuestNewManager.super.isDownloadRes(self)
end

function QuestNewManager:isDownloadLobbyRes()
    if self:isNewUserQuestNew() then
        return true
    end

    -- 弹板、hall、slide、资源在loading内
    return self:isDownloadLoadingRes()
end

function QuestNewManager:checkRes(resName)
    if resName == "Activity_QuestFantasy" then
        return true
    end

    return QuestNewManager.super.checkRes(self,resName)
end

function QuestNewManager:getEntryModule()
    if not self:isDownloadRes() then
        return ""
    end

    local _module = ""
    if self:isNewUserQuestNew() then
        _module = "newQuestNewCode.Activity_QuestNewUserEntryNode"
    else
        if self.m_lastThemeName and table.nums(QUESTNEW_CODE_PATH) > 0 and string.len(QUESTNEW_CODE_PATH.QuestNewEntryNode) > 0 then
            _module, _ = string.gsub(QUESTNEW_CODE_PATH.QuestNewEntryNode, "/", ".")
        end
    end

    return _module
end

function QuestNewManager:getLobbyBottomName()
    return QuestNewManager.super.getLobbyBottomName(self)
    -- if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_NEWUSERQUEST or self:isNewUserQuestNew() then
    --     return "Activity_QuestNewNewUserLobbyNode"
    -- else
    --     return QuestNewManager.super.getLobbyBottomName(self)
    -- end
end

--获得主界面节点
function QuestNewManager:getQuestNewMainView()
    if not self:isRunning() then
        return nil
    end

    if not self.m_lastThemeName then
        return nil
    end

    local uiView = nil
    if self:isNewUserQuestNew() then
        uiView = util_createFindView("newQuestNewCode/QuestNew/QuestNewNewUserMainView")
    else
    uiView = util_createView(QUESTNEW_CODE_PATH.QuestNewChapterChoseMainView)
    end

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
function QuestNewManager:needShowInLobby(_bLoginToLobby)
    local quest_activity = self:getRunningData()
    if quest_activity then
        if not _bLoginToLobby then
            return quest_activity:isEnterGameFromQuest()
        end

        local bShow = quest_activity:checkNewUserLoginShowQuest(_bLoginToLobby)
        if bShow then
            return bShow
        end
        return quest_activity:isEnterGameFromQuest()
    end
    return false
end

---------------------------------------------展示界面相关--------------begin----------------------------------
--显示quest主界面
function QuestNewManager:showMainLayer(isJumpToPhase)
    if not self:isCanShowLayer() then
        return
    end

    local questMainView = gLobalViewManager:getViewByExtendData("QuestNewMainLayer")
    if questMainView then
        return
    end

    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER, false)
    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)

    local questConfig = self:getRunningData()
    local uiView = self:getQuestNewMainView()
    if uiView then
        self:clearEnterGameFromQuest()
        self:setIsEnterQuestLayer(true)
        if isJumpToPhase then
            uiView:setShowActionEnabled(false)
        end
        self.m_guide:onRegist(self:getThemeName())
        self:showLayer(uiView, ViewZorder.ZORDER_UI)
        -- 记录打开次数
        local newCount = gLobalDataManager:getNumberByField("Activity_QuestNew_New", 0)
        newCount = newCount + 1
        gLobalDataManager:setNumberByField("Activity_QuestNew_New", newCount)

        gLobalSendDataManager:getLogQuestNewActivity():sendQuestUILog("QuestLobby", "Open", "")
    end
end

-- 显示章节界面
function QuestNewManager:showQuestMainMapView(chapterId,forceBackChapter)
    if not self:isCanShowLayer() then
        return false
    end

    -- 指定了章节界面文件 跳转到章节界面
    if not QUESTNEW_CODE_PATH.QuestNewMainMapView then
        return false
    end

    local quest_data = self:getRunningData()
    if not quest_data then
        return false
    end

    if gLobalViewManager:getViewByExtendData("QuestNewMainMapView") then
        return true
    end

    local chapterId_use = quest_data:getCurrentChapterID()
    if chapterId then
        chapterId_use = chapterId
    else
        local enterChapterId,enterPointId = self:getEnterGameChapterIdAndPointId()
        if enterChapterId then
            chapterId_use = enterChapterId
        end
    end

    local phaseView = util_createView(QUESTNEW_CODE_PATH.QuestNewMainMapView, chapterId)
    if not phaseView then
        return false
    end

    if quest_data:isEnterGameFromQuest() or forceBackChapter then
        self:clearEnterGameFromQuest()
        self:setIsEnterQuestLayer(true)
        phaseView:setBackToChooseMainLayer(true)
        phaseView:setShowActionEnabled(false)
    end

    --gLobalSendDataManager:getLogQuestNewActivity():sendQuestNewUILog("islandQuesGametLobby", "Open", "IslandQuestNewPage")
    self:showLayer(phaseView, ViewZorder.ZORDER_UI)
    return true
end


function QuestNewManager:showStarPrizeView(chapterId,func)
    if not self:isCanShowLayer() then
        return false
    end

    local quest_data = self:getRunningData()
    if not quest_data then
        return false
    end

    local starPrizeView = util_createView(QUESTNEW_CODE_PATH.QuestNewChapterStarPrizesLayer,chapterId,func)
    if starPrizeView then
        self:showLayer(starPrizeView, ViewZorder.ZORDER_UI)
    end
end

function QuestNewManager:showWheelView(chapterId)
    if not self:isCanShowLayer() then
        return false
    end

    local quest_data = self:getRunningData()
    if not quest_data then
        return false
    end

    local starPrizeView = util_createView(QUESTNEW_CODE_PATH.QuestNewWheelLayer,chapterId)
    if starPrizeView then
        self:showLayer(starPrizeView, ViewZorder.ZORDER_UI)
    end
end

function QuestNewManager:showTipView(data)
    if not self:isCanShowLayer() then
        return false
    end

    local quest_data = self:getRunningData()
    if not quest_data then
        return false
    end

    local tipView = util_createView(QUESTNEW_CODE_PATH.QuestNewAllTipLayer,data)
    if tipView then
        self:showLayer(tipView, ViewZorder.ZORDER_UI)
    end
end

---------------------------------------------展示界面相关--------------end----------------------------------

--forceBackChapter 关闭强制返回主界面
function QuestNewManager:jumpToPhaseViewAndWait(forceBackChapter)
    self:jumpToMainMapViewAndPrepareChooseLayer(forceBackChapter)
end


-- 直接跳转到章节界面
function QuestNewManager:jumpToMainMapViewAndPrepareChooseLayer(forceBackChapter)

    local quest_data = self:getRunningData()
    if not quest_data then
        return false
    end
    local chapterId = quest_data:getCurrentChapterID()
    if quest_data:isEnterGameFromQuest() then
        local enterChapterId,enterPointId = self:getEnterGameChapterIdAndPointId()
        if enterChapterId then
            chapterId = enterChapterId
        end
    end
    --请求quest排行数据
    G_GetMgr(ACTIVITY_REF.QuestNew):requestQuestRank()
    return self:showQuestMainMapView(chapterId,forceBackChapter)
end

-- 显示玩法简介
function QuestNewManager:showInfo()
    if not self:isCanShowLayer() then
        return false
    end

    local QuestNewIslandInfoView = util_createView(QUESTNEW_CODE_PATH.QuestNewChapterChoseInfoView)
    if QuestNewIslandInfoView then
        self:showLayer(QuestNewIslandInfoView, ViewZorder.ZORDER_UI)
    end
end

-- 显示关卡信息界面
function QuestNewManager:showStageTips(chapterId, stage_idx)
    if not chapterId or not stage_idx then
        return
    end
    local islandCellTips = util_createView("QuestNewIslandCode.IslandCellTips", chapterId, stage_idx)
    if islandCellTips then
        self:showLayer(islandCellTips, ViewZorder.ZORDER_UI)
    end
end

-- 显示开启弹板
function QuestNewManager:showOpenLayer(callback)
    if gLobalViewManager:isLobbyView() or gLobalViewManager:isLoadingView() then
        return nil
    end

    local view = nil
    if self:isNewUserQuestNew() then
        --csc 2021-06-01 新手期ABTEST quest 优化弹板修改
        view = util_createView("newQuestNewCode.QuestNew.QuestNewNewUserOpenView", callback)
        if not view or globalData.GameConfig:checkUseNewNoviceFeatures() then
            view = util_createView("newQuestNewCode.QuestNew.QuestNewNewUserLoginView", callback)
        end
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

-- 显示结束弹板
function QuestNewManager:showOverLayer(callback, isCompleted)
    local view = gLobalViewManager:getViewByName("QuestNewNewUserClose")
    if not view then
        if isCompleted and globalData.GameConfig:checkUseNewNoviceFeatures() then
            --[[ 2023年06月14日14:20:02
                cxc 新手quest完成 功能解锁弹板不显示： 直接走重登
            ]]
            self:questNoviceOverRestartGame()
            -- view = util_createView("newQuestNewCode.QuestNew.QuestNewNewUserCloseViewNew")
        else
            view =
                util_createView(
                "newQuestNewCode.QuestNew.QuestNewNewUserCloseView",
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
            view:setName("QuestNewNewUserClose")
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end

    return view
end
function QuestNewManager:questNoviceOverRestartGame()
    globalData.userRunData:saveLeveToLobbyRestartInfo()
    if globalData.slotRunData.isPortrait == true then
        globalData.slotRunData.isChangeScreenOrientation = true
        globalData.slotRunData:changeScreenOrientation(false)
    end

    gLobalDataManager:setBoolByField("QuestUlkLobbyBtmGuide", true)
    util_restartGame()
end
function QuestNewManager:checkQuestUlkLobbyBtmGuide()
    local bNeedGuide = gLobalDataManager:getBoolByField("QuestUlkLobbyBtmGuide", false)
    return bNeedGuide
end

--进入关卡显示任务界面
function QuestNewManager:showEnterLayer()
    local uiView = util_createFindView(QUESTNEW_CODE_PATH.QuestNewEnterLayer)
    if uiView ~= nil then
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "Push", DotUrlType.UrlName, true, DotEntrySite.LeftView, DotEntryType.Game)
        end
        self:showLayer(uiView, ViewZorder.ZORDER_UI)
    end
end





------------------------------------------任务相关------------------------------------------------

--关卡中判断是否完成任务  需要弹出完成一个任务弹窗  需要弹窗全部任务完成弹窗
function QuestNewManager:isCurrentStageTaskTipState()
    local quest_data = self:getRunningData()
    if not quest_data or not quest_data:isEnterGameFromQuest() then
        return false,false
    end
    local pointData =  quest_data:getEnterGamePointData()
    if pointData then
        local willShowOneTaskTip , willShowAllTaskTip = pointData:getTipState()
        if willShowOneTaskTip then
            pointData:clearOneTipState()
        end
        if willShowAllTaskTip then
            pointData:clearAllTipState()
        end
        return willShowOneTaskTip , willShowAllTaskTip
    end
    return false,false
end

--显示任务完成界面
function QuestNewManager:showTaskDoneView()
    if gLobalViewManager:getViewByExtendData("QuestNewTaskDoneLayer") ~= nil then
        return
    end
    if not self.m_showTaskDoneTipType then
        return
    end
    local quest_data = self:getRunningData()
    if not quest_data then
        return
    end

    local data = {type = self.m_showTaskDoneTipType}

    local tipView = util_createFindView(QUESTNEW_CODE_PATH.QuestNewTaskDoneTipLayer,data)
    if tipView ~= nil then
        -- if gLobalSendDataManager.getLogPopub then
        --     gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "Push", DotUrlType.UrlName, true, DotEntrySite.LeftView, DotEntryType.Game)
        -- end
        self:showLayer(tipView, ViewZorder.ZORDER_UI)
    else
        util_sendToSplunkMsg("QuestNewManager--QuestTaskDone", "创建界面失败 没有资源")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
    end
    return tipView
end


------------------------------------------任务相关------------------------------------------------

--是否需要弹出选择难度
function QuestNewManager:IsNeedShowDifficultyView(phase)
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

--显示选择难度
function QuestNewManager:showDifficultyView()
    local diffView = gLobalViewManager:getViewByExtendData("QuestNewDifficultyLayer")
    if diffView then
        -- 界面已存在
        return
    end

    --请求quest关卡难度+奖励
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_ACTIVITY_QUEST_PHASEREWARD)

            local uiView = util_createFindView(QUESTNEW_CODE_PATH.QuestNewDifficultyLayer) 
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
    gLobalSendDataManager:getNetWorkFeature():sendActionQuestNewPhaseReward()
end

--显示下一章节
function QuestNewManager:showNextPhase()
    --请求quest关卡难度+奖励
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_ACTIVITY_QUEST_PHASEREWARD)
            -- 抛出消息 过度到下一章节
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_PHASEREWARD
    )
    gLobalSendDataManager:getNetWorkFeature():sendActionQuestNewPhaseReward()
end

--打开排行榜
function QuestNewManager:showRankView(clickName)
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", clickName)
    local uiView = util_createFindView(QUESTNEW_CODE_PATH.QuestNewRankLayer)
    if uiView ~= nil then
        if gLobalSendDataManager.getLogPopub then
           -- gLobalSendDataManager:getLogPopub():addNodeDot(uiView, clickName, DotUrlType.UrlName, false)
        end
        self:setWillAutoShowRankLayer(false)
        self:showLayer(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end

----刷新假钱
function QuestNewManager:checkShowFalseCoins()
    local questConfig = self:getRunningData()
    --宝箱的为准
    if questConfig.m_lastBoxCoins then
        --刷新假钱
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, questConfig.m_lastBoxCoins)
        questConfig.m_lastBoxCoins = nil
    end
end

--完成quest关卡后弹窗
function QuestNewManager:checkShowFinishView(updateCellFunc)
    local infoList = {}
    --弹窗
    return self:checkShowView(infoList, updateCellFunc)
end

--进入quest弹窗
function QuestNewManager:checkShowEnterView(updateCellFunc)
    local questConfig = self:getRunningData()
    if not questConfig then
        return false
    end
    local infoList = {}
    --展示排行榜
    if self:isWillAutoShowRankLayer() then
        G_GetMgr(ACTIVITY_REF.QuestNew):setWillAutoShowRankLayer(false)
        infoList[#infoList + 1] = {path = QUESTNEW_CODE_PATH.QuestNewRankLayer}
    end
    -- questRush活动
    local entrySite = gLobalSendDataManager:getLogQuestNewActivity():getQuestNewEntrySite()
    if entrySite ~= "gameBackLobby" then
        infoList[#infoList + 1] = {func = handler(self, self.showQuestNewRushPanel)}
    end
    --弹窗
    return self:checkShowView(infoList, updateCellFunc)
end

--展示一系列弹窗
function QuestNewManager:checkShowView(infoList, updateCellFunc)
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
function QuestNewManager:showViewNext()
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
function QuestNewManager:setShowViewCallBack(func)
    self.m_showViewFunc = func
end

--完成弹窗
function QuestNewManager:showViewFinish()
    self.m_showViewList:clear()
    if self.m_showViewCount > 0 and self.m_showViewFunc then
        self.m_showViewFunc()
        self.m_showViewFunc = nil
    end
    self.m_showViewCount = -1
end

-- 显示quest挑战活动面板
function QuestNewManager:showQuestNewRushPanel(_cb)
    G_GetMgr(ACTIVITY_REF.QuestNewRush):showMainView(_cb)
end

--制作点击区域
function QuestNewManager:makeTouch(size, btnName)
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
    touch:setBackGroundColorOpacity(100)
    return touch
end

--拷贝到对应主题的资源目录中
function QuestNewManager:writeQuestNewMapConfig(path)
    --读取地图配置csb
    local test = util_createAnimation(path)
    --初始化数据
    local data = {}

    --地图关卡获取
    local nodeCell = test:findChild("node_cell")
    local childs1 = nodeCell:getChildren()
    data.cell = {}
    for i = 1, #childs1 do
        data.cell[i] = cc.p(childs1[i]:getPosition())
    end

    --地图连线获取
    local nodeDian = test:findChild("node_dian")
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

    --地图宝箱获取
    local nodeBox = test:findChild("Node_box")
    local childs4 = nodeBox:getChildren()
    data.Box = {}
    local boxPos = cc.p(nodeBox:getPosition())
    for i = 1, #childs4 do
        data.Box[i] = ccpAdd(boxPos, cc.p(childs4[i]:getPosition()))
    end

    --写入json文件
    local jsonData = cjson.encode(data)
    local path = device.writablePath .. "questMapConfig.json"
    local file = io.open(path, "wb+")
    file:write(jsonData)
    file:flush()
    file:close()
end

-- 获得折扣
function QuestNewManager:getDiscount()
    local _data = self:getRunningData()
    if _data then
        return _data:getDiscount()
    else
        return 0
    end
end

function QuestNewManager:getRewardVipBoostItem(_rewardData)
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

function QuestNewManager:isCanShowHall()
    if self:isNewUserQuestNew() then
        return false
    else
        return QuestNewManager.super.isCanShowHall(self)
    end
end

function QuestNewManager:isCanShowSlide()
    if self:isNewUserQuestNew() then
        return false
    else
        return QuestNewManager.super.isCanShowSlide(self)
    end
end

function QuestNewManager:isCanShowInEntrance()
    if self:isNewUserQuestNew() then
        return false
    end
    return QuestNewManager.super.isCanShowInEntrance(self)
end

function QuestNewManager:getIsShowTaskDoneTip()
    return self.m_isShowTaskDoneTip
end

function QuestNewManager:setIsShowTaskDoneTip(_flag,type)
    self.m_isShowTaskDoneTip = _flag
    if type then
        self.m_showTaskDoneTipType = type
    end
end

-- 完成关卡时 记录章节信息 用于和服务器数据做对比 表现完成动画
function QuestNewManager:recordStageInfo()
    local record_datas = {}

    local quest_data = self:getRunningData()
    if quest_data then
        record_datas.phaseIdx = quest_data:getPhaseIdx()
        record_datas.stageIdx = quest_data:getStageIdx()
        record_datas.phase_data = clone(quest_data:getPhaseData(record_datas.phaseIdx))
        local stage_data = record_datas.phase_data.p_stages[record_datas.stageIdx]
        -- 用于通关时 校正最后一关的状态
        if stage_data then
            stage_data.p_status = "COMPLETE"
        end
        self.record_datas = record_datas
    end
end

function QuestNewManager:getRecordStageInfo()
    -- test
    --self.record_datas.phaseIdx = 1
    --self.record_datas.stageIdx = 1
    --local quest_data = self:getRunningData()
    --self.record_datas.phase_data = clone(quest_data:getPhaseData(record_datas.phaseIdx))
    --self.record_datas.phase_data.p_pickChips = self.record_datas.phase_data.p_maxChips
    --self.record_datas.phase_data.p_status = "FINISHED"

    return self.record_datas
end

function QuestNewManager:clearRecordStageInfo()
    self.record_datas = nil
end

function QuestNewManager:clearRecordJackpot()
    local quest_data = self:getRunningData()
    if quest_data then
        quest_data.m_lastBoxJackpot = nil
    end
end

function QuestNewManager:willShowEnded()
    if self:isRunning() then
        self.bl_showEnded = false
    elseif self.bl_showEnded == false then
        self.bl_showEnded = nil
        return true
    end
    return false
end

------------------------------------------记录的一堆状态值------------------------------------------------


--- 进入quest大厅
function QuestNewManager:isEnterQuestLayer()
    if self.m_isQuestLayer == nil then
        self.m_isQuestLayer = false
    end
    return self.m_isQuestLayer
end
function QuestNewManager:setIsEnterQuestLayer(isQuestLayer)
    self.m_isQuestLayer = isQuestLayer
end

--- 普通关卡点击进入quest
function QuestNewManager:isLevelEnterQuest()
    if self.m_isLevelEnterQuest == nil then
        self.m_isLevelEnterQuest= false
    end
    return self.m_isLevelEnterQuest
end
function QuestNewManager:setIsLevelEnterQuest(isLevelEnterQuest)
    self.m_isLevelEnterQuest = isLevelEnterQuest
end


function QuestNewManager:setCurrentCompletedPointChapterIdAndPointId(chapterId,pointId)
    self.m_currentCompletePointChapterId = chapterId
    self.m_currentCompletePointPointId = pointId
end

function QuestNewManager:checkNeedDoCompletedActForPoint(pointData)
    if not self.m_currentCompletePointChapterId then
        self.m_currentCompletePointChapterId = 0
    end
    if not self.m_currentCompletePointPointId then
        self.m_currentCompletePointPointId = 0
    end

    if pointData.p_chapterId == self.m_currentCompletePointChapterId 
        and pointData.p_id == self.m_currentCompletePointPointId then
        return true
    end
    return false
end

-- 关卡地图中自动展示排行榜界面
function QuestNewManager:setWillAutoShowRankLayer(willAutoShow)
    self.m_willAutoShowRankLayer = willAutoShow
end

function QuestNewManager:isWillAutoShowRankLayer()
    return not not self.m_willAutoShowRankLayer
end


-- 关卡地图中自动展示Rush界面
function QuestNewManager:setWillAutoShowRushLayer(willAutoShow)
    self.m_willAutoShowRushLayer = willAutoShow
end

function QuestNewManager:isWillAutoShowRushLayer()
    return not not self.m_willAutoShowRushLayer
end

--地图界面检测中
function QuestNewManager:setDoingMapCheckLogic(isDoing)
    self.m_doingMapCheckLogic = isDoing
end

function QuestNewManager:isDoingMapCheckLogic()
    return not not self.m_doingMapCheckLogic
end

----------------------------------------------------------------------------------

function QuestNewManager:getAllChapterData()
    local _data = self:getRunningData()
    if _data then
        return _data:getALlChapter()
    end
    return nil
end

function QuestNewManager:getALLPointDataByChapterId(chapterId)
    local _data = self:getRunningData()
    if _data then
        return _data:getALLPointDataByChapterId(chapterId)
    end
    return nil
end

function QuestNewManager:getPointDataByChapterIdAndIndex(chapterId,index)
    local activityData = self:getRunningData()
    return  activityData:getPointDataByChapterIdAndIndex(chapterId,index)
end

function QuestNewManager:getCurrentChapter()
    local _data = self:getRunningData()
    if _data then
        return _data:getCurrentChapterID()
    end
    return 1
end

function QuestNewManager:getShowStarPointInChapter(chapterId)
    return  1
end

function QuestNewManager:getChapterDataByChapterId(chapterId)
    local activityData = self:getRunningData()
    if activityData then
        return activityData:getChapterDataByChapterId(chapterId)
    end
    return nil
end

function QuestNewManager:getCurrentChapterData()
    return self:getChapterDataByChapterId(self:getCurrentChapter())
end


function QuestNewManager:getChapterStarPrizesData(chapterId,forBefore)
    local chapterData = self:getChapterDataByChapterId(chapterId)
    if chapterData then
        return chapterData:getStarMeters(forBefore)
    end
    return {}
end

function QuestNewManager:resetChapterStarPrizesRememberData(chapterId)
    local chapterData = self:getChapterDataByChapterId(chapterId)
    if chapterData then
        return chapterData:resetCurrentChapterStarPrizesRememberData()
    end
end

-- 获得本章节已得星星数
function QuestNewManager:getChapterPickStars(chapterId,forBefore)
    local chapterData = self:getChapterDataByChapterId(chapterId)
    if chapterData then
        return chapterData:getPickStars(forBefore),chapterData:getMaxStars()
    end
    return 0,10000
end

function QuestNewManager:getChapterWheelDataByChapterId(chapterId)
    local chapterData = self:getChapterDataByChapterId(chapterId)
    if chapterData then
        return chapterData:getWheelData()
    end
    return nil
end

function QuestNewManager:getCurrentChapterWheelData()
    local chapterData = self:getCurrentChapterData()
    if chapterData then
        return chapterData:getWheelData()
    end
    return nil
end

function QuestNewManager:getEnterGamePointData()
    local quest_data = self:getRunningData()
    if  quest_data then
        return quest_data:getEnterGamePointData()
    end
    return nil
end
function QuestNewManager:getEnterGamePointNextData()
    local quest_data = self:getRunningData()
    if  quest_data then
        return quest_data:getEnterGamePointNextData()
    end
    return nil
end

function QuestNewManager:setForceInitChapter(doForce)
    local quest_data = self:getRunningData()
    if  quest_data then
        quest_data:setForceInitChapter(doForce)
    end
end

---------------------------------------------------关卡相关------------------------------------------------
function QuestNewManager:isEnterGameFromQuest()
    local activityData = self:getRunningData()
    if activityData then
        return activityData:isEnterGameFromQuest()
    end
    return false
end

function QuestNewManager:setEnterGameFromQuest(isFrom)
    local activityData = self:getRunningData()
    if activityData then
        activityData:setEnterGameFromQuest(isFrom)
    end
end

function QuestNewManager:clearEnterGameFromQuest()
    self:setEnterGameFromQuest(false)
end

function QuestNewManager:setEnterQuestFromGame(isFrom)
    local activityData = self:getRunningData()
    if activityData then
        activityData:setEnterQuestFromGame(isFrom)
    end
end

function QuestNewManager:setEnterGameChapterIdAndPointId(chapterId,pointId)
    local activityData = self:getRunningData()
    if activityData then
        activityData:setEnterGameChapterIdAndPointId(chapterId,pointId)
    end
end

function QuestNewManager:getEnterGameChapterIdAndPointId()
    local activityData = self:getRunningData()
    if activityData then
        return activityData:getEnterGameChapterIdAndPointId()
    end
    return 1,1
end

------------------------------------------Quest 转轮奖池逻辑------------------------------------------------

-- 1 minor  2 major  3 grand
function QuestNewManager:updateQuestGoldIncrease(forceInit,data)
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
function QuestNewManager:getRuningGoldByType(type)
    local activityData = self:getRunningData()
    if activityData then
        return activityData:getRunGoldCoinByType(type)
    end
    return 111111111,false
end


function QuestNewManager:getGianCoinsNameByType(type)
    return "somebody"
end




-----------------------------------------------网络协议相关-----------------------------------------------------------

-- 请求fantasyQuest排行版信息
function QuestNewManager:requestQuestRank()
    self.m_net:requestQuestRank()
end

function QuestNewManager:requestCollectGift(chapterId,stageId)
    self.m_net:requestCollectGift(chapterId,stageId)
end

function QuestNewManager:requestCollectStarMeter(chapterId)
    self.m_net:requestCollectStarMeter(chapterId)
end

function QuestNewManager:requestGetPool(isFirstEnter)
    local quest_data = self:getRunningData()
    if not quest_data then
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
    self.m_net:requestGetPool()
end

function QuestNewManager:clearRequestGetPool()
    self.m_requestGetPool = false
end

function QuestNewManager:requestPlayWheel()
    self.m_net:requestPlayWheel()
end

function QuestNewManager:requestCollectWheelReward()
    self:setStopPoolRun(true)
    self.m_net:requestCollectWheelReward()
end

function QuestNewManager:setStopPoolRun(isStop)
    self.m_stopPoolRun = isStop
end

function QuestNewManager:isStopPoolRun()
    return not not self.m_stopPoolRun
end

function QuestNewManager:doQuestNextRound()
    if self.m_isQuestNextRound then
        return
    end
    self.m_isQuestNextRound = true
    self:setForceInitChapter(true)
    self.m_net:doQuestNextRound()
end

function QuestNewManager:isQuestNextRound()
    return self.m_isQuestNextRound
end

function QuestNewManager:clearQuestNextRound()
    self.m_isQuestNextRound = false
end

function QuestNewManager:doQuestBySaleUseGem(gemIndex)
    self.m_net:doQuestBySaleUseGem(gemIndex)
end

function QuestNewManager:checkFirstEnterChapter(chapterId)
    local themeName = self:getThemeName()
    local result = false
    local strData = gLobalDataManager:getStringByField("QuestNewEnterChapter", "")
    if strData == "" then
        result = true
    else
        local strs = string.split(strData, "|")
        if strs[1] == themeName then
            result = tonumber(strs[2]) < chapterId
        else
            result = true
        end
    end
    if result then
        gLobalDataManager:setStringByField("QuestNewEnterChapter", themeName.. "|" ..chapterId)
    end
    return result
end

---------------------------------新手相关-----------------华丽的分割线-----------------
function QuestNewManager:canDoChapterGuide()
    local activityData = self:getRunningData()
    if not activityData then
        return false
    end
    if not activityData:isHasReset() then
        return false
    end
    return self.m_guide:canDoChapterGuide()
end

function QuestNewManager:saveGuideOver()
    self.m_guide:saveGuideOver()
end

function QuestNewManager:isInGuide()
    return not not G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():getGuideMaskLayer()
end

return QuestNewManager
