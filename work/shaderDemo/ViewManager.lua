local ViewManager = class("ViewManager")
local LuaList = require("GameControl.LuaList")
GD.SceneType = {
    Scene_Logon     = 1, -- 登录
    Scene_Lobby     = 2, -- 大厅
    Scene_Game      = 3, -- 游戏 slots
    Scene_Quest     = 4,
    Scene_LAUNCH    = 5, -- 进入大厅或游戏时的 loading 界面
    Scene_VerticalPhysics3D = 6, -- 含有物理引擎的竖版3D场景 目前用于CoinPusher场景
    -- Scene_HorizonPhysics3D  = 7, -- 含有物理引擎的横版3D场景

}

GD.ViewZorder = {
    ZORDER_GAME = 0, --游戏轮盘逻辑弹版都是默认值0 例如fsstart over弹版 respin bigewin unlock uplevel等
    ZORDER_UI = 1000, --系统UI弹版 例如邮件商店小猪银行任务等
    ZORDER_SHOPUI = 1500,--商城购买完成之后的
    ZORDER_GUIDE = 2000, --引导UI
    ZORDER_SPECIAL = 10000, --特殊层级 顶部层级 飞金币飞特效等
    ZORDER_LOADING = 20000, --loadign层级 加载网络时的loading遮罩
    ZORDER_NETWORK = 30000, --网络层级 提示性弹窗 例如登录失败 网络连接失败
    ZORDER_PIAOCHUANG = 2500, --工会飘窗
}

GD.LOGTYPE = 
{
    lobby = "lobby",
    hall = "hall",
    slide = "slide",
    show = "show",
    game = "game",
}

-- 特殊slot机器类型
GD.SpecialMachine = {
    [1] = "PhysicsScene"
}

ViewManager.m_instance = nil
ViewManager.m_currentScene = nil -- 当前场景
ViewManager.p_ViewLayer = nil --  显示UI 使用的层

ViewManager.m_viewPool = nil --
ViewManager.m_isResumeStatus = nil --促销闪退问题

--p_ViewLayer child 类型
local ViewType = {
    TYPE_UI = 100,  --UI弹窗tag
}

--暂停老虎机不允许其他系统resume老虎机的系统名称
ViewManager.kViewManager_PauseMachineSystemMap =
{
    ["CardNadoWheelMainUI"] = true,
    ["CollectPop"] = true,
    ["CollectMaxPop"] = true,
    ["BlastMainUI"] = true,
    ["BingoMainUI"] = true,
    ["MapMain"] = true,
    ["FishdomMainUI"] = true,
    ["MapMainUI"] = true,
    ["CateenMainUI"] = true,
    ["CoinPusherMainUI"] = true,
    ["PlinkoMainUI"] = true,
}

