--
local LoadingControl = require("views.loading.LoadingControl")
local ViewManager = class("ViewManager")
local LuaList = require("common.LuaList")

GD.SceneType = {
    Scene_Logon = 1, -- 登录
    Scene_Lobby = 2, -- 大厅
    Scene_Game = 3, -- 游戏 slots
    Scene_Quest = 4,
    Scene_LAUNCH = 5, -- 进入大厅或游戏时的 loading 界面
    Scene_CoinPusher = 6, -- CoinPusher场景
    Scene_BeerPlinko = 7, -- BeerPlinko场景
    Scene_NewCoinPusher = 8, -- NewCoinPusher场景
    Scene_EgyptCoinPusher = 9, -- 埃及CoinPusher场景
}
-- 特殊slot机器类型
GD.SpecialMachine = {
    [1] = "PhysicsScene"
}

GD.ViewZorder = {
    -- 游戏轮盘逻辑弹版都是默认值0 例如fsstart over弹版 respin bigewin unlock uplevel等
    ZORDER_GAMEUI = 0,
    ZORDER_FLOAT_VIEW = 45,
    -- slots系统相关弹板
    ZORDER_GAMEPOP = 500,
    -- 系统UI弹版 例如邮件商店小猪银行任务等
    ZORDER_UI_LOWER = 999, -- 适应显示在活动弹板之下的需求
    ZORDER_UI = 1000,
    ZORDER_UI_UPPER = 1001, -- 适应大活动场景切换遮罩
    -- 活动相关弹板 关卡中会跟关卡本身弹窗相互重叠，重新定义了一个层级
    ZORDER_POPUI = 1200,
    -- 引导UI
    ZORDER_GUIDE = 2000,
    -- 特殊层级 顶部层级 飞金币飞特效等
    ZORDER_SPECIAL = 10000,
    -- loadign层级 加载网络时的loading遮罩
    ZORDER_LOADING = 20000,
    -- 网络层级 提示性弹窗 例如登录失败 网络连接失败
    ZORDER_NETWORK = 30000
}

ViewManager.m_instance = nil
ViewManager.m_currentScene = nil -- 当前场景
ViewManager.p_ViewLayer = nil --  显示UI 使用的层

ViewManager.m_viewPool = nil --
ViewManager.m_isResumeStatus = nil --促销闪退问题

--p_ViewLayer child 类型
local ViewType = {
    TYPE_UI = 100 --UI弹窗tag
}

ViewManager.m_captureScreenFile = "testViewPause.png"
ViewManager.m_outputFile = nil
function ViewManager:getInstance()
    if ViewManager.m_instance == nil then
        ViewManager.m_instance = ViewManager.new()
    end
    return ViewManager.m_instance
end

function ViewManager:ctor()
    self.m_currentScene = SceneType.Scene_Logon
    self.m_viewPool = {}
    self.p_ViewLayer = cc.Layer:create()
    self.p_ViewLayer:retain()
    -- self.m_triggerFuncList = LuaList.new()
    -- self.m_triggerFuncCount = -1
    self.transitionSceneFlag = false
    self.m_triggerQueueList = {}
end

function ViewManager:getViewLayer()
    if tolua.isnull(self.p_ViewLayer) then
        self.p_ViewLayer = cc.Layer:create()
        self.p_ViewLayer:retain()
    end

    return self.p_ViewLayer
end

function ViewManager:removeViewLayerFromParent(...)
    if not tolua.isnull(self.p_ViewLayer) then
        self.p_ViewLayer:removeAllChildren()
        if self.p_ViewLayer:getParent() then
            self.p_ViewLayer:removeFromParent(...)
        end
    end
end

function ViewManager:releaseViewLayer()
    self:removeViewLayerFromParent(true)
    if not tolua.isnull(self.p_ViewLayer) then
        self.p_ViewLayer:release()
        self.p_ViewLayer = nil
    end
end

function ViewManager:getSceneMainLayer()
    local runningScene = display.getRunningScene()
    if tolua.isnull(runningScene) then
        return nil
    end
    return runningScene:getChildByName("SceneMainLayer")
end

function ViewManager:isLevelView()
    return self.m_currentScene == SceneType.Scene_Game
end

function ViewManager:isLobbyView()
    return self.m_currentScene == SceneType.Scene_Lobby
end

function ViewManager:isLogonView()
    return self.m_currentScene == SceneType.Scene_Logon
end

function ViewManager:isLoadingView()
    return self.m_currentScene == SceneType.Scene_LAUNCH
end

function ViewManager:isCoinPusherScene(_scene)
    local scene = _scene or self.m_currentScene
    return scene == SceneType.Scene_CoinPusher or scene == SceneType.Scene_NewCoinPusher or scene == SceneType.Scene_EgyptCoinPusher
end

function ViewManager:isBeerPlinkoScene()
    return self.m_currentScene == SceneType.Scene_BeerPlinko
end

function ViewManager:getCurSceneType()
    return self.m_currentScene
end

function ViewManager:pushView(sceneType)
end

function ViewManager:isPhysicsScene(_scene)
    local scene = _scene or self.m_currentScene
    return scene == SceneType.Scene_CoinPusher or scene == SceneType.Scene_NewCoinPusher or scene == SceneType.Scene_EgyptCoinPusher or scene == SceneType.Scene_BeerPlinko
end

--清理游戏状态 是否在高倍场中 是否在quest中
function ViewManager:clearGameStatus()
    -- globalData.slotRunData.isDeluexeClub = false -- cxc 2021-01-14 03:01:38不用清理高倍场状态(钻石挑战里高倍场跳高倍场)
    globalData.deluexeHall = false
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig and questConfig.class.m_IsQuestLogin then
        questConfig.class.m_IsQuestLogin = false
    end
    G_GetMgr(ACTIVITY_REF.QuestNew):clearEnterGameFromQuest()
end

-- 大厅和(BeerPlinko) 进入 关卡
function ViewManager:lobbyGotoGameScene(_id)
    if not _id or (self.m_currentScene ~= SceneType.Scene_Lobby and self.m_currentScene ~= SceneType.Scene_BeerPlinko) then
        return
    end

    --根据app版本检测关卡是否可以进入
    -- if not self:checkEnterLevelForApp(_id) then
    --     self:showUpgradeAppView()
    --     return
    -- end

    local info = globalData.slotRunData:getLevelInfoById(_id)
    if not info then
        return
    end

    return self:gotoSlotsScene(info)
end

-- 进入关卡
function ViewManager:gotoSlotsScene(info, siteType, lastBetIdx ,gameType)
    if not info then
        return 
    end

    --根据app版本检测关卡是否可以进入
    if not self:checkEnterLevelForApp(info.p_id) then
        self:showUpgradeAppView()
        return false
    end

    --横竖屏
    if info.p_portraitFlag ~= globalData.slotRunData.isPortrait then
        globalData.slotRunData.isChangeScreenOrientation = true
        globalData.slotRunData:changeScreenOrientation(info.p_portraitFlag)
    end
    globalData.slotRunData.isDeluexeClub = info.p_highBetFlag
    --高倍场没有值所以特殊处理
    globalData.slotRunData.iLastBetIdx = lastBetIdx or -1 
    -- if info.p_recommendBets ~= nil and #info.p_recommendBets > 0 then
    --     globalData.slotRunData.iLastBetIdx = info.p_recommendBets[1].p_betId
    -- else
    --     globalData.slotRunData.iLastBetIdx = -1 --高倍场没有值所以特殊处理
    -- end
    gLobalSendDataManager:getLogSlots():initSlotLog(info)
    gLobalSendDataManager:getLogIap():setEntryGame(info.p_name)
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.EnterTheme)
    end
    if gameType then
        gLobalSendDataManager:getLogSlots():setEnterLevelGameType(gameType)
    end
    gLobalActivityManager:checkAddNewLevelCount(info.p_id)

    if siteType then
        gLobalSendDataManager:getLogSlots():setEnterLevelSiteType(siteType)
    end
    gLobalSendDataManager:getLogSlots():setEnterLevelName(info.p_levelName, info.p_name)

    globalData.slotRunData.nextMachineData = info

    self:gotoSceneByType(SceneType.Scene_Game)

    return true
end

--关卡中跳转到下一关
function ViewManager:gotoSceneByLevelId(id)
    --找不到id
    if not id then
        return
    end
    --不是关卡中跳转
    if self.m_currentScene ~= SceneType.Scene_Game then
        return
    end

    --根据app版本检测关卡是否可以进入
    -- if not self:checkEnterLevelForApp(id) then
    --     self:showUpgradeAppView()
    --     return
    -- end

    --赚不到关卡配置
    if not globalData.slotRunData.machineData then
        return
    end
    local info = globalData.slotRunData:getLevelInfoById(id)
    if not info then
        return
    end

    self:clearGameStatus() --清理quest高倍场状态

    local lastBetIdx = -1
    if info.p_recommendBets ~= nil and #info.p_recommendBets > 0 then
        lastBetIdx = info.p_recommendBets[1].p_betId
    end
    return self:gotoSlotsScene(info, globalData.slotRunData.machineData.p_name, lastBetIdx)
end
--loading中返回大厅
function ViewManager:gotoLobbyByLunch()
    self.m_currentScene = SceneType.Scene_Game
    release_print("LaunchScene back to lobby!!!")
    self:gotoSceneByType(SceneType.Scene_Lobby)
end

function ViewManager:addLoadingSceneBlock()
    local layer = cc.Layer:create()
    layer:onTouch(
        function()
            return true
        end,
        false,
        true
    )
    local runningScene = display:getRunningScene()
    runningScene:addChild(layer, ViewZorder.ZORDER_LOADING)
    layer:setName("LoadingSceneBlockLayer")
    return layer
end