--  2023-08-24 用来存储需要的节点的世界坐标 方便各个地方使用  升级里程碑的时候移植jfs
GD.NodeWorldPosType =
{
    LobbyTop_Head = "LobbyTop_Head", -- 大厅头像
    TopNode_Level_Label = "TopNode_Level_Label", --等级条上的等级文本
    TopNode_Center  = "TopNode_Center", --topui的中点
    TopNode_Wheel = "TopNode_Wheel", -- topui 像写轮眼的那个节点
    GameBtmNodeBetLabel = "GameBtmNodeBetLabel", --关卡内底部bet节点文本
    GameBtmNodeWinCoinsLabel = "GameBtmNodeWinCoinsLabel",--关卡内部赢钱节点文本
    BigActivityEntryNodePos = "BigActivityEntryNodePos", -- 大活动入口节点
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
    self.m_triggerFuncList = LuaList.new()
    self.m_triggerFuncCount = -1
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

function ViewManager:isVerticalPhysics3D()
    return self.m_currentScene == SceneType.Scene_VerticalPhysics3D
end

function ViewManager:pushView(sceneType)
end

--loading中返回大厅
function ViewManager:gotoLobbyByLunch()
    self.m_currentScene = SceneType.Scene_Game
    gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
end
function ViewManager:gotoSceneByType(sceneType,noPushView)
    --跳转场景 中断触发弹窗逻辑
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TRIGGER_END)
    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER,true) --弹窗逻辑执行结束回调 flag 是否不执行结束回调
    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    globalNoviceGuideManager:clearGuide()
    gLobalQuestManager:clearData()
    gLobalAdsControl:removeAdTimerHandler()
    globalData.slotRunData.m_autoNum = 0
    globalData.slotRunData.m_isAutoSpinAction = false
    globalData.slotRunData.m_isFastSpin = false
    globalData.slotRunData.b_openFastSpin = false  
    gLobalViewManager:triggerFuncClear()
    --跳转场景调用一下退出集卡系统
    if CardSysManager and CardSysManager.exitCard then
        CardSysManager:exitCard()
    end
    
    -- 跳转场景时成就不再弹出，数据清理一下
    if GD.JMS_MedalManager and GD.JMS_MedalManager.setNeedShowRewardList then
        GD.JMS_MedalManager:setNeedShowRewardList(nil)
    end

    -- levelchase 在切换场景后清除数据
    if jmsLevelChaseManager then
        jmsLevelChaseManager:resetNewOpen()
        jmsLevelChaseManager:resetReward()
        if jmsPinataChallengeManager then
            jmsPinataChallengeManager:resetReward()
        end
    end
    -- levelchasenew 在切换场景后清除数据
    if jmsLevelChaseNewManager then
        jmsLevelChaseNewManager:resetNewOpen()
        jmsLevelChaseNewManager:resetReward()
        if jmsPinataChallengeManager then
            jmsPinataChallengeManager:resetReward()
        end
    end
    if jmsGoldRushManager then
        jmsGoldRushManager:setTaskExtra(nil)
    end
    
    local sceneLayer = nil

    if sceneType == SceneType.Scene_Lobby and globalData.slotRunData.isPortrait == true then
        globalData.slotRunData.isChangeScreenOrientation = true
        globalData.slotRunData:changeScreenOrientation(false)
    end
    if sceneType == SceneType.Scene_Logon then
        sceneLayer = util_createView("GameModule.jmsLogon.JMSLogonLoading")
    else
        local launchLayer = self:checkShowLaunchLayer(sceneType)

        if launchLayer == nil then -- 表明从logon 界面进入到大厅
            if sceneType == SceneType.Scene_Lobby then
                self:logonToLobby(sceneType,noPushView)
                return
            end

            if sceneType == SceneType.Scene_VerticalPhysics3D then
                -- 切换为竖屏
                globalData.slotRunData.isChangeScreenOrientation = true
                if globalData.slotRunData.isPortrait ~= true then
                    globalData.slotRunData:changeScreenOrientation(true)
                end
                -- <刘阳 2021-04-01添加 这里需要清除一下>
                globalMachineController:onExit()

                self:changeScene(sceneType, nil)
                return
            end
        else
            --游戏返回到大厅
            if sceneType == SceneType.Scene_Lobby then
                local levelName = globalData.slotRunData.machineData.p_levelName
                gLobalSendDataManager:getLogSlots():sendEnterGameLog(LOG_ENUM_TYPE.GameEnter_LevelExit,levelName)
                gLobalSendDataManager:getLogIap():setEntryType("lobby")
            end
            -- lobby 和 game 的加载放到 launch layer 里面去
            sceneLayer = launchLayer
            sceneType = SceneType.Scene_LAUNCH
        end
    end

    if sceneLayer == nil then
        release_print("enter level is nil")
        return
    end

    --每次进入关卡设置新的gssid
    GD.jmsRecordManager:setLevelSsid()

    self:changeScene(sceneType, sceneLayer)
end

--登录到大厅
function ViewManager:logonToLobby(sceneType,noPushView)
    gLobalSendDataManager:getLogIap():setEntryType("lobby")
    local startTime = xcyy.SlotsUtil:getMilliSeconds()
    local pushView = true
    if noPushView then -- 推币机(danzhu)返回到大厅不弹弹窗总控<lzc>
        pushView = nil
    end
    local sceneLayer = util_createView("GameModule.jmsLobby.JMSLobbyView", pushView)
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
                else
                    actUpdate:stop()
                    local extra = {}
                    if gLobalSendDataManager:getIsFbLogin() then
                        extra.logonWay = "Facebook"
                    else
                        extra.logonWay = "Guest"
                    end

                    self:changeScene(sceneType, sceneLayer)
                    sceneLayer:release()
                end
            end,
            0.05
        )
    else
        self:changeScene(sceneType, sceneLayer)
        sceneLayer:release()
    end
end

function ViewManager:isPauseAndResumeMachine(ui)
    local viewChilds = self.p_ViewLayer:getChildren()
    local flag = true
    for k,v in ipairs(viewChilds) do
        if v.getExtendData ~= nil then
            local extendData = v:getExtendData()
            if extendData ~= nil and (ui == nil or ui.getExtendData == nil or ui:getExtendData() ~= extendData) and ViewManager.kViewManager_PauseMachineSystemMap[extendData] then
                flag = false
                break
            end
        end
    end
    return flag
end

function ViewManager:transitionScene(sceneType,sceneLayer,delayTime)
    local preScene = self.curScene
    local newScene = nil--display.newScene(sceneType)
    if sceneType == SceneType.Scene_VerticalPhysics3D then
        -- 活动为物理场景
        if GD.CoinPusher2Manager and GD.CoinPusher2Manager:isRunning() then
            newScene = GD.CoinPusher2Mgr:GoToCoinPusher2( true )
        elseif GD.coinPusherManager and GD.coinPusherManager:isRunning() then
            newScene = GD.CoinPusherMgr:GoToCoinPusher( true )
        elseif GD.plinkoManager then
            newScene = GD.plinkoManager:goToPlinko( true )
        end
    else
        if sceneType == SceneType.Scene_Game then
            local machineData = globalData.slotRunData:getLastEnterLevelInfo()
            local sepcialGameType = machineData.p_sepcialGameType
            if sepcialGameType then
                newScene = display.newScene(sceneType, {physics = true})

                local phyWorld = newScene:getPhysicsWorld()
                if phyWorld then
                    phyWorld:setAutoStep(false)
                end
            else
                newScene = display.newScene(sceneType)
            end
        else
            newScene = display.newScene(sceneType)
        end
    end

    self.curScene = newScene
    if sceneLayer ~= nil then

        -- test by tm --
        if sceneType == SceneType.Scene_Game then
            if tolua.isnull( sceneLayer ) then
                release_print("HolyShit. ViewManager:transitionScene begin addChild .But no node." )
            end
            newScene:addChild(sceneLayer)
            release_print("HolyShit. ViewManager:transitionScene addChild sceneLayer OK " )
        else
            newScene:addChild(sceneLayer)
        end

    end

    local function releaseCacheData()
        if sceneType == SceneType.Scene_LAUNCH or
            -- sceneType == SceneType.Scene_Lobby or
            sceneType == SceneType.Scene_Logon then
            xcyy.SlotsUtil:releaseSpineCacheData()
            cc.Director:getInstance():purgeCachedData()
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_SCENE_OVER)
    end

    if delayTime ~= nil then
        self:runScene(newScene,"FADE",delayTime)
    else
        self:runScene(newScene)
    end

    if preScene ~= nil and sceneType == SceneType.Scene_LAUNCH then
        local exitNode = cc.Node:create()
        preScene:addChild(exitNode)
        exitNode:registerScriptHandler(
        function(event)
            if event == "cleanup" then
                util_afterDrawCallBack(releaseCacheData)
            end
        end)
    else
        -- util_afterDrawCallBack(releaseCacheData)
        releaseCacheData()
    end
end

---
-- 切换场景
--
function ViewManager:changeScene(sceneType, sceneLayer)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    self.m_currentScene = sceneType
    if jmsMegaWinWheelManager then
        jmsMegaWinWheelManager:clearData()
    end
    if globalData.slotRunData.isChangeScreenOrientation == true or globalData.slotRunData.isChangeScreenOrientation == nil then
        globalData.slotRunData.isChangeScreenOrientation = false
        self:transitionScene(sceneType,sceneLayer)
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
        end

        self:transitionScene(sceneType, sceneLayer, time)
    end
end

--[[
    @desc: 检测是否需要显示 launch layer
    time:2018-07-04 20:17:10
    @return:
]]
function ViewManager:checkShowLaunchLayer(sceneType)
    if self.m_currentScene == SceneType.Scene_Logon
    or (sceneType == SceneType.Scene_VerticalPhysics3D)
    or (self.m_currentScene == SceneType.Scene_VerticalPhysics3D and sceneType == SceneType.Scene_Lobby)
    then
        return nil
    end

    local layer = util_createView("GameModule.jmsLoading.JMSLoadingLayer", {curScene = self.m_currentScene, nextScene = sceneType})
    return layer
end

---
-- UI 处理函数
--
-- @param uiNode 显示的ui 节点
function ViewManager:showUI(uiNode,zorder,showTouchLayer)
    if uiNode == nil then
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
            gLobalSendDataManager:getLogPopub():pushUrlKey(uiNode.__cname,DotUrlType.ViewName,false)
        end
    end

    uiNode.m_showTouchLayer = showTouchLayer
    printInfo("xcyy ViewManager:showUI 111 : %s", uiNode.__cname)
    if zorder then
        self.p_ViewLayer:addChild(uiNode, zorder) -- 是否添加在最上层
    else
        self.p_ViewLayer:addChild(uiNode)
    end

    uiNode.viewType = ViewType.TYPE_UI
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = uiNode})
end

function ViewManager:getViewByTag(tag)
    local view =  self.p_ViewLayer:getChildByTag(tag)
    return view
end

function ViewManager:getViewByExtendData(data)
    local viewChilds = self.p_ViewLayer:getChildren()
    for k,v in ipairs(viewChilds) do
        if v.getExtendData ~= nil and v:getExtendData() == data then
            return v
        end
    end
    return nil
end


function ViewManager:getHasShowUI()
    local viewChilds = self.p_ViewLayer:getChildren()
    for i=1, #viewChilds do
        local view = viewChilds[i]
        if view.viewType and view.viewType == ViewType.TYPE_UI then
            return true
        end
    end
    return false
end

--csb_path csb路径 okFunc确定按钮回调 otherFunc取消按钮回调 isHold 点击后是否保留弹窗
--使用例子: gLobalViewManager:showDialog("Dialog/xxxxx.csb")
function ViewManager:showDialog(csb_path, okFunc, otherFunc, isHold,zorder)
    local view = util_createView("GameModule.jmsDialogs.JMSDialogLayer", csb_path, okFunc, otherFunc, isHold)
    if zorder then
        gLobalViewManager:showUI(view,zorder)
    else
        gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
    end

    return view