function ViewManager:gotoSceneByType(sceneType, callback)
    self:addLoadingSceneBlock()

    if sceneType then
        local strType = tostring(sceneType)
        release_print("---------------------gotoSceneByType = " .. strType)
        if self.m_currentScene == sceneType and sceneType == SceneType.Scene_Lobby then
            -- 大厅不能跳大厅
            util_sendToSplunkMsg("gotoLobby", "lobby scene go to lobby!!!")
            return
        end
    end
    -- 跳转场景 中断触发弹窗逻辑
    -- gLobalTriggerManager:setTriggerEndFunc(nil)
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TRIGGER_END)
    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER, true) --弹窗逻辑执行结束回调 flag 是否不执行结束回调
    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    if globalNoviceGuideManager then
        globalNoviceGuideManager:clearGuide()
    end
    if G_GetMgr(ACTIVITY_REF.Quest) then
        G_GetMgr(ACTIVITY_REF.Quest):clearData()
    end
    local pigBankMgr = G_GetMgr(G_REF.PiggyBank)
    if pigBankMgr then
        local bubble = pigBankMgr:getBubbleCtr()
        if bubble and bubble.clearData then
            bubble:clearData()
        end
    end
    gLobalAdsControl:removeAdTimerHandler()
    globalData.slotRunData.m_autoNum = 0
    globalData.slotRunData.m_isAutoSpinAction = false
    self:triggerFuncClear()
    --跳转场景调用一下退出集卡系统
    if CardSysManager and CardSysManager.exitCard then
        CardSysManager:exitCard()
    end
    local FlameClashMgr  = G_GetMgr(ACTIVITY_REF.FrostFlameClash)
    if FlameClashMgr and FlameClashMgr:getRunningData() and sceneType == SceneType.Scene_Game then
        FlameClashMgr:requestRefreshFrostFlameClashInfo(true)
    end

    local sceneLayer = nil
    if sceneType == SceneType.Scene_Lobby or sceneType == SceneType.Scene_Logon or sceneType == SceneType.Scene_BeerPlinko then
        if self:isCoinPusherScene(sceneType) then
            globalData.slotRunData.isChangeScreenOrientation = true
        else
            -- elseif self.m_currentScene == SceneType.Scene_Game or self.m_currentScene == SceneType.Scene_LAUNCH then
            if globalData.slotRunData.isPortrait == true then
                globalData.slotRunData.isChangeScreenOrientation = true
                globalData.slotRunData:changeScreenOrientation(false)
            end
        end
    elseif self:isCoinPusherScene(sceneType) then
        if globalData.slotRunData.isPortrait ~= true then
            globalData.slotRunData.isChangeScreenOrientation = true
            -- 切换为竖屏
            globalData.slotRunData:changeScreenOrientation(true)
        end
    end

    if self.m_currentScene == SceneType.Scene_Game or self:isCoinPusherScene() then
        if globalMachineController.clearSystemUICor then
            globalMachineController:clearSystemUICor()
        end
    end

    release_print("---------------------currentScene = " .. tostring(self.m_currentScene))
    release_print("---------------------gotoSceneByType = " .. tostring(sceneType))
    RotateScreen:getInstance():initScreenDir()

    if sceneType == SceneType.Scene_Logon then
        -- 游戏切换到登陆默认是重启
        LoadingControl:getInstance():resetLoading()
        sceneLayer = util_createView("views.logon.LogonLoading", {isRestartGame = true})
        if not sceneLayer then
            util_sendToSplunkMsg("gotoLogin", "sceneLayer is nil!!")
        end
        self:changeScene(sceneType, sceneLayer, callback)
    else
        local launchLayer = self:checkShowLaunchLayer(sceneType)
        if launchLayer == nil then
            -- 表明从logon 界面进入到大厅
            if sceneType == SceneType.Scene_Lobby then
                self:logonToLobby(sceneType, callback)
            end
        else
            LoadingControl:getInstance():initLoadingData({curScene = self.m_currentScene, nextScene = sceneType})
            local callFunc = function()
                if callback then
                    callback()
                end
                LoadingControl:getInstance():startLoading()
            end
            if sceneType == SceneType.Scene_Lobby or sceneType == SceneType.Scene_Game or sceneType == SceneType.Scene_BeerPlinko or self:isCoinPusherScene(sceneType) then
                if self.m_currentScene == SceneType.Scene_Game then
                    --游戏返回到大厅
                    -- local levelName = globalData.slotRunData.machineData.p_levelName
                    gLobalSendDataManager:getLogIap():setEntryType("lobby")
                    local battleMatchManager = G_GetMgr(ACTIVITY_REF.BattleMatch)
                    if battleMatchManager then
                        battleMatchManager:clearCompareData()
                    end
                end

                release_print("---------------------currentScene2 = " .. tostring(self.m_currentScene))

                sceneType = SceneType.Scene_LAUNCH
                self:changeScene(sceneType, launchLayer, callFunc)
            end
        end
    end
end

--登录到大厅
function ViewManager:logonToLobby(sceneType, callback)
    -- 登录 到 大厅检查下需要显示什么类型 大厅
    G_GetMgr(G_REF.NewUserExpand):checkUpdateLobbyStyle()
    gLobalSendDataManager:getLogIap():setEntryType("lobby")
    local startTime = xcyy.SlotsUtil:getMilliSeconds()
    local sceneLayer = util_createView("views.lobby.LobbyView", true)
    sceneLayer:retain()
    local preLoadLobbyNodes = sceneLayer:getPreLoadLobbyNodes()

    if preLoadLobbyNodes ~= nil and #preLoadLobbyNodes > 0 then
        local count = #preLoadLobbyNodes
        local actUpdate
        actUpdate =
            schedule(
            display.getRunningScene(),
            function()
                if preLoadLobbyNodes ~= nil and #preLoadLobbyNodes > 0 then
                    local preSlotInfo = preLoadLobbyNodes[1]
                    local index = (count - #preLoadLobbyNodes + 1)
                    table.remove(preLoadLobbyNodes, 1)
                    sceneLayer:preLoadLobbyNode(index, preSlotInfo)
                else
                    actUpdate:stop()
                    local extra = {}
                    if gLobalSendDataManager:getIsFbLogin() then
                        extra.logonWay = "Facebook"
                    else
                        extra.logonWay = "Guest"
                    end

                    self:changeScene(sceneType, sceneLayer, callback)
                    sceneLayer:release()
                end
            end,
            0.05
        )
    else
        -- if sceneLayer.freshLevelNode then
        --     sceneLayer:freshLevelNode("LoginLobby")
        -- end

        self:changeScene(sceneType, sceneLayer, callback)
        sceneLayer:release()
    end
end

local sceneIndex = 0
local PARAMS_EMPTY = {}
function ViewManager:newScene(name, params)
    params = params or PARAMS_EMPTY
    sceneIndex = sceneIndex + 1
    local scene
    if not BaseScene then
        BaseScene = require("base.BaseScene")
    end
    scene = BaseScene:create(params.physics)
    scene.name_ = string.format("%s:%d", name or "<unknown-scene>", sceneIndex)

    if params.transition then
        scene = display.wrapSceneWithTransition(scene, params.transition, params.time, params.more)
    end

    return scene
end

function ViewManager:createScence(_sceneType)
    local pScene = nil

    -- 活动为物理场景
    if self:isPhysicsScene(_sceneType) then
        pScene = self:newScene(_sceneType, {physics = true})
    else
        if _sceneType == SceneType.Scene_Game then
            local machineData = globalData.slotRunData:getLastEnterLevelInfo()
            local sepcialGameType = machineData.p_sepcialGameType
            if sepcialGameType then
                local specialGame = SpecialMachine[sepcialGameType]
                pScene = self:newScene(_sceneType, {physics = true})

                local phyWorld = pScene:getPhysicsWorld()
                if phyWorld then
                    phyWorld:setAutoStep(false)
                end
            else
                pScene = self:newScene(_sceneType)
            end
        else
            pScene = self:newScene(_sceneType)
        end
    end
    pScene:setName("name--" .. _sceneType)
    return pScene
end
--[[
    @desc: 切换场景
    author: 徐袁
    time: 2021-05-20 14:36:30
    --@preSceneType: 上一个场景类型
    --@sceneType: 新进入的场景类型
    --@sceneLayer: 新的场景
    --@delayTime: 等待时间
    @return: 
]]
function ViewManager:transitionScene(preSceneType, sceneType, sceneLayer, callback, delayTime)
    if not self.transitionSceneFlag then
        local preScene = self.curScene
        local newScene = self:createScence(sceneType)
        self.curScene = newScene
        self.transitionSceneFlag = true

        if sceneLayer ~= nil then
            if sceneType ~= SceneType.Scene_LAUNCH then
                -- 非loading场景
                sceneLayer:setName("SceneMainLayer")
            end
            newScene:addChild(sceneLayer)
        end

        local function releaseCacheData()
            xcyy.SlotsUtil:releaseSpineCacheData()
            cc.Director:getInstance():purgeCachedData()
        end

        local transitionCallback = function()
            release_print("--------transition scene callback!!!")
            if callback then
                callback()
            end
            self.transitionSceneFlag = false
        end

        if delayTime ~= nil then
            release_print("--------transition scene FADE action!!!")
            self:runScene(newScene, "FADE", delayTime)
        else
            release_print("--------transition scene no action!!!")
            self:runScene(newScene)
        end

        -- if preScene ~= nil and sceneType == SceneType.Scene_LAUNCH then
        -- if (preSceneType ~= SceneType.Scene_Logon and preSceneType ~= SceneType.Scene_LAUNCH and preSceneType ~= self.m_currentScene) then
        if preScene ~= nil then
            local cleanupCallback = function()
                release_print("--------transition scene cleanup callback!!!")
                util_afterDrawCallBack(
                    function()
                        if (preSceneType ~= SceneType.Scene_Logon and preSceneType ~= SceneType.Scene_LAUNCH and preSceneType ~= self.m_currentScene) then
                            releaseCacheData()
                        end
                        transitionCallback()
                    end
                )
            end

            addCleanupListenerNode(preScene, cleanupCallback)
        else
            -- releaseCacheData()
            transitionCallback()
        end

    -- 监听切换场景成功事件
    -- local customEventDispatch = cc.Director:getInstance():getEventDispatcher()
    -- local _eventName = "director_after_set_next_scene"
    -- local listener =
    --     cc.EventListenerCustom:create(
    --     _eventName,
    --     function(event)
    --         local eventName = event:getEventName()
    --         customEventDispatch:removeCustomEventListeners(eventName)
    --         release_print("CustomEvent:removeEvent " .. eventName)

    --         if (preSceneType ~= SceneType.Scene_Logon and preSceneType ~= SceneType.Scene_LAUNCH and preSceneType ~= self.m_currentScene) then
    --             releaseCacheData()
    --         end

    --         transitionCallback()
    --     end
    -- )
    -- -- customEventDispatch:getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)
    -- customEventDispatch:addEventListenerWithSceneGraphPriority(listener, newScene)
    -- release_print("CustomEvent:addEvent " .. _eventName)
    end