end

-- 账号异常，登陆警告
function ViewManager:showLoginWarning(okFunc)
    local csbPath = GD.jmsLocalizationManager:getLobbyLocalizationInfo(40032).Param
    local btnContact = function ( )
        gLobalViewManager:removeLoadingAnima()
         --通知界面去打开 aihelp
         globalData.skipForeGround = true
         globalPlatformManager:openAIHelpRobot()
        --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OPEN_ROBOT)
    end
    local view = gLobalViewManager:showDialog( csbPath,function()
        if okFunc then
            okFunc()
        end
    end,btnContact,isHold,ViewZorder.ZORDER_NETWORK)
end

-- 账号异常，登陆封禁
function ViewManager:showLoginForbid(forbidTime)
    local csbPath = GD.jmsLocalizationManager:getLobbyLocalizationInfo(40031).Param
    local btnContact = function ( )
        gLobalViewManager:removeLoadingAnima()
         --通知界面去打开 aihelp
        --  globalData.skipForeGround = true
         globalPlatformManager:openAIHelpRobot()
        --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OPEN_ROBOT)
    end
    local view = gLobalViewManager:showDialog( csbPath,function()
        local director = cc.Director:getInstance()
        director:endToLua()
    end,btnContact,isHold,ViewZorder.ZORDER_NETWORK)
    -- 显示解封倒计时
    view:showUnlockTime(forbidTime)
end

--显示断线重新连接
function ViewManager:showReConnect(isHold)
    --清理引导防止不能点击
    if globalNoviceGuideManager ~= nil then
        globalNoviceGuideManager:clearGuide()
    end
    local csbName = GD.jmsLocalizationManager:getLobbyLocalizationInfo( 40027 ).Param

    local btnContact = function ( )
        gLobalViewManager:removeLoadingAnima()
         --通知界面去打开 aihelp
         globalData.skipForeGround = true
         globalPlatformManager:openAIHelpRobot()
        --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OPEN_ROBOT)
    end
    local view = gLobalViewManager:showDialog( csbName,function()
        util_restartGame()
        if gLobalGameHeartBeatManager then
            gLobalGameHeartBeatManager:stopHeartBeat()
        end
    end,btnContact,isHold,ViewZorder.ZORDER_NETWORK)
    if view.setEnableOnkeyBack then
        view:setEnableOnkeyBack(false)
    end
end

--显示关卡维护中弹窗
function ViewManager:showMaintain()
    local csbName = GD.jmsLocalizationManager:getLobbyLocalizationInfo( 40023 ).Param
    local view = util_createView("GameModule.jmsDialogs.JMSDialogLayer", csbName,function()
        if globalNoviceGuideManager.guideBubbleReturnLobbyPopup then
            globalNoviceGuideManager.guideBubbleReturnLobbyPopup = nil
        end
        if globalData.slotRunData.machineData then
            globalData.slotRunData:changeLevelsMaintain(globalData.slotRunData.machineData.p_id,true)
        end
        if gLobalSendDataManager:getLogGuide():isGuideBegan(5) then
            gLobalSendDataManager:getLogGuide():sendGuideLog(5, 2)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_GAME_LOADING)
        gLobalViewManager:gotoLobbyByLunch()
    end,nil,true)
    display.getRunningScene():addChild(view,ViewZorder.ZORDER_NETWORK)
    if view.setEnableOnkeyBack then
        view:setEnableOnkeyBack(false)
    end
end


---
-- UI 处理函数
--
-- @param 添加最上层遮罩 是否创建不可见的loading
function ViewManager:addLoadingAnima(isHide)
    local loadingMaskLayer = util_newMaskLayer(false)
    loadingMaskLayer:setOpacity(178)

    local loadingIcon = display.newSprite("Public_Common/Other/common_loading_0.png")
    loadingIcon:setPosition(cc.p(display.width / 2, display.height / 2))
    loadingIcon:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, 360)))
    loadingIcon:setScale(1 / loadingMaskLayer:getScale())
    loadingMaskLayer:addChild(loadingIcon)
    self.p_ViewLayer:addChild(loadingMaskLayer, ViewZorder.ZORDER_LOADING, ViewZorder.ZORDER_LOADING)

    --隐藏loading
    if isHide == true then
        loadingMaskLayer:setOpacity(0)
        loadingIcon:setVisible(false)
    else
        performWithDelay(loadingMaskLayer,function ()
            GD.jmsRecordManager:sendTurnTimeOutLog()
        end,10)
    end
end