end

---
-- 切换场景
--
function ViewManager:changeScene(sceneType, sceneLayer, callback)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local preSceneType = self.m_currentScene
    self.m_currentScene = sceneType
    if globalData.slotRunData.isChangeScreenOrientation == true or globalData.slotRunData.isChangeScreenOrientation == nil then
        globalData.slotRunData.isChangeScreenOrientation = false
        self:transitionScene(preSceneType, sceneType, sceneLayer, callback)
    elseif sceneType == SceneType.Scene_BeerPlinko then
        globalData.slotRunData.isChangeScreenOrientation = false
        self:transitionScene(preSceneType, sceneType, sceneLayer, callback)
    else
        local time = 0.4
        if sceneType == SceneType.Scene_Game then
            local machineData = globalData.slotRunData:getLastEnterLevelInfo()
            local sepcialGameType = machineData.p_sepcialGameType
            if sepcialGameType then
                local specialGame = SpecialMachine[sepcialGameType]
                if specialGame == SpecialMachine[1] then
                    time = nil
                end
            end
        elseif sceneType == SceneType.Scene_Lobby then
            -- 进入大厅 需要引导直接进入扩圈小游戏 不走 动画切场景
            local bIgnore = G_GetMgr(G_REF.NewUserExpand):checkIgnoreTransitionScene()
            if bIgnore then
                time = nil
            end
        end

        self:transitionScene(preSceneType, sceneType, sceneLayer, callback, time)
    end
end

--[[
    @desc: 检测是否需要显示 launch layer
    time:2018-07-04 20:17:10
    @return:
]]
function ViewManager:checkShowLaunchLayer(sceneType)
    -- if self.m_currentScene == SceneType.Scene_Logon or (sceneType == SceneType.Scene_CoinPusher) or (self.m_currentScene == SceneType.Scene_CoinPusher and sceneType == SceneType.Scene_Lobby) then
    --     return nil
    -- end

    local launchLayer = nil
    if (self.m_currentScene == SceneType.Scene_CoinPusher and sceneType ~= SceneType.Scene_Game) or sceneType == SceneType.Scene_CoinPusher then
        launchLayer = util_createView("Activity.CoinPusherGame.CoinPusherLoading")
    elseif (self.m_currentScene == SceneType.Scene_BeerPlinko and sceneType ~= SceneType.Scene_Game) or sceneType == SceneType.Scene_BeerPlinko then
        launchLayer = util_createView("ItemGame.PlinkoCode.loadingUI.PlinkoSceneLoading")
    elseif (self.m_currentScene == SceneType.Scene_NewCoinPusher and sceneType ~= SceneType.Scene_Game) or sceneType == SceneType.Scene_NewCoinPusher then
        launchLayer = util_createView("Activity.NewCoinPusherGame.NewCoinPusherLoading")
    elseif (self.m_currentScene == SceneType.Scene_EgyptCoinPusher and sceneType ~= SceneType.Scene_Game) or sceneType == SceneType.Scene_EgyptCoinPusher then
        launchLayer = util_createView("Activity.EgyptCoinPusherGame.EgyptCoinPusherLoading")
    elseif self.m_currentScene == SceneType.Scene_Game or sceneType == SceneType.Scene_Game then
        launchLayer = util_createView("views.loading.LoadingGameLayer", sceneType)
    end

    if launchLayer then
        launchLayer:setName("LoadingLayer")
    end

    return launchLayer
end

---
-- UI 处理函数
--
-- @param uiNode 显示的ui 节点
function ViewManager:showUI(uiNode, zorder, showTouchLayer)
    if tolua.isnull(uiNode) then
        -- 已经有父节点了
        local errMsg = "uiNode tolua isnull!!!"
        if DEBUG == 2 then
            assert(nil, errMsg)
        else
            release_print(errMsg)
            util_sendToSplunkMsg("showUIError", errMsg)
        end
        return
    end

    -- 重启中不显示UI
    if globalPlatformManager:isRebooting() then
        return
    end

    if showTouchLayer == nil then
        showTouchLayer = true
    end

    if showTouchLayer == true then
        local touchLayer = util_newMaskLayer()
        touchLayer:setOpacity(0)
        uiNode:addChild(touchLayer, -1000)
    end
    --日志系统  如果被标记过需要打日志  则有下面操作
    if uiNode.m_dotLog then
        uiNode.onHangExit = function()
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():removeUrlKey(uiNode.__cname)
            end
        end
        -- 界面名字  类型是url
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():pushUrlKey(uiNode.__cname, DotUrlType.ViewName, false)
        end
    end

    uiNode.m_showTouchLayer = showTouchLayer
    if device.platform == "mac" then
        printInfo("xcyy ViewManager:showUI 111 : %s", tostring(uiNode.__cname))
    else
        release_print("xcyy ViewManager:showUI: " .. tostring(uiNode.__cname))
    end

    local _parent = uiNode:getParent()
    if not tolua.isnull(_parent) then
        -- 已经有父节点了
        local errMsg = "uiNode " .. tostring(uiNode.__cname) .. " had parent, add to ViewLayer will crash!!!"
        if DEBUG == 2 then
            assert(nil, errMsg)
        else
            release_print(errMsg)
            util_sendToSplunkMsg("showUIError", errMsg)
        end
        return
    end

    if zorder then
        self:getViewLayer():addChild(uiNode, zorder) -- 是否添加在最上层
    else
        self:getViewLayer():addChild(uiNode)
    end

    uiNode.viewType = ViewType.TYPE_UI
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI, {node = uiNode})
end

function ViewManager:getViewByTag(tag)
    local view = self:getViewLayer():getChildByTag(tag)
    return view
end

function ViewManager:getViewByName(name)
    local view = self:getViewLayer():getChildByName(name)
    return view
end

function ViewManager:getViewByExtendData(data)
    local viewChilds = self:getViewLayer():getChildren()
    for k, v in ipairs(viewChilds) do
        if v.getExtendData ~= nil and v:getExtendData() == data then
            return v
        end
    end
    return nil
end

function ViewManager:isPauseAndResumeMachine(ui)
    return true
end

function ViewManager:getHasShowUI()
    local viewChilds = self:getViewLayer():getChildren()
    for i = 1, #viewChilds do
        local view = viewChilds[i]
        if view.viewType and view.viewType == ViewType.TYPE_UI then
            return true
        end
    end
    return false
end

--csb_path csb路径 okFunc确定按钮回调 otherFunc取消按钮回调 isHold 点击后是否保留弹窗
--使用例子: gLobalViewManager:showDialog("Dialog/xxxxx.csb")
function ViewManager:showDialog(csb_path, okFunc, otherFunc, isHold, zorder, params)
    local view = util_createView("views.dialogs.DialogLayer", csb_path, okFunc, otherFunc, isHold, params)
    if zorder then
        self:showUI(view, zorder)
    else
        self:showUI(view, ViewZorder.ZORDER_UI)
    end

    return view
end

-- 未下载的通用提示
function ViewManager:showDownloadTip(okFunc, otherFunc)
    local view = self:showDialog("Dialog/LevelDashIndexIf.csb", okFunc, otherFunc, nil, nil)
    if view then
        local str = "Please wait for a while until the download is completed."
        view:updateContentTipUI("lb_text", str)
    end
end

function ViewManager:findReconnectView()
    local view = display.getRunningScene():getChildByName("ReconnectView")
    if not view then
        view = gLobalViewManager:getViewByName("ReconnectView")
    end
    return view
end

--显示断线重新连接
function ViewManager:showReConnect(isRestart, isHold, errorInfo, ignoreLog)
    --清理引导防止不能点击
    if globalNoviceGuideManager ~= nil then
        globalNoviceGuideManager:clearGuide()
    end

    local view = self:findReconnectView()
    if not view then
        view =
            self:showDialog(
            "Dialog/Reconnect.csb",
            function()
                if isRestart then
                    if gLobalGameHeartBeatManager then
                        gLobalGameHeartBeatManager:stopHeartBeat()
                    end
                    util_restartGame()
                else
                    gLobalSendDataManager:reconnNetwork()
                end
            end,
            nil,
            isHold,
            ViewZorder.ZORDER_NETWORK,
            {
                {buttomName = "btn_ok", labelString = "RETRY"}
            }
        )
        if view.setEnableOnkeyBack then
            view:setEnableOnkeyBack(false)
        end
        view:setName("ReconnectView")
    end

    if DEBUG == 2 and (errorInfo and type(errorInfo) == "table") then
        local str = errorInfo.errorMsg
        view:updateContentTipUI("lb_text", str)
    end

    if (not isRestart) and (not ignoreLog) then
        if gLobalSendDataManager and gLobalSendDataManager.getLogGameLoad and gLobalSendDataManager:getLogGameLoad().sendNetErrorLog then
            gLobalSendDataManager:getLogGameLoad():sendNetErrorLog(errorInfo, "ReConnectDialog")
        end
    end
end

-- 显示断线重新连接
function ViewManager:showReConnectNew(_okFunc, _otherFunc, _isHold, errorInfo, ignoreLog)
    --清理引导防止不能点击
    if globalNoviceGuideManager ~= nil then
        globalNoviceGuideManager:clearGuide()
    end

    local _runningScene = display.getRunningScene()
    if _runningScene then
        local warnView = self:findReconnectView()
        if not warnView then
            warnView =
                util_createView(
                "views.dialogs.DialogLayer",
                "Dialog/Reconnect.csb",
                function()
                    gLobalSendDataManager:reconnNetwork(_okFunc)
                end,
                _otherFunc,
                _isHold,
                {
                    {buttomName = "btn_ok", labelString = "RETRY"}
                }
            )

            if warnView.setEnableOnkeyBack then
                warnView:setEnableOnkeyBack(false)
            end

            warnView:setName("ReconnectView")
            _runningScene:addChild(warnView, ViewZorder.ZORDER_NETWORK)
        end

        if DEBUG == 2 and (errorInfo and type(errorInfo) == "table") then
            local str = errorInfo.errorMsg
            warnView:updateContentTipUI("lb_text", str)
        end
    end

    if not ignoreLog then
        if gLobalSendDataManager and gLobalSendDataManager.getLogGameLoad and gLobalSendDataManager:getLogGameLoad().sendNetErrorLog then
            gLobalSendDataManager:getLogGameLoad():sendNetErrorLog(errorInfo, "ReConnectDialog")
        end
    end