-- 延迟loading notNeedLoadingIcon:true 不显示loadingIcon
function ViewManager:addLoadingAnimaDelay( notNeedLoadingIcon )
    local loadingMaskLayer = util_newMaskLayer(false)
    loadingMaskLayer:setOpacity(0)
    self.p_ViewLayer:addChild(loadingMaskLayer, ViewZorder.ZORDER_LOADING, ViewZorder.ZORDER_LOADING)

    local hasLoadingIcon = true
    if notNeedLoadingIcon then
        hasLoadingIcon = false
    end

    if hasLoadingIcon then
        local loadingIcon = display.newSprite("Public_Common/Other/common_loading_0.png")
        loadingIcon:setPosition(cc.p(display.width / 2, display.height / 2))
        loadingIcon:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, 360)))
        loadingIcon:setOpacity(0)
        loadingIcon:setScale(1 / loadingMaskLayer:getScale())
        loadingMaskLayer:addChild(loadingIcon)

        util_performWithDelay(loadingMaskLayer,
        function()
            loadingMaskLayer:setOpacity(178)
            loadingIcon:setOpacity(255)
        end,1)
        performWithDelay(loadingMaskLayer,function ()
            GD.jmsRecordManager:sendTurnTimeOutLog()
        end,11)
    end
end

---
-- UI 处理函数
--
-- @param 删除最上层遮罩
function ViewManager:removeLoadingAnima()
    local loadingMaskLayer = self.p_ViewLayer:getChildByTag(ViewZorder.ZORDER_LOADING)
    if not loadingMaskLayer then
        loadingMaskLayer = display.getRunningScene():getChildByTag(ViewZorder.ZORDER_LOADING)
    end
    if loadingMaskLayer then
        loadingMaskLayer:removeFromParent()
    end
end

function ViewManager:hasLoadingAnima()
    local loadingMaskLayer = self.p_ViewLayer:getChildByTag(ViewZorder.ZORDER_LOADING)
    if not loadingMaskLayer then
        loadingMaskLayer = display.getRunningScene():getChildByTag(ViewZorder.ZORDER_LOADING)
    end
    return loadingMaskLayer ~= nil
end

function ViewManager:runScene(scene,transitiond, time, more)
    display.runScene(scene,transitiond, time, more)
    self:addOnkeyBackListener(scene)
    globalEventKeyControl:clearKeyBack()
end

function ViewManager:addOnkeyBackListener(scene)
    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(handler(self,self.onKeyboard), cc.Handler.EVENT_KEYBOARD_RELEASED)
    local eventDispatcher =scene:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener,scene)
end

function ViewManager:onKeyboard(code, event)

    if code == cc.KeyCode.KEY_BACK then
        print("你点击了返回键")
        local loadingMaskLayer = self.p_ViewLayer:getChildByTag(ViewZorder.ZORDER_LOADING)
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
            local textureCache    = cc.Director:getInstance():getTextureCache():getCachedTextureInfo()
            dumpStrToDisk( textureCache,"-------> textureCache = ",20 )

            local lastRow  = string.find( textureCache , "TextureCache" ) - 1
            local strSize  = string.len( textureCache )
            local cacheStr = string.sub(textureCache, lastRow - strSize )

            print( ""..cacheStr )
            print("请到以下路径查看纹理内存 "..device.writablePath.."/JmsLog.json")


            if tolua.isnull(self.textureCacheText) == true then

                self.textureCacheText = cc.Label:createWithSystemFont( ""..cacheStr , "", 12)
                self.textureCacheText:setAnchorPoint( cc.p(0,0) )
                self.textureCacheText:setPosition( cc.p( 0 , 0 ) )
                display:getRunningScene():addChild( self.textureCacheText )

            else
                self.textureCacheText:removeFromParent()
                self.textureCacheText = nil
                print("关闭纹理内存")
            end

        end
    elseif code == cc.KeyCode.KEY_Q then
        
        if self:isLevelView() or self:isLobbyView() then
            util_TestGotoLevel()
        end
    elseif code == cc.KeyCode.KEY_S then
        require "Shader.ShaderManager"
        ShaderManager:showTestLayer()
    elseif code == cc.KeyCode.KEY_V then
        package.loaded['debug.tools.VideoTestLayer'] = nil
        local ShaderTestLayer = require "debug.tools.VideoTestLayer"
        local layer = ShaderTestLayer:create()
        cc.Director:getInstance():getRunningScene():addChild(layer,0xffffff)
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

    local createCoinFlyView = function(  )
        local view = util_createView("GameModule.jmsLobby.JMSGameCoinFlyView")
        view:setName("viewCoinFly")
        return view
    end
    local viewCoinFly = self.p_ViewLayer:getChildByName("viewCoinFly")
    if not viewCoinFly then
        viewCoinFly = createCoinFlyView()
        self.p_ViewLayer:addChild(viewCoinFly, ViewZorder.ZORDER_SPECIAL) -- 是否添加在最上层
    end

    return viewCoinFly
end

-- 飞钻石页面
function ViewManager:getFlyDiamondsView()

    local createGemFlyView = function(  )
        local view = util_createView("GameModule.jmsLobby.JMSFlyDiamondsView")
        view:setName("viewDiamondsFly")
        return view
    end
    local viewCoinFly = self.p_ViewLayer:getChildByName("viewDiamondsFly")
    if not viewCoinFly then
        viewCoinFly = createGemFlyView()
        self.p_ViewLayer:addChild(viewCoinFly, ViewZorder.ZORDER_SPECIAL) -- 是否添加在最上层
    end

    return viewCoinFly
end

function ViewManager:pubPlayFlyCoin(startPos,endPos,baseCoinValue,addCoinValue,func,bShowBgColor,newCountNum,flyType,newFlyTime, newSpanTime,bHideOriginEffect,bgC4fColor)
    local viewCoinFly = self:getFlyCoinsView()
    viewCoinFly:pubPlayFlyCoin(startPos,endPos,baseCoinValue,addCoinValue,func,bShowBgColor,newCountNum,flyType,newFlyTime, newSpanTime,true,bgC4fColor)
    return viewCoinFly
end

function ViewManager:pubPlayFlyDiamonds(startPos,endPos,baseGemValue,addGemValue,func,bShowBgColor,newCountNum,flyType,newFlyTime, newSpanTime,bHideOriginEffect,bgC4fColor)
    local viewCoinFly = self:getFlyDiamondsView()
    viewCoinFly:pubPlayFlyGem(startPos,endPos,baseGemValue,addGemValue,func,bShowBgColor,newCountNum,flyType,newFlyTime, newSpanTime,true,bgC4fColor)
    return viewCoinFly
end

---------------------------------------------------------------------------------------------------------
--2020-5-27 用户全部更新新飞金币接口后可删除
function ViewManager:flyCoins(startPos,endPos,flyType,func,countNum,newFlyTime,spanTime)
    gLobalSoundManager:playSound("Sounds/flying_coins.mp3")
    local flyNode = cc.Node:create()
    self.p_ViewLayer:addChild(flyNode, ViewZorder.ZORDER_SPECIAL) -- 是否添加在最上层
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
    for i=1,count do
        self:runFlyCoinsAction(flyNode,time*i,flyTime,startPos,endPos,flyType)
    end
    performWithDelay(flyNode,function()
        if func then
            func()
        end
        flyNode:removeFromParent()
    end,flyTime+time*count)
end