end

--显示关卡维护中弹窗
function ViewManager:showMaintain()
    local view =
        util_createView(
        "views.dialogs.DialogLayer",
        "Dialog/MaintainLayer.csb",
        function()
            if globalNoviceGuideManager.guideBubbleReturnLobbyPopup then
                globalNoviceGuideManager.guideBubbleReturnLobbyPopup = nil
                if globalFireBaseManager.sendFireBaseLogDirect then
                    globalFireBaseManager:sendFireBaseLogDirect("MaintainBackLobby", false)
                end
            end
            if globalData.slotRunData.machineData then
                globalData.slotRunData:changeLevelsMaintain(globalData.slotRunData.machineData.p_id, true)
            end
            if gLobalSendDataManager:getLogGuide():isGuideBegan(5) then
                gLobalSendDataManager:getLogGuide():sendGuideLog(5, 2)
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_GAME_LOADING)
            gLobalViewManager:gotoLobbyByLunch()
        end,
        nil,
        true
    )
    display.getRunningScene():addChild(view, ViewZorder.ZORDER_NETWORK)
    if view.setEnableOnkeyBack then
        view:setEnableOnkeyBack(false)
    end
end

-- 封停用户弹框
function ViewManager:showAccountClosureDialog()
    local ui = util_createView("views.dialogs.AccountClosureLayer")
    display.getRunningScene():addChild(ui, ViewZorder.ZORDER_NETWORK + 1)
end

-- 用户作弊被警告 或者 封号
function ViewManager:showAccountBannedDialog(_bannedInfo, _ignoreCb)
    if not _bannedInfo or not _bannedInfo.code then
        return
    end
    local ui = util_createView("views.dialogs.AccountBannedLayer", _bannedInfo, _ignoreCb)
    display.getRunningScene():addChild(ui, ViewZorder.ZORDER_NETWORK + 1)
end

--删除账号恢复弹窗
function ViewManager:showRecoverDelAccountDialog(data)
    local ui = util_createView("views.dialogs.AccountRecoverLayer", data)
    display.getRunningScene():addChild(ui, ViewZorder.ZORDER_NETWORK + 1)
end

function ViewManager:showTestDialog(msg, okFunc)
    local view = self:showDialog("Dialog/TestDialog.csb", okFunc, nil, false, ViewZorder.ZORDER_NETWORK)
    if not msg then
        msg = ""
    end
    view:findChild("m_msg"):setString(msg)
end

-- 创建 网络loading layer
function ViewManager:createLoadingAnimaLayer()
    local loadingMaskLayer = util_newMaskLayer(false)

    local loadingIcon = display.newSprite("Common/Other/common_loading_0.png")
    loadingIcon:setPosition(cc.p(display.width / 2, display.height / 2))
    loadingIcon:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, 360)))
    loadingIcon:setScale(1 / loadingMaskLayer:getScale())
    loadingIcon:setName("Sp_loading")
    loadingMaskLayer:setName("loadingAnimaLayer")
    loadingMaskLayer:addChild(loadingIcon)
    self:getViewLayer():addChild(loadingMaskLayer, ViewZorder.ZORDER_LOADING, ViewZorder.ZORDER_LOADING)

    performWithDelay(
        loadingMaskLayer,
        function()
            -- loading动画超时
            util_sendToSplunkMsg("LoadingAnima", "loading anima 10s timeout!!!")
        end,
        10
    )

    return loadingMaskLayer
end

--[[
description: 添加最上层遮罩 是否创建不可见的loading
param _idHide bool 是否隐藏
param _delayTime number 延迟时间
param _persistTime number 持续时间
return {*}
--]]
function ViewManager:addLoadingAnima(_isHide, _delayTime, _persistTime)
    local loadingMaskLayer = self:getLoadingAnima()

    if not loadingMaskLayer then
        loadingMaskLayer = self:createLoadingAnimaLayer()
    end

    local opacity = 120
    if _isHide or _delayTime then
        -- 隐藏 或者 延迟显示 把透明度设为0
        opacity = 0
    end

    self:setLoadingAnimaOpacty(loadingMaskLayer, opacity)

    -- 延迟时间
    if _delayTime then
        util_performWithDelay(
            loadingMaskLayer,
            function()
                self:setLoadingAnimaOpacty(loadingMaskLayer, 120)
            end,
            _delayTime
        )
    end

    -- 持续时间
    if _persistTime then
        util_performWithDelay(
            loadingMaskLayer,
            function()
                loadingMaskLayer:removeFromParent()
            end,
            _persistTime
        )
    end
end

function ViewManager:setLoadingAnimaOpacty(loadingLayer, opacity)
    if tolua.isnull(loadingLayer) then
        return
    end
    -- loading 显隐
    loadingLayer:setOpacity(opacity)
    local spLoading = loadingLayer:getChildByName("Sp_loading")
    if not tolua.isnull(spLoading) then
        spLoading:setVisible(opacity ~= 0)
    end
end

-- 延迟loading
function ViewManager:addLoadingAnimaDelay(_delayTime)
    _delayTime = _delayTime or 0.6
    self:addLoadingAnima(false, _delayTime)
end

---
-- UI 处理函数
--
-- @param 删除最上层遮罩
function ViewManager:removeLoadingAnima()
    local loadingMaskLayer = self:getLoadingAnima()
    self:setLoadingAnimaOpacty(loadingMaskLayer, 0)
    util_nextFrameFunc(
        function()
            local _loadingMaskLayer = self:getLoadingAnima()
            if _loadingMaskLayer then
                _loadingMaskLayer:removeFromParent()
            end
        end
    )
end

function ViewManager:getLoadingAnima()
    local loadingMaskLayer = self:getViewLayer():getChildByName("loadingAnimaLayer")
    if not loadingMaskLayer then
        loadingMaskLayer = display.getRunningScene():getChildByName("loadingAnimaLayer")
    end
    if not tolua.isnull(loadingMaskLayer) then
        return loadingMaskLayer
    else
        return nil
    end
end

function ViewManager:runScene(scene, transitiond, time, more)
    display.runScene(scene, transitiond, time, more)
    self:addOnkeyBackListener(scene)
    globalEventKeyControl:clearKeyBack()
end

function ViewManager:addOnkeyBackListener(scene)
    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(handler(self, self.onKeyboard), cc.Handler.EVENT_KEYBOARD_RELEASED)
    local eventDispatcher = scene:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, scene)
end

function ViewManager:onKeyboard(code, event)
    if code == cc.KeyCode.KEY_BACK then
        print("你点击了返回键")
        local loadingMaskLayer = self:getLoadingAnima()
        if loadingMaskLayer == nil then
            --引导遮罩存在时不可以按返回键
            if globalNoviceGuideManager and globalNoviceGuideManager:isMaskUI() then
                return
            end

            globalEventKeyControl:onKeyBack()
        end
    elseif code == cc.KeyCode.KEY_HOME then
        print("你点击了HOME键")
    elseif code == cc.KeyCode.KEY_T then
        if DEBUG ~= 0 then
            -- Modified by tm , show current texture cache --
            if tolua.isnull(self.textureCacheText) == true then
                local textureCache = cc.Director:getInstance():getTextureCache():getCachedTextureInfo()
                self.textureCacheText = cc.Label:createWithSystemFont(textureCache, "", 12)
                self.textureCacheText:setAnchorPoint(cc.p(0, 0))
                self.textureCacheText:setPosition(cc.p(0, 0))
                display:getRunningScene():addChild(self.textureCacheText, 100)
                util_saveStrLogToFile(textureCache)
                print("显示纹理内存")
            else
                self.textureCacheText:removeFromParent()
                self.textureCacheText = nil
                print("关闭纹理内存")
            end
        end
    elseif code == cc.KeyCode.KEY_C then
        cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    elseif code == cc.KeyCode.KEY_Q then
        -- if self:isLobbyView() then
            util_TestGotoLevel()
        -- end
        
    end
end

--[[
    @desc:
    author:{he}
    time:2020-05-27 14:45:09
    --@startPos:            金币出现位置
    --@endPos:              金币结束位置 现在一般在topui金币条位置
    --@baseCoinValue:       金币滚动前的数值
    --@addCoinValue:        金币增加数量
    --@func:                全部动画播放完回调
    --@bShowBgColor:        是否显示bg的灰色遮罩    默认关闭
    --@flyType:             金币飞行轨迹 type 扩展用现在就一个moveto
    --@newCountNum:         新的收集飞行金币数量
    --@newFlyTime:          新的金币飞行时间
    --@newSpanTime:         金币出现间隔
    --@bHideOriginEffect:   是否隐藏金币出现时动画(漩涡动画)
    --@c4fColor:            遮罩color设置
    @return:
]]
--新的 飞金币接口
function ViewManager:getFlyCoinsView()
    local createCoinFlyView = function()
        local view = util_createView("views.lobby.GameCoinFlyView")
        view:setName("viewCoinFly")
        return view
    end
    local viewCoinFly = self:getViewLayer():getChildByName("viewCoinFly")
    if not viewCoinFly then
        viewCoinFly = createCoinFlyView()
        self:getViewLayer():addChild(viewCoinFly, ViewZorder.ZORDER_SPECIAL) -- 是否添加在最上层
    end
    return viewCoinFly
end

function ViewManager:pubPlayFlyCoin(startPos, endPos, baseCoinValue, addCoinValue, func, bShowBgColor, newCountNum, flyType, newFlyTime, newSpanTime, bHideOriginEffect, bgC4fColor)
    local viewCoinFly = self:getFlyCoinsView()
    if globalData.LevelRushLuckyStampCoinsEndPos then
        -- levelRush 金币位置有问题
        endPos = globalData.LevelRushLuckyStampCoinsEndPos
        viewCoinFly:pubShowSelfCoins(true)
        viewCoinFly:pubSetRotationFlag(false, endPos)
    end
    viewCoinFly:pubPlayFlyCoin(startPos, endPos, baseCoinValue, addCoinValue, func, bShowBgColor, newCountNum, flyType, newFlyTime, newSpanTime, bHideOriginEffect, bgC4fColor)
    return viewCoinFly
end