function ViewManager:runFlyCoinsAction(flyNode,time,flyTime,startPos,endPos,flyType)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local node,csbAct=util_csbCreate("JMSGameLobby/csd/lobby/JMSFlyCoins.csb")
    node:setVisible(false)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
        if not flyType then
            util_csbPlayForKey(csbAct,"idle")
        elseif flyType == 1 then
            util_csbPlayForKey(csbAct,"idle2")
        end
    end)
    flyNode:addChild(node)

    node:setPosition(startPos)
    if not flyType then
        local bez=cc.BezierTo:create(flyTime,{cc.p(endPos.x,startPos.y+(endPos.y-startPos.y)*0.3),
        cc.p(startPos.x,startPos.y+(endPos.y-startPos.y)*0.5),endPos})
        actionList[#actionList + 1] = bez
    elseif flyType == 1 then
        local bez=cc.BezierTo:create(flyTime,{cc.p(startPos.x-(startPos.x-endPos.x)*0.3,startPos.y-100),
        cc.p(startPos.x-(startPos.x-endPos.x)*0.6,startPos.y+50),endPos})
        actionList[#actionList + 1] = bez
    elseif flyType == 2 then

    end
    node:runAction(cc.Sequence:create(actionList))
end
---------------------------------------------------------------------------------------------------------

function ViewManager:flyImage(path,startPos,endPos,scale,func)
    local flyNode = cc.Node:create()
    self.p_ViewLayer:addChild(flyNode, ViewZorder.ZORDER_SPECIAL) -- 是否添加在最上层
    local time = 0.03
    local count = 5
    local flyTime = 0.5
    for i=1,count do
        self:runFlyImageAction(path,flyNode,time*i,flyTime,scale,startPos,endPos)
    end

    local sp = display.newSprite(path)
    flyNode:addChild(sp)
    sp:setPosition(startPos)
    sp:runAction(cc.EaseExponentialIn:create(cc.MoveTo:create(flyTime,endPos)))
    -- sp:runAction(cc.FadeTo:create(flyTime,50))
    sp:runAction(cc.ScaleTo:create(flyTime,scale))
    performWithDelay(flyNode,function()
        if func then
            func()
        end
    end,flyTime)

    performWithDelay(flyNode,function()
        flyNode:removeFromParent()
    end,flyTime+time*count+1)
end

function ViewManager:runFlyImageAction(path,flyNode,time,flyTime,scale,startPos,endPos)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local sp = display.newSprite(path)
    -- local sp =cc.MotionStreak:create(0.3, 1, 128, cc.c3b(255,255,255),path)
    sp:setVisible(false)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        sp:setVisible(true)
        sp:runAction(cc.FadeTo:create(flyTime+0.5-time,50))
        sp:runAction(cc.ScaleTo:create(flyTime,scale))
    end)
    flyNode:addChild(sp)
    sp:setPosition(startPos)
    actionList[#actionList + 1] = cc.EaseExponentialIn:create(cc.MoveTo:create(flyTime,endPos))
    sp:runAction(cc.Sequence:create(actionList))
end

function ViewManager:flyImage(path,startPos,endPos,scale,func)

end

--是否处于暂停中，这个函数没用了
function ViewManager:isViewPause()
    return false
end

--暂停背景界面 需要传入暂停的界面
function ViewManager:showPauseUI(path,...)
    local view = util_createView(path,...)
    self:showUI(view,ViewZorder.ZORDER_UI)
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
function ViewManager:addAutoCloseTips(node,closeFunc,isTouchEnd,closeTime)
    if not node then
        return
    end

    -- 屏蔽延时，因为添加延时后，0.5s内点击后不会关闭界面
    local isCloseTips = false
    local layer = cc.Layer:create()
    layer:onTouch(function(event)
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
            closeFunc= nil
        end
        return true
    end, false, true)
    gLobalViewManager.p_ViewLayer:addChild(layer,ViewZorder.ZORDER_SPECIAL)
    if not closeTime then
        closeTime = 5
    end

    -- 定义倒计时关闭界面
    performWithDelay(node,function()
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
            closeFunc= nil
        end
    end,closeTime)
    return layer
end
--node飞行的图片或者粒子,startPos开始坐标,endPos停止坐标,flyTime飞行时间,func结束回调
function ViewManager:flySpecialNode(node,startPos,endPos,flyTime,func)
    if not node then
        return
    end
    if not flyTime then
        flyTime = 1
    end
    local actionList = {}
    local tempPos = cc.p(endPos.x-300,endPos.y+300)
    local bez1=cc.BezierTo:create(flyTime*0.5,{startPos,cc.p(startPos.x,endPos.y+300),tempPos})
    actionList[#actionList + 1] = bez1
    local bez2=cc.BezierTo:create(flyTime*0.5,{tempPos,cc.p(tempPos.x-200,endPos.y),endPos})
    actionList[#actionList + 1] = bez2
    if func then
        actionList[#actionList + 1] = cc.CallFunc:create(func)
    end
    node:runAction(cc.Sequence:create(actionList))
end


--当前版本是否可以玩关卡
function ViewManager:checkEnterLevelForApp(id)
    if globalData.slotRunData.p_machineDatas and #globalData.slotRunData.p_machineDatas > 0 then
        local info = nil
        for i=1,#globalData.slotRunData.p_machineDatas do
            local newInfo = globalData.slotRunData.p_machineDatas[i]
            if newInfo.p_id == id then
                info = newInfo
                break
            end
        end
        if not info then
            return false
        end
        if not info.p_openAppVersion or util_isSupportVersion(info.p_openAppVersion) then
            --没有配置 或者配置版本可支持
            return true
        end
    end
    return false
end
--显示提升版本界面
function ViewManager:showUpgradeAppView()
    local view = gLobalViewManager:showDialog( "JMSGuide/csd/UpgradeAppView/JMSUpgradeAppView.csb",function()
        GD.upGradeApp()
    end,nil,false,ViewZorder.ZORDER_NETWORK)
end

--执行一系列方法
-- funcdata = {func = 需要执行的方法,params = 参数}
--funcList = {funcdata1,funcdata2,funcdata3}
function ViewManager:checkTriggerList(funcList,overListFunc)
    self.m_triggerFuncCallBack = overListFunc
    if not funcList or #funcList == 0 then
        self:triggerFuncFinish()
        return false
    end
    self.m_triggerFuncList:clear()
    self.m_triggerFuncCount = 0
    for i=1,#funcList do
        self.m_triggerFuncList:push(funcList[i])
    end
    return self:triggerFuncNext()
end
--执行下一个方法
function ViewManager:triggerFuncNext()
    --结束条件
    if self.m_triggerFuncList:empty() then
        self:triggerFuncFinish()
        return false
    end
    local info = self.m_triggerFuncList:pop()
    if info then
        if info.func then
            --执行一个方法
            self.m_triggerFuncCount = self.m_triggerFuncCount + 1
            info.func(info.params)
            return true
        else
            return self:triggerFuncNext()
        end
    else
        return self:triggerFuncNext()
    end
end
--执行完成
function ViewManager:triggerFuncFinish()
    --清空参数
    self:triggerFuncClear()
    if self.m_triggerFuncCallBack then
        local overFunc = self.m_triggerFuncCallBack
        self.m_triggerFuncCallBack = nil
        overFunc()
    end
end
--清空参数
function ViewManager:triggerFuncClear()
    self.m_triggerFuncList:clear()
    self.m_triggerFuncCount = -1
end

--测试用例
function ViewManager:testBuyTipLayerFunc()
    gLobalViewManager:triggerFuncNext() --执行下一个方法
end



-- 显示服务器有更新面板 2021-3-29 tm --
function ViewManager:showServerUpdateView( showInfo )

    local existView = gLobalViewManager:getViewByExtendData("ServerUpdateView")
    if existView ~= nil then
        return
    end

    --清理引导防止不能点击
    if globalNoviceGuideManager ~= nil then
        globalNoviceGuideManager:clearGuide()
    end
    --
    local csbName = GD.jmsLocalizationManager:getLobbyLocalizationInfo( 40011 ).Param
    local view = gLobalViewManager:showDialog( csbName,function()
        util_restartGame()
    end,nil,nil,ViewZorder.ZORDER_NETWORK)
    --
    view:setExtendData("ServerUpdateView")
    --
    local textNode = view:findChild("updateInfo")
    if textNode ~= nil and showInfo ~= nil then
        local sText = string.gsub( showInfo, ";","\n")
        textNode:setString( sText )
    end
    --
    if view.setEnableOnkeyBack then
        view:setEnableOnkeyBack(false)
    end

end

--[[
    @desc: 提供新接口，方便特殊游戏需求，从游戏结束后需要返回之前的场景
]]
function ViewManager:setCurrMachineData()
    if self.m_currentScene == SceneType.Scene_Game and globalData.slotRunData.machineData then
        globalData.slotRunData.gameRunPause = true
        self.m_currrMachineData = globalData.slotRunData.machineData
    else
        self.m_currrMachineData = nil
    end
end

function ViewManager:clearCurrMachineData()
    globalData.slotRunData.gameRunPause = nil
    self.m_currrMachineData = nil
end

function ViewManager:gotoBeforeSceneType()
    if self.m_currrMachineData then
        -- globalData.slotRunData.gameRunPause = nil
        -- globalData.slotRunData.gameResumeFunc = nil
        -- --发现关卡不竖版的 ，需要旋转
        -- if self.m_currrMachineData.p_portraitFlag ~= true then
        --     globalData.slotRunData.isChangeScreenOrientation = true
        --     globalData.slotRunData:changeScreenOrientation(self.m_currrMachineData.p_portraitFlag)
        -- end
        -- globalData.slotRunData.isDeluexeClub = self.m_currrMachineData.p_highBetFlag
        -- globalData.slotRunData.machineData = self.m_currrMachineData
        -- globalData.slotRunData.iLastBetIdx = -1
        -- gLobalSendDataManager:getLogIap():setEntryGame(self.m_currrMachineData.p_name)
        -- self:gotoSceneByType(SceneType.Scene_Game)
        local questConfig = jmsActivityControl:getCurQuestData()
        local info = self.m_currrMachineData
        local isQuest = false
        local logStr = "RegularArea"
        if questConfig and questConfig.m_IsQuestLogin then
            isQuest = true
            logStr = "QuestLobby"
        end
        GD.jmsLobbyManager:gotoSlotSceneByLevelId(info.p_id,logStr,isQuest,true)
        self.m_currrMachineData = nil
    else
        self:gotoSceneByType(SceneType.Scene_Lobby)
    end
end

function ViewManager:addNodeWorldPosByType(_type,_worldPos)
    if not self.m_nodeWorldPos then
        self.m_nodeWorldPos = {}
    end
    self.m_nodeWorldPos[_type] = _worldPos
end

function ViewManager:getNodeWorldPosByType(_type)
    return self.m_nodeWorldPos[_type] or cc.p(0,0)
end

--[[
    @desc: 新增v2接口，方便控制参数
    --@_node:绑定定时器的节点
	--@_closeFunc:回调
	--@isTouchEnd:是否穿透
	--@zorder:层级
	--@closeTime: 自动关闭的时间
]]
function ViewManager:addAutoCloseTipsV2(_node,_closeFunc,_extra)
    if not _node then
        return
    end

    local isTouchEnd = _extra.isTouchEnd
    local zorder = _extra.zorder
    local closeTime = _extra.closeTime or 5
    local isSwallow = true
    if _extra.isSwallow ~= nil then
        isSwallow = _extra.isSwallow
    end
    local isCloseTips = false
    local layer = cc.Layer:create()
    layer:onTouch(function(event)
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
        if not tolua.isnull(_node) and _closeFunc then
            _closeFunc()
            _closeFunc= nil
        end
        
        return true
    end, false, isSwallow)
    if zorder then
        gLobalViewManager.p_ViewLayer:addChild(layer,zorder)
    else
        gLobalViewManager.p_ViewLayer:addChild(layer,ViewZorder.ZORDER_SPECIAL)
    end

    -- 定义倒计时关闭界面
    performWithDelay(_node,function()
        if isCloseTips then
            return true
        end
        isCloseTips = true
        if layer and not tolua.isnull(layer) then
            layer:removeFromParent()
            layer = nil
        end
        if _closeFunc then
            _closeFunc()
            _closeFunc= nil
        end
    end,closeTime)
    return layer
end

return ViewManager