---------------------------------------------------------------------------------------------------------
--2020-5-27 用户全部更新新飞金币接口后可删除
function ViewManager:flyCoins(startPos, endPos, flyType, func, countNum, newFlyTime, spanTime)
    gLobalSoundManager:playSound("Sounds/flying_coins.mp3")
    local flyNode = cc.Node:create()
    self:getViewLayer():addChild(flyNode, ViewZorder.ZORDER_SPECIAL) -- 是否添加在最上层
    --new
    local count = 13
    local flyTime = 0.8
    local time = 0.07

    if spanTime then
        time = spanTime
    end
    if newFlyTime then
        flyTime = newFlyTime
    end
    if countNum then
        -- body
        count = countNum
    end
    for i = 1, count do
        self:runFlyCoinsAction(flyNode, time * i, flyTime, startPos, endPos, flyType)
    end
    performWithDelay(
        flyNode,
        function()
            if func then
                func()
            end
            flyNode:removeFromParent()
        end,
        flyTime + time * count
    )
end

function ViewManager:runFlyCoinsAction(flyNode, time, flyTime, startPos, endPos, flyType)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local node, csbAct = util_csbCreate("Lobby/FlyCoins.csb")
    node:setVisible(false)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            node:setVisible(true)
            if not flyType then
                util_csbPlayForKey(csbAct, "idle")
            elseif flyType == 1 then
                util_csbPlayForKey(csbAct, "idle2")
            end
        end
    )
    flyNode:addChild(node)

    node:setPosition(startPos)
    if not flyType then
        local bez =
            cc.BezierTo:create(
            flyTime,
            {
                cc.p(endPos.x, startPos.y + (endPos.y - startPos.y) * 0.3),
                cc.p(startPos.x, startPos.y + (endPos.y - startPos.y) * 0.5),
                endPos
            }
        )
        actionList[#actionList + 1] = bez
    elseif flyType == 1 then
        local bez =
            cc.BezierTo:create(
            flyTime,
            {
                cc.p(startPos.x - (startPos.x - endPos.x) * 0.3, startPos.y - 100),
                cc.p(startPos.x - (startPos.x - endPos.x) * 0.6, startPos.y + 50),
                endPos
            }
        )
        actionList[#actionList + 1] = bez
    elseif flyType == 2 then
    end
    node:runAction(cc.Sequence:create(actionList))
end
---------------------------------------------------------------------------------------------------------

function ViewManager:flyImage(path, startPos, endPos, scale, func)
    local flyNode = cc.Node:create()
    self:getViewLayer():addChild(flyNode, ViewZorder.ZORDER_SPECIAL) -- 是否添加在最上层
    local time = 0.03
    local count = 5
    local flyTime = 0.5
    for i = 1, count do
        self:runFlyImageAction(path, flyNode, time * i, flyTime, scale, startPos, endPos)
    end

    local sp = display.newSprite(path)
    flyNode:addChild(sp)
    sp:setPosition(startPos)
    sp:runAction(cc.EaseExponentialIn:create(cc.MoveTo:create(flyTime, endPos)))
    -- sp:runAction(cc.FadeTo:create(flyTime,50))
    sp:runAction(cc.ScaleTo:create(flyTime, scale))
    performWithDelay(
        flyNode,
        function()
            if func then
                func()
            end
        end,
        flyTime
    )

    performWithDelay(
        flyNode,
        function()
            flyNode:removeFromParent()
        end,
        flyTime + time * count + 1
    )
end

function ViewManager:runFlyImageAction(path, flyNode, time, flyTime, scale, startPos, endPos)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local sp = display.newSprite(path)
    -- local sp =cc.MotionStreak:create(0.3, 1, 128, cc.c3b(255,255,255),path)
    sp:setVisible(false)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            sp:setVisible(true)
            sp:runAction(cc.FadeTo:create(flyTime + 0.5 - time, 50))
            sp:runAction(cc.ScaleTo:create(flyTime, scale))
        end
    )
    flyNode:addChild(sp)
    sp:setPosition(startPos)
    actionList[#actionList + 1] = cc.EaseExponentialIn:create(cc.MoveTo:create(flyTime, endPos))
    sp:runAction(cc.Sequence:create(actionList))
end

-- function ViewManager:flyImage(path, startPos, endPos, scale, func)
-- end

--是否处于暂停中，这个函数没用了
function ViewManager:isViewPause()
    return false
end

--暂停背景界面 需要传入暂停的界面
function ViewManager:showPauseUI(path, ...)
    local view = util_createView(path, ...)
    self:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

--暂停恢复
function ViewManager:viewResume(func)
    if func then
        func()
        func = nil
    end
end

--自动关闭提示 isTouchEnd是否穿透
function ViewManager:addAutoCloseTips(node, closeFunc, isTouchEnd)
    if not node then
        return
    end

    -- 屏蔽延时，因为添加延时后，0.5s内点击后不会关闭界面
    -- performWithDelay(node,function()
    local isCloseTips = false
    local layer = cc.Layer:create()
    layer:onTouch(
        function(event)
            if isCloseTips then
                return true
            end
            if isTouchEnd and event.name ~= "ended" then
                return true
            end
            isCloseTips = true
            if layer then
                layer:removeFromParent()
                layer = nil
            end
            -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            if closeFunc then
                closeFunc()
                closeFunc = nil
            end
            return true
        end,
        false,
        true
    )
    self:getViewLayer():addChild(layer, ViewZorder.ZORDER_SPECIAL)
    -- end,0.5)

    -- 定义倒计时关闭界面
    performWithDelay(
        node,
        function()
            if isCloseTips then
                return true
            end
            isCloseTips = true
            if layer and not tolua.isnull(layer) then
                layer:removeFromParent()
                layer = nil
            end
            if closeFunc then
                closeFunc()
                closeFunc = nil
            end
        end,
        5
    )
end
--node飞行的图片或者粒子,startPos开始坐标,endPos停止坐标,flyTime飞行时间,func结束回调
function ViewManager:flySpecialNode(node, startPos, endPos, flyTime, func)
    if not node then
        return
    end
    if not flyTime then
        flyTime = 1
    end
    local actionList = {}
    local tempPos = cc.p(endPos.x - 300, endPos.y + 300)
    local bez1 = cc.BezierTo:create(flyTime * 0.5, {startPos, cc.p(startPos.x, endPos.y + 300), tempPos})
    actionList[#actionList + 1] = bez1
    local bez2 = cc.BezierTo:create(flyTime * 0.5, {tempPos, cc.p(tempPos.x - 200, endPos.y), endPos})
    actionList[#actionList + 1] = bez2
    if func then
        actionList[#actionList + 1] = cc.CallFunc:create(func)
    end
    node:runAction(cc.Sequence:create(actionList))
end

--集卡预告
function ViewManager:showPreCard()
    local proCardLayer = util_createAnimation("PreCard/PreCardLayer.csb")
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(proCardLayer, "Push", DotUrlType.UrlName, true, DotEntrySite.LevelUpPush, DotEntryType.Game)
    end
    self:showUI(proCardLayer, nil, false)
    if globalData.slotRunData.isPortrait then
        local bangHeight = util_getBangScreenHeight()
        proCardLayer:setPosition(display.width - 550, display.height - 170 - bangHeight)
    else
        proCardLayer:setPosition(display.width - 550, display.height - 170)
    end
    proCardLayer:runCsbAction(
        "show",
        false,
        function()
            if proCardLayer and proCardLayer.removeFromParent then
                proCardLayer:removeFromParent()
            end
        end,
        60
    )
end

--当前版本是否可以玩关卡
function ViewManager:checkEnterLevelForApp(id)
    -- if globalData.slotRunData.p_machineDatas and #globalData.slotRunData.p_machineDatas > 0 then
    --     local info = nil
    --     for i = 1, #globalData.slotRunData.p_machineDatas do
    --         local newInfo = globalData.slotRunData.p_machineDatas[i]
    --         if newInfo.p_id == id then
    --             info = newInfo
    --             break
    --         end
    --     end
    --     if not info then
    --         return false
    --     end
    --     if not info.p_openAppVersion or util_isSupportVersion(info.p_openAppVersion) then
    --         --没有配置 或者配置版本可支持
    --         return true
    --     end
    -- end

    local info = globalData.slotRunData:getLevelInfoById(id)
    if not info then
        return false
    end
    if not info.p_openAppVersion or util_isSupportVersion(info.p_openAppVersion) then
        --没有配置 或者配置版本可支持
        return true
    end

    return false
end

--显示提升版本界面
function ViewManager:showUpgradeAppView()
    local view =
        gLobalViewManager:showDialog(
        "UpgradeAppView/UpgradeAppView.csb",
        function()
            xcyy.GameBridgeLua:rateUsForSetting()
        end,
        nil,
        false,
        ViewZorder.ZORDER_NETWORK
    )
end

function ViewManager:refreshTriggerQueueList()
    if self.m_triggerQueueList and table.nums(self.m_triggerQueueList) > 0 then
        for i = table.nums(self.m_triggerQueueList), 1, -1 do
            local queue = self.m_triggerQueueList[i]
            if queue:isEmpty() then
                table.remove(self.m_triggerQueueList, i)
            end
        end
        print("!!!ViewManager.m_triggerQueueList = ", table.nums(self.m_triggerQueueList))
    end
end

function ViewManager:triggerFuncClear()
    if self.m_triggerQueueList and table.nums(self.m_triggerQueueList) > 0 then
        for i = table.nums(self.m_triggerQueueList), 1, -1 do
            self.m_triggerQueueList[i]:triggerFuncClear()
        end
    end
end

function ViewManager:checkTriggerList(_funcList, _overcall)
    local TriggerFunctionQueue = util_require("manager.TriggerFunctionQueue")
    local triggerQueue = TriggerFunctionQueue:create()
    table.insert(self.m_triggerQueueList, triggerQueue)
    triggerQueue:checkTriggerList(_funcList, _overcall)
end

-- --执行一系列方法
-- -- funcdata = {func = 需要执行的方法,params = 参数}
-- --funcList = {funcdata1,funcdata2,funcdata3}
-- function ViewManager:checkTriggerList(funcList, overListFunc)
--     self.m_triggerFuncCallBack = overListFunc
--     if not funcList or #funcList == 0 then
--         self:triggerFuncFinish()
--         return false
--     end
--     self.m_triggerFuncList:clear()
--     self.m_triggerFuncCount = 0
--     for i = 1, #funcList do
--         self.m_triggerFuncList:push(funcList[i])
--     end
--     return self:triggerFuncNext()
-- end
-- --执行下一个方法
-- function ViewManager:triggerFuncNext()
--     --结束条件
--     if self.m_triggerFuncList:empty() then
--         self:triggerFuncFinish()
--         return false
--     end
--     local info = self.m_triggerFuncList:pop()
--     if info then
--         if info.func then
--             --执行一个方法
--             self.m_triggerFuncCount = self.m_triggerFuncCount + 1
--             info.func(info.params)
--             return true
--         else
--             return self:triggerFuncNext()
--         end
--     else
--         return self:triggerFuncNext()
--     end
-- end
-- --执行完成
-- function ViewManager:triggerFuncFinish()
--     --清空参数
--     self:triggerFuncClear()
--     if self.m_triggerFuncCallBack then
--         local overFunc = self.m_triggerFuncCallBack
--         self.m_triggerFuncCallBack = nil
--         overFunc()
--     end
--     self:onFinished()
-- end
-- --清空参数
-- function ViewManager:triggerFuncClear()
--     self.m_triggerFuncList:clear()
--     self.m_triggerFuncCount = -1
-- end

-- -- 弹板结束消息 这里不能用做控制弹板 有弹板的话 还是要放到弹板列表里面去
-- -- 这里用作监听该消息的面板自身刷新
-- function ViewManager:onFinished()
--     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUY_TIP_POPED_OVER)
-- end

--在付费掉卡之前的提示（纯提示不要有任何跳转的）
function ViewManager:checkAfterBuyTipList(callback, key)
    local funcList = {}
    --测试用例
    -- funcList[#funcList+1] = {func = handler(self,self.testBuyTipLayerFunc), params = nil}

    --尝试提示jackpotTip
    funcList[#funcList + 1] = {func = handler(self, self.triggerRepartJackpotTipLayer), params = nil}
    local isRepartFsAlive = true
    if key and key == "LevelDash" then
        isRepartFsAlive = false
    end
    if key and key == "CashBonus" then
        isRepartFsAlive = false
    end
    --尝试提示freespinTip leveldash 和付费轮盘不弹提示
    if isRepartFsAlive then
        funcList[#funcList + 1] = {func = handler(self, self.triggerRepartFreeSpinTipLayer), params = nil}
    end
    funcList[#funcList + 1] = {func = handler(self, self.triggerEchoWinSpinTipLayer), params = nil}
    --开始执行
    self:checkTriggerList(funcList, callback)
end
----购买盖章后的提示
function ViewManager:checkBuyTipList(callback)
    local funcList = {}
    --测试用例
    -- funcList[#funcList+1] = {func = handler(self,self.testBuyTipLayerFunc), params = nil}

    funcList[#funcList + 1] = {func = handler(self, self.triggerLuckyStamp), params = nil}
    -- funcList[#funcList + 1] = {func = handler(self, self.updateShop), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropPurchaseCrads), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerCustomDropCrads), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropLuckySpinCrads), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropDoubleBuffCrads), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropOtherCrads), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropChipPiggyCrads), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropCatFoodLayer), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.trigger7DaysPurchase), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerPurchaseDrawLayerFunc), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerGetMorePayLessLayer), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.trigger4BdayDrawWheelLayer), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerSaleTicketLayerFunc), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerCouponRewardsLayer), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropPropsBagLayer), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerPiggyGoodiesLayer), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerAddPayLayer), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropLuckFish), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropDeluxeCard), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerPopWildChallengeLayer), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropDuckShot), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerGashpon), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropLotteryTicket), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerKeepRecharge), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropPiggyClickerGameItem), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerPinBallGO), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropDartsGameItem), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDropDartsGameItemNew), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerBasicSaleWheel), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerRoutineSaleWheel), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerReturnQuestTaskComplete), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerGrandFinaleTaskComplete), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerTimeLimitExpansionTaskComplete), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerDIYFeatureMission), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerHolidayStore), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerHolidayPassProgressLayer), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerXmasCraze2023Mgr), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerXmasSplit2023), params = nil}
    funcList[#funcList + 1] = {func = handler(self, self.triggerBingoBuff), params = nil} -- 记得放最后一个

    --开始执行
    self:checkTriggerList(funcList, callback)
end

-- LuckySpin购买掉卡
function ViewManager:triggerDropLuckySpinCrads(_params, _overcall)
    if not CardSysManager:needDropCards("Purchase") then
        if _overcall then
            _overcall()
        end
        return
    end

    gLobalNoticManager:addObserver(
        self,
        function(sender, func)
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
            if _overcall then
                _overcall()
            end
        end,
        ViewEventType.NOTIFY_CARD_SYS_OVER
    )
    CardSysManager:doDropCards("Purchase")
end

--测试用例
function ViewManager:testBuyTipLayerFunc(_params, _overcall)
    if _overcall then
        _overcall()
    end
end
--尝试提示jackpotTip
function ViewManager:triggerRepartJackpotTipLayer(_params, _overcall)
    local repartJackpotData = G_GetMgr(ACTIVITY_REF.RepartJackpot):getRunningData()
    if repartJackpotData == nil or repartJackpotData:isRunning() == false then
        if _overcall then
            _overcall()
        end
        return
    end
    --活动结束时间
    local expireTime = repartJackpotData:getLeftTime()
    if not expireTime or expireTime <= 0 then
        if _overcall then
            _overcall()
        end
        return
    end
    --不需要提示
    if not repartJackpotData:isBuyTips() then
        if _overcall then
            _overcall()
        end
        return
    end
    local view = util_createFindView("Activity/RepartJackpotBuyLayer")
    if view ~= nil then
        repartJackpotData:clearBuyTips()
        self:showUI(view, ViewZorder.ZORDER_POPUI)
        view:setOverFunc(
            function()
                if _overcall then
                    _overcall()
                end
            end
        )
    else
        if _overcall then
            _overcall()
        end
    end
end
--尝试提示freespinTip
function ViewManager:triggerRepartFreeSpinTipLayer(_params, _overcall)
    local repeatFreeSpinData = G_GetMgr(ACTIVITY_REF.RepeatFreeSpin):getRunningData()
    if repeatFreeSpinData == nil or repeatFreeSpinData:isRunning() == false then
        if _overcall then
            _overcall()
        end
        return
    end
    --活动结束时间
    local expireTime = repeatFreeSpinData:getLeftTime()
    if not expireTime or expireTime <= 0 then
        if _overcall then
            _overcall()
        end
        return
    end
    --不需要提示
    if not repeatFreeSpinData:isBuyTips() then
        if _overcall then
            _overcall()
        end
        return
    end
    local view = util_createFindView("Activity/RepeatFreeSpinBuyLayer")
    if view ~= nil then
        repeatFreeSpinData:clearBuyTips()
        self:showUI(view, ViewZorder.ZORDER_UI)
        view:setOverFunc(
            function()
                if _overcall then
                    _overcall()
                end
            end
        )
    else
        if _overcall then
            _overcall()
        end
    end
end
--尝试提示freespinTip
function ViewManager:triggerEchoWinSpinTipLayer(_params, _overcall)
    local echowinSpinData = G_GetMgr(ACTIVITY_REF.EchoWin):getRunningData()
    if echowinSpinData == nil or echowinSpinData:isRunning() == false then
        if _overcall then
            _overcall()
        end
        return
    end

    --活动结束时间
    local expireTime = echowinSpinData:getLeftTime()
    if not expireTime or expireTime <= 0 then
        if _overcall then
            _overcall()
        end
        return
    end

    --不需要提示
    if not echowinSpinData:isBuyTips() then
        if _overcall then
            _overcall()
        end
        return
    end

    local view = util_createFindView("Activity/Activity_EchoWinBuy")
    if view == nil then
        if _overcall then
            _overcall()
        end
        return
    end

    echowinSpinData:setIsBuyTips(false)
    self:showUI(view, ViewZorder.ZORDER_UI)
    view:setOverFunc(
        function()
            if _overcall then
                _overcall()
            end
        end
    )
end

function ViewManager:triggerLuckyStamp(_params, _overcall)
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data and data:getNeedStampNum() > 0 and data:getLeftTime() > 0 then
        G_GetMgr(G_REF.LuckyStamp):enterGame(
            function()
                if _overcall then
                    _overcall()
                end
            end
        )
    else
        if _overcall then
            _overcall()
        end
    end
end

function ViewManager:updateShop()
    -- 提前刷新商城，因为商城后续的弹板中再次付费的话，会覆盖 checkBuyTipList 的回调函数
    -- 后续优化：将 checkBuyTipList 的弹板队列封装成对象，实现嵌套，防止回调函数被覆盖，一去不返。
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYTIP_CLOSE)
    gLobalViewManager:triggerFuncNext() --执行下一个方法
end

-- 尝试 掉落充值卡
function ViewManager:triggerDropPurchaseCrads(_params, _overcall)
    if not CardSysManager:needDropCards("Purchase") then
        if _overcall then
            _overcall()
        end
        return
    end

    gLobalNoticManager:addObserver(
        self,
        function(sender, func)
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
            if _overcall then
                _overcall()
            end
        end,
        ViewEventType.NOTIFY_CARD_SYS_OVER
    )
    CardSysManager:doDropCards("Purchase")
end

function ViewManager:setCustomCardSource(source)
    self.m_source = source
end
-- 尝试 掉落充值卡
function ViewManager:triggerCustomDropCrads(_params, _overcall)
    if self.m_source then
        local useSource = self.m_source
        self.m_source = nil
        if not CardSysManager:needDropCards(useSource) then
            if _overcall then
                _overcall()
            end
            return
        end
    
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                if _overcall then
                    _overcall()
                end
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards(useSource)
    else
        if _overcall then
            _overcall()
        end
        return
    end
end

-- 尝试 掉落  神像双倍掉落buff 卡
function ViewManager:triggerDropDoubleBuffCrads(_params, _overcall)
    if not CardSysManager:needDropCards("Purchase Double Buff") then
        if _overcall then
            _overcall()
        end
        return
    end

    gLobalNoticManager:addObserver(
        self,
        function(sender, func)
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
            if _overcall then
                _overcall()
            end
        end,
        ViewEventType.NOTIFY_CARD_SYS_OVER
    )
    CardSysManager:doDropCards("Purchase Double Buff")
end

-- 尝试 掉落  其他 卡
function ViewManager:triggerDropOtherCrads(_params, _overcall)
    if CardSysManager:needDropCards("Super Spin Card") == true then
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                if _overcall then
                    _overcall()
                end
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards("Super Spin Card")
    elseif CardSysManager:needDropCards("Super Spin Golden Card") == true then
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                if _overcall then
                    _overcall()
                end
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards("Super Spin Golden Card")
    elseif CardSysManager:needDropCards("Super Spin Guaranteed Card") == true then
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                if _overcall then
                    _overcall()
                end
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards("Super Spin Guaranteed Card")
    elseif CardSysManager:needDropCards("Lucky Spin New Card") == true then
        CardSysManager:doDropCards("Lucky Spin New Card", function ()
            local data = G_GetMgr(ACTIVITY_REF.FireLuckySpinRandomCard):getRunningData()
            if data then
                G_GetMgr(ACTIVITY_REF.FireLuckySpinRandomCard):showMainLayer({overcall = _overcall, needAct = true})
            else
                if _overcall then
                    _overcall()
                end
            end
        end)
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 尝试 集卡小猪掉卡
function ViewManager:triggerDropChipPiggyCrads(_params, _overcall)
    if CardSysManager:needDropCards("Pig Chip") == true then
        CardSysManager:doDropCards(
            "Pig Chip",
            function()
                if _overcall then
                    _overcall()
                end
            end
        )
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 尝试 掉落猫粮
function ViewManager:triggerDropCatFoodLayer(_params, _overcall)
    local catManager = G_GetMgr(ACTIVITY_REF.DeluxeClubCat)
    local cb = function()
        catManager:resetCatFoodTempList()
        if _overcall then
            _overcall()
        end
    end

    catManager:autoPopCatFoodLayer(cb)
end

-- 尝试 掉落合成福袋
function ViewManager:triggerDropPropsBagLayer(_params, _overcall)
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    local cb = function()
        mergeManager:resetPropsBagTempList()
        if _overcall then
            _overcall()
        end
    end

    mergeManager:autoPopPropsBagLayer(cb)
end

function ViewManager:triggerAddPayLayer(_params, _overcall)
    if G_GetMgr(ACTIVITY_REF.AddPay):hasRewards() then
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_ACTIVITY_ADDPAY_CLOSED)
                if _overcall then
                    _overcall()
                end
            end,
            ViewEventType.NOTIFY_ACTIVITY_ADDPAY_CLOSED
        )

        G_GetMgr(ACTIVITY_REF.AddPay):showMainLayer()
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 尝试 弹出luckFish 道具
function ViewManager:triggerDropLuckFish(_params, _overcall)
    local levelRushList = gLobalLevelRushManager:getPopLevelRushTempList()
    if levelRushList and next(levelRushList) then
        local cb = function()
            gLobalLevelRushManager:resetLevelRushTempList()
            if _overcall then
                _overcall()
            end
        end
        -- csc 2022-01-06 修改掉弹板，改为直接跳转进minigame
        if gLobalMiniGameManager:checkHasMiniGame() then
            gLobalMiniGameManager:startMiniGame(cb)
        else
            cb()
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

function ViewManager:triggerDropDeluxeCard(_params, _overcall)
    local cb = function()
        if _overcall then
            _overcall()
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM, cb)
end

-- 尝试弹出四联折扣券活动弹框
function ViewManager:triggerSaleTicketLayerFunc(_params, _overcall)
    -- 如果不是商城中购买的话不弹出4连折扣券  如果是第二货币购买的话也不能弹出
    local ZQCoinStoreLayer = gLobalViewManager:getViewByExtendData("ZQCoinStoreLayer")
    if not ZQCoinStoreLayer or globalData.shopRunData:getShopPageIndex() == 2 then
        if _overcall then
            _overcall()
        end
        return
    end

    local saleTicketData = G_GetMgr(ACTIVITY_REF.SaleTicket):getRunningData()
    if saleTicketData and saleTicketData.isRunning and saleTicketData:isRunning() then
        local refName = saleTicketData:getThemeName()
        local view = util_createFindView("Activity/" .. refName, {autoClose = true, noTouch = true})
        if view ~= nil then
            self:showUI(view, ViewZorder.ZORDER_UI)
            -- csc 2021年04月03日11:55:47 修改代码 后续换皮需要用最新的 BaseLayer 写法
            if view.setCloseCallBack then
                view:setCloseCallBack(
                    function()
                        if _overcall then
                            _overcall()
                        end
                    end
                )
            else -- 兼容老换皮,后续如果都采取了 BaseLayer 写法，这里就可以去掉了
                view:setOverFunc(
                    function()
                        if _overcall then
                            _overcall()
                        end
                    end
                )
            end
        else
            if _overcall then
                _overcall()
            end
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 尝试 弹出 新手期个人累充 界面
function ViewManager:trigger7DaysPurchase(_params, _overcall)
    if G_GetMgr(ACTIVITY_REF.SevenDaysPurchase):hasRewards() then
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_ACTIVITY_SEVEN_DAYS_PURCHASE_CLOSED)
                if _overcall then
                    _overcall()
                end
            end,
            ViewEventType.NOTIFY_ACTIVITY_SEVEN_DAYS_PURCHASE_CLOSED
        )
        G_GetMgr(ACTIVITY_REF.SevenDaysPurchase):showMainLayer()
    else
        if _overcall then
            _overcall()
        end
    end
end
-- 尝试 弹出 充值抽奖活动 界面
function ViewManager:triggerPurchaseDrawLayerFunc(_params, _overcall)
    -- 购买完小游戏 HAT TRICK DELUXE 活动 购买充值触发
    local manage = util_require("manager.Activity.ActivtiyPurchaseDrawManager"):getInstance()
    if manage:checkIsActive() then
        manage:addAutoPopMainLayerRefCount()
    end

    -- manage:checkPopMainLayer(handler(self, self.triggerFuncNext))
    manage:checkPopMainLayer(_overcall)
end

-- 弹出WILD CHALLENGE付费挑战 弹板
function ViewManager:triggerPopWildChallengeLayer(_params, _overcall)
    if not G_GetMgr(ACTIVITY_REF.WildChallenge):checkUncollectedTask() then
        if _overcall then
            _overcall()
        end
        return
    end

    local view = gLobalViewManager:getViewByExtendData("WildChallengeActMainLayer")
    if view then
        view:setLocalZOrder(view:getLocalZOrder() + 1)
        view:updateUI()
    else
        view = G_GetMgr(ACTIVITY_REF.WildChallenge):showMainLayer(true)
    end
    if view then
        view:setOverFunc(
            function()
                if _overcall then
                    _overcall()
                end
            end
        )
        return
    end

    if _overcall then
        _overcall()
    end
end

-- 弹出 DuckShot小游戏
function ViewManager:triggerDropDuckShot(_params, _overcall)
    local duckShotNewGame = G_GetMgr(ACTIVITY_REF.DuckShot):getNewCreateGameData("Purchase") --这里是来源

    local overFunc = function()
        if _overcall then
            _overcall()
        end
    end
    if table.nums(duckShotNewGame) > 0 then
        G_GetMgr(ACTIVITY_REF.DuckShot):showPlayTipLayer(overFunc)
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 弹出 弹珠小游戏
function ViewManager:triggerPinBallGO(_params, _overcall)
    local pinBallGoNewGame = G_GetMgr(ACTIVITY_REF.PinBallGo):getNewGameDataBySource("Purchase") --这里是来源

    local overFunc = function()
        if _overcall then
            _overcall()
        end
    end
    if table.nums(pinBallGoNewGame) > 0 then
        G_GetMgr(ACTIVITY_REF.PinBallGo):showPlayTipLayer(overFunc)
    else
        if _overcall then
            _overcall()
        end
    end
end

function ViewManager:triggerBingoBuff(_params, _overcall)
    if G_GetMgr(ACTIVITY_REF.Bingo):getRunningData() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BUY_BINGOPROMOTION_FINISH)
    end
    if _overcall then
        _overcall()
    end
end

function ViewManager:triggerGashpon(_params, _overcall)
    G_GetMgr(ACTIVITY_REF.Gashapon):showGainPointsLayer(
        function()
            if _overcall then
                _overcall()
            end
        end
    )
end

-- 付费任务自动领取
function ViewManager:triggerDIYFeatureMission(_params, _overcall)
    G_GetMgr(ACTIVITY_REF.DIYFeatureMission):showHardTaskMasterRewardLayer(
        function()
            if _overcall then
                _overcall()
            end
        end
    )
end

-- 掉落乐透券
function ViewManager:triggerDropLotteryTicket(_params, _overcall)
    local _overCall = function()
        if _overcall then
            _overcall()
        end
    end

    local lotteryData = G_GetMgr(G_REF.Lottery):getData()

    if not lotteryData then
        if _overcall then
            _overcall()
        end
        return
    end

    local tickets = G_GetMgr(G_REF.Lottery):getBuyTipDropTickets()
    if tickets > 0 then
        G_GetMgr(G_REF.Lottery):showTicketView(nil, _overCall, tickets)
        G_GetMgr(G_REF.Lottery):resetBuyTipDropTickets()
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 掉落快速点击小游戏道具
function ViewManager:triggerDropPiggyClickerGameItem(_params, _overcall)
    local _overCall = function()
        if _overcall then
            _overcall()
        end
    end

    local piggyClickerData = G_GetMgr(ACTIVITY_REF.PiggyClicker):getData()

    if not piggyClickerData then
        if _overcall then
            _overcall()
        end
        return
    end

    local bDropNew = piggyClickerData:checkIsGainNewGame()
    local newGameData = piggyClickerData:getNewGameData()
    if not bDropNew or not newGameData then
        if _overcall then
            _overcall()
        end
        return
    end

    G_GetMgr(ACTIVITY_REF.PiggyClicker):showGameDropItemLayer(newGameData, _overCall)
end

--扎气球掉落
function ViewManager:triggerDropDartsGameItem(_params, _overcall)
    local _overCall = function()
        if _overcall then
            _overcall()
        end
    end

    local dartsGameData = G_GetMgr(ACTIVITY_REF.DartsGame):getData()

    if not dartsGameData then
        if _overcall then
            _overcall()
        end
        return
    end

    local bDropNew = dartsGameData:checkIsGainNewGame()
    local newGameData = dartsGameData:getNewGameData()
    if not bDropNew or not newGameData then
        if _overcall then
            _overcall()
        end
        return
    end

    G_GetMgr(ACTIVITY_REF.DartsGame):showTriggerLayer(newGameData, _overCall)
end

--扎气球掉落
function ViewManager:triggerDropDartsGameItemNew(_params, _overcall)
    local _overCall = function()
        if _overcall then
            _overcall()
        end
    end

    local dartsGameData = G_GetMgr(ACTIVITY_REF.DartsGameNew):getData()

    if not dartsGameData then
        if _overcall then
            _overcall()
        end
        return
    end

    local bDropNew = dartsGameData:checkIsGainNewGame()
    local newGameData = dartsGameData:getNewGameData()
    if not bDropNew or not newGameData then
        if _overcall then
            _overcall()
        end
        return
    end

    G_GetMgr(ACTIVITY_REF.DartsGameNew):showTriggerLayer(newGameData, _overCall)
end

-- 连续充值面包主题，动效流程在购买掉卡结束后执行
function ViewManager:triggerKeepRecharge(_params, _overcall)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_KEEPRECHARGE_BUY_FINISH)
    if _overcall then
        _overcall()
    end
end

-- -- 任意一笔付费都会产生数据变化
-- function ViewManager:triggerReturnSignV2(_params, _overcall)
--     -- 如果是回归pass付费，在回归pass中处理
--     if globalData.iapRunData.p_lastBuyType == BUY_TYPE.RETURN_PASS then
--         if _overcall then
--             _overcall()
--         end
--         return
--     end
--     local data = G_GetMgr(G_REF.Return):getRunningData()
--     if not data then
--         if _overcall then
--             _overcall()
--         end
--         return
--     end
--     if not G_GetMgr(G_REF.Return):isActiveSignPurchase() then
--         if _overcall then
--             _overcall()
--         end
--         return
--     end
--     local view = G_GetMgr(G_REF.Return):showMainLayer(1, 1, {doubleSign = true}, _overcall)
--     if not view then
--         if _overcall then
--             _overcall()
--         end
--     end
-- end

-- quest跳过关卡时，完成回归签到的任务
function ViewManager:triggerReturnQuestTaskComplete(_params, _overcall)
    -- 如果是回归pass付费，在回归pass中处理
    if globalData.iapRunData.p_lastBuyType ~= BUY_TYPE.QUEST_SKIPSALE then
        if _overcall then
            _overcall()
        end
        return
    end
    local data = G_GetMgr(G_REF.Return):getRunningData()
    if not data then
        if _overcall then
            _overcall()
        end
        return
    end
    -- 是否有完成的quest任务
    local isComplete = false
    local autoList = {}
    local taskPageIndex = 1
    local questCompleteIndexs = data:getQuestTaskComplete()
    if questCompleteIndexs and #questCompleteIndexs > 0 then
        autoList.autoTaskQuest = questCompleteIndexs
        isComplete = true
        taskPageIndex = 3
    end
    if not isComplete then
        if _overcall then
            _overcall()
        end        
        return
    end
    -- 如果后续有quest完成弹框，回归界面中就不能跳转到Quest
    local noOpenQuest = true

    -- 打开回归签到V2
    local view = G_GetMgr(G_REF.Return):showMainLayer(3, taskPageIndex, autoList, _overcall, noOpenQuest)
    if not view then
        if _overcall then
            _overcall()
        end
    end
end

--大厅中跳转到下一关
function ViewManager:lobbyGotoLevelSceneByLevelId(id)
    --根据app版本检测关卡是否可以进入
    if not gLobalViewManager:checkEnterLevelForApp(id) then
        gLobalViewManager:showUpgradeAppView()
        return
    end
    local levelData = globalData.slotRunData:getLevelInfoById(id) -- 数据结构：MachineData
    if not levelData then
        return
    end
    --横竖屏
    if levelData.p_portraitFlag == true then
        globalData.slotRunData.isChangeScreenOrientation = true
        globalData.slotRunData:changeScreenOrientation(levelData.p_portraitFlag)
    end
    globalData.slotRunData.isDeluexeClub = levelData.p_highBetFlag
    globalData.slotRunData.machineData = levelData
    globalData.slotRunData.iLastBetIdx = -1   --高倍场没有值所以特殊处理

    gLobalSendDataManager:getLogSlots():initSlotLog()
    gLobalSendDataManager:getLogIap():setEntryGame(levelData.p_name)

    -- gLobalSendDataManager:getLogSlots():setEnterLevelTag(levelData.p_Log, levelData.p_link)
    gLobalSendDataManager:getLogSlots():setEnterLevelName(levelData.p_levelName, levelData.p_name)
    gLobalViewManager:gotoSceneByType(SceneType.Scene_Game)

end

function ViewManager:triggerBasicSaleWheel(_params, _overcall)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BASIC_WHEEL_REFRESH)
    
    if _overcall then
        _overcall()
    end
end

-- 付费目标
function ViewManager:triggerGetMorePayLessLayer(_params, _overcall)
    local gameData = G_GetMgr(ACTIVITY_REF.GetMorePayLess):getRunningData()
    if gameData then
        local activityOpen = gameData:getOpen()
        if activityOpen then
            local view = G_GetMgr(ACTIVITY_REF.GetMorePayLess):showMainLayer({buyShow = true, closeFunc = _overcall})
            if not view then
                if _overcall then
                    _overcall()
                end
            end
        else
            if _overcall then
                _overcall()
            end
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 赛季末返新卡
function ViewManager:triggerGrandFinaleTaskComplete(_params, _overcall)
    local isExecute = G_GetMgr(ACTIVITY_REF.GrandFinale):checkCollectReward()
    if isExecute then
        local view = G_GetMgr(ACTIVITY_REF.GrandFinale):showMainLayer({purchase = true, closeFunc = _overcall})
        if not view then
            if _overcall then
                _overcall()
            end
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

function ViewManager:trigger4BdayDrawWheelLayer(_params, _overcall)
    local flag = G_GetMgr(ACTIVITY_REF.dayDraw4B):checkWheelData()
    if flag then
        local view = G_GetMgr(ACTIVITY_REF.dayDraw4B):showWheelLayer({closeFunc = _overcall})
        if not view and _overcall then
            _overcall()
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 限时膨胀 任务完成
function ViewManager:triggerTimeLimitExpansionTaskComplete(_params, _overcall)
    local isExecute = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion):checkIsCompletePayTask()
    if isExecute then
        local view = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion):showMainLayer({purchase = true, closeFunc = _overcall})
        if not view then
            if _overcall then
                _overcall()
            end
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 尝试弹出三联优惠券弹框
function ViewManager:triggerCouponRewardsLayer(_params, _overcall)
    local saleTicketData = G_GetMgr(ACTIVITY_REF.CouponRewards):getRunningData()
    if saleTicketData then
        local showFlag = G_GetMgr(ACTIVITY_REF.CouponRewards):checkOpenLayer()
        if showFlag then
            local view = G_GetMgr(ACTIVITY_REF.CouponRewards):showMainLayer({storeShow = true, closeFunc = _overcall})
            if not view then
                if _overcall then
                    _overcall()
                end
            end
        else
            if _overcall then
                _overcall()
            end
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 新版小猪挑战
function ViewManager:triggerPiggyGoodiesLayer(_params, _overcall)
    local isOpen = G_GetMgr(ACTIVITY_REF.PiggyGoodies):checkOpenMainLayer()
    if isOpen then
        local view = G_GetMgr(ACTIVITY_REF.PiggyGoodies):showMainLayer({closeFunc = _overcall})
        if not view then
            if _overcall then
                _overcall()
            end
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 圣诞新聚合商店 金色商品解锁
function ViewManager:triggerHolidayStore(_params, _overcall)
    local data = G_GetMgr(ACTIVITY_REF.HolidayStore):getRunningData()
    if data then
        local view = G_GetMgr(ACTIVITY_REF.HolidayStore):showtriggerHolidayStore(_overcall)
        if not view then
            if _overcall then
                _overcall()
            end
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

function ViewManager:triggerHolidayPassProgressLayer(_params, _overcall)
    local mgr = G_GetMgr(ACTIVITY_REF.HolidayPass)
    if mgr then
        local view = mgr:showProgressLayer({overFunc = _overcall})
        if not view then
            if _overcall then
                _overcall()
            end
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

function ViewManager:triggerRoutineSaleWheel(_params, _overcall)
    if gLobalViewManager:getViewByExtendData("RoutineSaleMainLayer") then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ROUTINE_SALE_WHEEL_UPDATE)

        if _overcall then
            _overcall()
        end
    else
        local data = G_GetMgr(G_REF.RoutineSale):getRunningData()
        if data and data:hasWheelRward() then
            local params = {}
            params.baseCoins = data:getWheelBaseCoins()
            params.maxUsd = data:getWheelMaxUsd()
            params.wheelChunk = data:getWheelChunk()
            params.count = data:getWheelAllPro()
            params.wheelReward = data:getWheelReward()
            params.isReward = true
            params.overcall = _overcall
            G_GetMgr(G_REF.RoutineSale):showTurntableLayer(params)
            return
        end

        if _overcall then
            _overcall()
        end
    end
end

-- 圣诞充值分奖
function ViewManager:triggerXmasCraze2023Mgr(_params, _overcall)
    local data = G_GetMgr(ACTIVITY_REF.XmasCraze2023):getRunningData()
    if data then
        local view = G_GetMgr(ACTIVITY_REF.XmasCraze2023):showMainLayer(true,
            function()
                if _overcall then
                    _overcall()
                end
            end
        )
        if not view then
            if _overcall then
                _overcall()
            end
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

-- 圣诞累充分奖
function ViewManager:triggerXmasSplit2023(_params, _overcall)
    local data = G_GetMgr(ACTIVITY_REF.XmasSplit2023):getRunningData()
    if data then
        local view = G_GetMgr(ACTIVITY_REF.XmasSplit2023):showMainLayer(true,
            function()
                if _overcall then
                    _overcall()
                end
            end
        )
        if not view then
            if _overcall then
                _overcall()
            end
        end
    else
        if _overcall then
            _overcall()
        end
    end
end

return ViewManager
