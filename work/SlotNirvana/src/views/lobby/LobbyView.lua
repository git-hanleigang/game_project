--
--大厅图层
--
local LevelNodeControl = require("views.lobby.LevelNodeControl")
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")
local LobbyView = class("LobbyView", BaseLayer)

-- 启动推币机模块
local coinPusherMgr = G_GetMgr(ACTIVITY_REF.CoinPusher)
if coinPusherMgr then
    coinPusherMgr:onStart()
end
-- 启动新版推币机模块
local newCoinPusherMgr = G_GetMgr(ACTIVITY_REF.NewCoinPusher)
if newCoinPusherMgr then
    newCoinPusherMgr:onStart()
end
-- 启动埃及推币机模块
local egyptCoinPusherMgr = G_GetMgr(ACTIVITY_REF.EgyptCoinPusher)
if egyptCoinPusherMgr then
    egyptCoinPusherMgr:onStart()
end

function LobbyView:ctor()
    LobbyView.super.ctor(self)

    self.m_leftTime = nil -- 每小时奖励 --- 倒计时剩余时间

    self.m_dailyBonusGroup = {}
    self.m_dailyBonusGroup.m_dialyBonusCoin = nil
    self.m_dailyBonusGroup.m_dailyDayId = nil
    self.m_dailyBonusGroup.m_dailyRate = nil
    self.m_dailyBonusGroup.m_curDayTime = nil
    self.m_dailyBonusGroup.m_randomBaseIndex = nil
    self.m_dailyBonusGroup.m_bonusReward = nil
    self.m_isLogin = false
    self.m_lastBuyCoins = nil

    self.m_isShowBonusWheelView = nil
    self.m_CardOverFunc = nil
    self.m_newVersionNode = nil
end

function LobbyView:initDatas()
    LobbyView.super.initDatas(self)
    -- 显示计数
    self.m_visibledRef = 0
    self.m_tbNodes = {}
    -- 已加载 type(普通大厅还是扩圈大厅) contentUI 标识
    self.m_loadSignList = {}

    self:setResolutionPolicy(self.ResolutionPolicy.FIXED_WIDTH)

    self:setLandscapeCsbName("Lobby/LobbyLayer.csb")
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setKeyBackEnabled(true)
end

function LobbyView:initUI(isLogin)
    --初始化活动  存储活动的csb名称和对应顺序
    --self:initActivity()
    --测试评价
    --gLobalDataManager:setStringByField("LevelRateusNode", "")
    globalData.slotRunData.gameRunPause = false
    self.m_isLogin = isLogin
    if self.m_isLogin then
        globalData.lobbyScorllx = 0
        globalData.jump2Lobby2Level = false
        globalData.jump2Lobby2LevelId = nil
        globalNoviceGuideManager:setShowState(true)
    end
    gLobalGameHeartBeatManager:startHeartBeat()

    gLobalBuglyControl:log("LobbyView:initUI")
    -- setDefaultTextureType("RGBA8888", nil)
    -- self:createCsbNode("Lobby/LobbyLayer.csb")
    LobbyView.super.initUI(self)
    self:checkChangeLobbyBg()
    -- setDefaultTextureType("RGBA4444", nil)

    self.m_rootNode = self:findChild("root")
    if self.m_rootNode then
        self.m_rootNode:setLocalZOrder(5)
        globalData.lobbyScale = self.m_rootNode:getScale()
    end
    local img_bg = self:findChild("img_bg")
    local node_top = self:findChild("node_top")
    local node_down = self:findChild("node_down")
    local node_center = self:findChild("node_center")
    local node_left = self:findChild("node_left")
    local node_broadcast = self:findChild("node_broadcast")
    local layerMask = self:findChild("layerMask")
    local backFront = self:findChild("node_backfront")
    local node_expand = self:findChild("node_expand")
    table.insert(self.m_tbNodes, {node = img_bg, type = {NewUserExpandConfig.LOBBY_TYPE.SLOTS, NewUserExpandConfig.LOBBY_TYPE.COL_LEVELS}})
    table.insert(self.m_tbNodes, {node = node_top})
    table.insert(self.m_tbNodes, {node = node_down, type = {NewUserExpandConfig.LOBBY_TYPE.SLOTS, NewUserExpandConfig.LOBBY_TYPE.COL_LEVELS}})
    table.insert(self.m_tbNodes, {node = node_left})
    table.insert(self.m_tbNodes, {node = node_center, type = NewUserExpandConfig.LOBBY_TYPE.SLOTS})
    table.insert(self.m_tbNodes, {node = node_broadcast, type = NewUserExpandConfig.LOBBY_TYPE.SLOTS})
    table.insert(self.m_tbNodes, {node = layerMask, type = NewUserExpandConfig.LOBBY_TYPE.SLOTS})
    table.insert(self.m_tbNodes, {node = node_expand, type = NewUserExpandConfig.LOBBY_TYPE.PUZZLE})
    table.insert(self.m_tbNodes, {node = backFront, type = NewUserExpandConfig.LOBBY_TYPE.SLOTS})

    --整体上移15像素
    node_broadcast:setPositionY(node_center:getPositionY() + 15)

    -- 上UI topNode
    self.m_topNode = util_createView("views.lobby.TopNode")
    node_top:addChild(self.m_topNode)

    -- 下UI bottomNode
    self.m_bottomNode = util_createView("views.lobby.BottomNode", isLogin)
    node_down:addChild(self.m_bottomNode)

    -- 左边 大厅风格tagUI(显示普通大厅还是扩圈大厅)
    self:initNewUserExpandEntryUI()

    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)

    --尝试添加热更节点
    self:checkNewVersion()

    -- 进入大厅 申请卡牌数据信息 --
    self:getCardSysInfo()

    --第几次登录打点
    if isLogin then
        globalAdjustManager:sendAdjustLoginLog(globalData.saleRunData.p_loginTimesInDay)
    end

    -- quest相关
    G_GetMgr(ACTIVITY_REF.Quest):updateQuestConfig()
    G_GetMgr(ACTIVITY_REF.QuestNew):updateQuestConfig()
    G_GetMgr(ACTIVITY_REF.QuestNew):requestGetPool(true)
    G_GetMgr(ACTIVITY_REF.TopUpBonus):requestGetPool(true)
    
    -- 每日任务相关
    gLobalDailyTaskManager:updateConfig()
    gLobalDailyTaskManager:registerDLCompleteObservers()

    if device.platform == "ios" then
        cc.FileUtils:getInstance():removeFile(device.writablePath .. "LoadingError.dat")
    end
    G_GetMgr(ACTIVITY_REF.CommonJackpot):getPoolCtr():clearSyncTime(CommonJackpotCfg.POOL_KEY.Lobby)
    -- 同步一下，有可能没有走完同步流程就切换到了大厅
    G_GetMgr(ACTIVITY_REF.FlamingoJackpot):syncJackpotPoolData()
    -- 从关卡返回的时候清一下关卡中缓存的数据
    G_GetMgr(ACTIVITY_REF.FlamingoJackpot):clearSpinTriggerData()

    --收藏关卡节点
    self:initCollect()

    -- 大厅相关主内容UI
    self:updateLobbyNewUserExpandUIVisible()
    self:runCsbAction("idle")
end

--收藏关卡节点
function LobbyView:initCollect()
    local bOpen = G_GetMgr(G_REF.CollectLevel):checkColLevelsOpen()
    if not bOpen or self.m_expandEntryView then
        -- 扩圈入口包含了 收藏关卡页签
        return
    end

    self.m_clTipview = G_GetMgr(G_REF.CollectLevel):showTips()
    if not self.m_clTipview then
        return
    end
    
    local nodeLeft = self:findChild("node_left")
    local offset = util_getBangScreenHeight()
    self.m_clTipview:setPositionX(offset)
    self:adaptLobbyContent(offset)
    table.insert(self.m_tbNodes, {node = self.m_clTipview, type = NewUserExpandConfig.LOBBY_TYPE.SLOTS})
    nodeLeft:addChild(self.m_clTipview)
end
-- 收藏关卡
function LobbyView:loadColLevelUI()
    local view = G_GetMgr(G_REF.CollectLevel):createColLevelTbView()
    if not view then
        return
    end
    local nodeLeft = self:findChild("node_left")
    local offset = util_getBangScreenHeight()
    view:setPositionX(offset + 60)
    table.insert(self.m_tbNodes, {node = view, type = NewUserExpandConfig.LOBBY_TYPE.COL_LEVELS})
    nodeLeft:addChild(view)
end

function LobbyView:adaptLobbyContent(_offset)
    if not _offset or _offset == 0 then
        return
    end
    local node_center = self:findChild("Panel_1")
    local posX = node_center:getPositionX() + _offset
    node_center:setPositionX(posX)
    local node_broadcast = self:findChild("node_broadcast")
    posX = node_broadcast:getPositionX() + _offset
    node_broadcast:setPositionX(posX)
    local layerMask = self:findChild("layerMask")
    posX = layerMask:getPositionX() + _offset
    layerMask:setPositionX(posX)
    local node_expand = self:findChild("node_expand")
    posX = node_expand:getPositionX() + _offset
    node_expand:setPositionX(posX)
    local backFront = self:findChild("node_backfront")
    local backFrontPosX = backFront:getPositionX() + _offset
    backFront:setPositionX(backFrontPosX)
end

-- 左边 大厅风格tagUI(显示普通大厅还是扩圈大厅)
function LobbyView:initNewUserExpandEntryUI()
    local nodeLeft = self:findChild("node_left")
    if nodeLeft:getChildByName("NewUserExpandEntry") then
        return
    end

    local entryView = G_GetMgr(G_REF.NewUserExpand):createExpandEntryUI()
    if not entryView then
        return
    end
    nodeLeft:addChild(entryView)
    local offset = util_getBangScreenHeight()
    entryView:setPositionX(offset)
    self:adaptLobbyContent(offset)
    self.m_expandEntryView = entryView
end

-- 加载大厅 主 内容
function LobbyView:loadLobbyContentUI()
    local curType = G_GetMgr(G_REF.NewUserExpand):getCurLobbyStyle()
    if self.m_loadSignList[curType] then
        return
    end
    self.m_loadSignList[curType] = true

    if curType == NewUserExpandConfig.LOBBY_TYPE.SLOTS then
        --活动背景
        self:initActivityNode()
        -- 初始化大厅 关卡entry
        local node_center = self:findChild("node_center")
        local node_broadcast = self:findChild("node_broadcast")
        local layerMask = self:findChild("layerMask")
        local backFront = self:findChild("node_backfront")
        self:initlevel(node_center, node_broadcast, layerMask, backFront)
        -- 刷新 level 节点
        self:freshLevelNode(self.m_isLogin and "LoginLobby" or "ReturnLobby")
    elseif curType == NewUserExpandConfig.LOBBY_TYPE.PUZZLE then
        -- 扩圈大厅
        self:loadPuzzleContentUI()
    elseif curType == NewUserExpandConfig.LOBBY_TYPE.COL_LEVELS then
        -- 收藏关卡
        self:loadColLevelUI()
    end
end

-- 扩圈大厅
function LobbyView:loadPuzzleContentUI()
    local view = G_GetMgr(G_REF.NewUserExpand):createExpandMainLayer()
    if not view then
        return
    end
    local nodeExpand = self:findChild("node_expand")
    nodeExpand:addChild(view)
    nodeExpand:move(0, 0)
end

function LobbyView:checkChangeLobbyBg()
    local img_bg = self:findChild("img_bg")
    if img_bg then
        local themePath = globalData.GameConfig:getLobbyBg()
        if themePath then
            util_changeTexture(img_bg, themePath)
        end
    end
end

function LobbyView:checkNewVersion()
    if not globalData.isUpgradeTips or (globalData.constantData.UPDATE_TIPS_LEVEL or 0) > globalData.userRunData.levelNum then
        return
    end
    if self.m_newVersionNode then
        return
    end
    self.m_newVersionNode = util_createView("views.newVersion.NewVersionNode")
    self:addChild(self.m_newVersionNode, 1)
    self.m_newVersionNode:setPosition(display.width - 140, display.cy)
end

--需要预加载的资源数量
function LobbyView:getPreLoadLobbyNodes()
    return nil
end
--预加载资源nodeType 类型 目前只有一种不需要设置
function LobbyView:preLoadLobbyNode(index, info, nodeType)
    if self.m_levelNodeControl then
        self.m_levelNodeControl:loadLevelNode(index, info)
    end
end
--刷新子节点
function LobbyView:freshLevelNode(freshType)
    if self.m_levelNodeControl then
        if self.m_levelNodeControl.freshLevelNode then
            self.m_levelNodeControl:freshLevelNode(freshType)
            self.m_levelNodeControl:updateScroll()
        else
            util_sendToSplunkMsg("LevelNodeControl", "freshLevelNode is nil in freshType = " .. tostring(freshType))
        end
    else
        util_sendToSplunkMsg("LevelNodeControl", "levelNodeControl is nil in freshType = " .. tostring(freshType))
    end
end

function LobbyView:showFbFirstLoginDialog()
    if gLobalSendDataManager:getIsFbLogin() and globalData.userRunData.isGetFbReward == false then
        gLobalSendDataManager:getNetWorkFB():sendActionFbConnect(globalData.userRunData.coinNum + globalData.userRunData.FB_LOGIN_FIRST_REWARD, globalData.userRunData.FB_LOGIN_FIRST_REWARD)
    end
end

function LobbyView:initlevel(moveNode, node, layerMaskl, backFront)
    self.m_levelNodeControl = LevelNodeControl:getInstance()
    self.m_levelNodeControl:initData(moveNode, node, layerMaskl, backFront)
    self.m_levelNodeControl:initLevelScroll()
end

-- 刷新显示
function LobbyView:moveToLevelNode(posX, secs)
    if self.m_levelNodeControl then
        self.m_levelNodeControl:moveToLevelNode(posX, secs)
    end
end

-- 刷新显示
function LobbyView:jumpToLevelNode(offsetX)
    if self.m_levelNodeControl then
        self.m_levelNodeControl:jumpToLevelNode(offsetX)
    end
end

-- 跳转到关卡分类
function LobbyView:jumpToRecmdNode(offsetX)
    if self.m_levelNodeControl then
        self.m_levelNodeControl:jumpToRecmdNode(offsetX)
    end
end

--跳转到推荐的新关卡
function LobbyView:openNewLevel(gameID, params)
    params = params or {}
    if not self.m_levelNodeControl then
        return
    end
    if not gameID then
        gameID = globalData.constantData.OPEN_NEWLEVEL_ID
    end
    if not gameID then
        return
    end
    local moveX, idxCol, idxRow = self.m_levelNodeControl:getLevelPosXById(gameID)
    self:jumpToLevelNode(-moveX)

    local cellNode = self.m_levelNodeControl:getNodeCell(idxCol, idxRow)
    if cellNode then
        gLobalSendDataManager:getLogSlots():resetEnterLevel()
        if gLobalSendDataManager and gLobalSendDataManager:getLogSlots() and gLobalSendDataManager:getLogSlots().setEnterLevelSite then
            gLobalSendDataManager:getLogSlots():setEnterLevelSite("NewGame")
        end
        gLobalSendDataManager:getLogSlots():setEnterLevelSiteType("NewGame")
        if params.siteName then
            gLobalSendDataManager:getLogSlots():setEnterLevelSiteName(params.siteName)
        end
        cellNode:checkGotoLevel()
    end
end

function LobbyView:onExit()
    LobbyView.super.onExit(self)
    globalNoviceGuideManager:setShowState(false)
    
    -- self.m_scroll = nil

    -- clear view childs
    local viewLayer = gLobalViewManager:getViewLayer()
    if not tolua.isnull(viewLayer) then
        viewLayer:removeAllChildren()
    end
    local NetworkLog = util_require("network.NetworkLog")
    if NetworkLog ~= nil then
        NetworkLog.saveLogToFile()
    end
end

function LobbyView:onCleanup()
    LobbyView.super.onCleanup(self)
    if self.m_levelNodeControl then
        self.m_levelNodeControl:purge()
        self.m_levelNodeControl = nil
    end
end
function LobbyView:checkInvite(_type)
    local invite = G_GetMgr(G_REF.Invite):getData()
    if invite then
        G_GetMgr(G_REF.Invite):sendLinkReq(invite:getInviteUid(), _type)
    end
end

function LobbyView:getInviteData()
    local invite = G_GetMgr(G_REF.Invite):getData()
    if invite then
        G_GetMgr(G_REF.Invite):sendDataReq(1)
        globalPlatformManager:parseCommonLink(nil, 999)
    end
end

function LobbyView:setLobbyVisible(isVisible)
    local curType = G_GetMgr(G_REF.NewUserExpand):getCurLobbyStyle()
    for _, nodeInfo in pairs(self.m_tbNodes) do
        local node = nodeInfo.node
        local showType = nodeInfo.type
        if showType then
            local bIn = showType == curType
            if type(showType) == "table" then
               for _,v in pairs(showType) do
                    if v == curType then
                        bIn = true
                        break
                    end
               end
            end
            node:setVisible(isVisible and bIn)
        else
            node:setVisible(isVisible)
        end
    end
end

-- 更新 大厅 普通大厅 还是 扩圈系统 显隐
function LobbyView:updateLobbyNewUserExpandUIVisible()
    self:setLobbyVisible(true)
    self:loadLobbyContentUI()  
end

--交换顺序
function LobbyView:changeTopBottomZorder(isChange)
    local node_top = self:findChild("node_top")
    local node_down = self:findChild("node_down")
    if node_top and node_down then
        local orderTop = node_top:getZOrder()
        -- local orderDown = node_down:getZOrder()
        -- node_top:setZOrder(orderDown)
        if isChange then
            node_down:setZOrder(orderTop + 1)
        else
            node_down:setZOrder(orderTop)
        end
    end
end

function LobbyView:openCashBonusTishi(id)
    self.m_bottomNode:openCashBonusTishi(id)
end

function LobbyView:initNoob()
    local curType = G_GetMgr(G_REF.NewUserExpand):getCurLobbyStyle()
    if curType == NewUserExpandConfig.LOBBY_TYPE.PUZZLE then
        return
    end
    if self.m_initNoob then
        return
    end
    self.m_initNoob = true -- 是否已经初始化过了
    if gLobalPopViewManager:isPopView() then
        return
    end
    gLobalPopViewManager:checkReadConfig()
    if self.m_isLogin then
        --进入游戏弹窗控制
        local isPopView = true
        if globalData.leaveFromCoinPuhser then
            globalData.leaveFromCoinPuhser = false
            isPopView = false
        end
        if CC_IS_PORTRAIT_MODE == false and isPopView then
            -- 强制公告的数据获取后再开始弹框
            globalAnnouncementManager:sendAnnouncementLogin(
                function()
                    gLobalPopViewManager:setPause(false)
                    gLobalPopViewManager:showPopView(POP_VC_TYPE.LOGIN_TO_LOBBY)
                end
            )
        end
    else
        -- --集卡第二赛季小游戏检查
        -- if CardSysManager and CardSysManager.checkAutoEnterSpecialGame then
        --     if CardSysManager:checkAutoEnterSpecialGame() then
        --         --通过点击关卡内集卡小游戏返回的大厅直接进入小游戏
        --         return
        --     end
        -- end
        if globalData.isShowCashBonus and globalData.isShowCashBonus == true then
            globalData.isShowCashBonus = false
            local cashBonusView = util_createView("views.cashBonus.cashBonusMain.CashBonusMainView")
            gLobalViewManager:showUI(cashBonusView, ViewZorder.ZORDER_UI)
        end

        local isPopView = true

        globalData.isMoreGames2Lobby = false
        if globalData.jump2Lobby2Level then
            globalData.jump2Lobby2Level = false
            if globalData.jump2Lobby2LevelId then
                isPopView = false
                performWithDelay(
                    self,
                    function()
                        gLobalSendDataManager:getLogSlots():resetEnterLevel()
                        gLobalSendDataManager:getLogSlots():setEnterLevelSiteType("NewUser")
                        if globalData.isForeJump then
                            globalData.isForeJump = false
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FORCE_INTO_LEVEL_BY_ID, globalData.jump2Lobby2LevelId)
                        else
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GOTO_LEVEL_BY_ID, {levelId = globalData.jump2Lobby2LevelId, autoEnter = true})
                        end
                    end,
                    0.5
                )
            end
        end

        if globalData.leaveFromCoinPuhser then
            globalData.leaveFromCoinPuhser = false
            isPopView = false
        end
        --返回大厅弹窗控制
        if isPopView then
            gLobalPopViewManager:setPause(false)
            gLobalPopViewManager:showPopView(POP_VC_TYPE.GAME_TO_LOBBY)
        end

        -- 等级里程碑跳转到 刚刚解锁的关卡id
        local bJump = G_GetMgr(G_REF.LevelRoad):checkJumpLoobyUnlockGames()

    end
end

--是否显示集卡引导
function LobbyView:checkAutoCard()
    -- 从关卡回到大厅验证是否要自动进入集卡系统
    self.m_CardOverFunc = nil
    if self:checkAutoEnterCard() == true then
        if not CardSysManager:isDownLoadCardRes() then
            gLobalNoticManager:postNotification(
                ViewEventType.NOTIFY_LOBBY_BOTTOM_CARD_CHECKDOWNLOAD,
                function()
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT) --弹窗逻辑执行下一个事件
                end
            )
        elseif not CardSysManager:hasSeasonOpening() then
            gLobalNoticManager:postNotification(
                ViewEventType.NOTIFY_LOBBY_BOTTOM_CARD_OPEN,
                function()
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT) --弹窗逻辑执行下一个事件
                end
            )
        else
            self.m_CardOverFunc = function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT) --弹窗逻辑执行下一个事件
            end
            if CardSysManager.setEnterCardType then
                CardSysManager:setEnterCardType(2)
            end
            CardSysManager:enterCardCollectionSys()
        end
    else
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT) --弹窗逻辑执行下一个事件
    end
end

function LobbyView:updateTopUiInfo()
    -- 计算缩放和适配
    globalData.topUIScale = self.m_topNode:getCsbNodeScale()
    local coin_dollar = self.m_topNode:findChild("coin_dollar")
    local endPos = coin_dollar:getParent():convertToWorldSpace(cc.p(coin_dollar:getPosition()))
    globalData.flyCoinsEndPos = clone(endPos)
    globalData.recordHorizontalEndPos = clone(endPos)
    if device.platform == "mac" and endPos.y > endPos.x then
        globalData.recordHorizontalEndPos.y = display.width - (display.height - endPos.y)
        globalData.recordHorizontalEndPos.x = endPos.x
    end
end

function LobbyView:onEnter()
    globalEventKeyControl:addKeyBack(self)
    self:toDoLayout()
    -- 设置显示的横竖屏
    globalData.slotRunData:setFramePortrait(false)
    if globalNoviceGuideManager:isNoobUsera() then --新用户
        if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.initIcons.id) then --新手金币指引没完成
            self.m_topNode:checkGuideClearCoins()
            self.m_topNode:checkGuideClearGems()
        end
    end
    
    self:updateTopUiInfo()

    gLobalBuglyControl:log("LobbyView:onEnter")
    self:addObserverRegister()

    local viewLayer = gLobalViewManager:getViewLayer()
    if not tolua.isnull(viewLayer) then
        viewLayer:removeAllChildren()
        if viewLayer:getParent() ~= nil then
            viewLayer:removeFromParent(false)
        end
        self:addChild(viewLayer, 20, 20)
    end

    schedule(
        self,
        function()
            globalNotifyNodeManager:timeUpdate()

            if globalData.deluexeClubData:getDeluexeClubStatus() == true then
                local strTime, isOver = globalData.deluexeClubData:getLeftTimeStr()
                if isOver == true then
                    self:updateUiByDeluxe(false)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUXECLUB_OVER)
                end
            end

            -- 清除热玩玩家数据
            self:checkClearMachineHotPlayerList()
            -- 监测自身头像框是否过期
            self:checkSelfAvartarBEnabled()
        end,
        1
    )
    

    --默认下载当前赛季黑曜卡资源
    G_GetMgr(G_REF.ObsidianCard):checkDownloadObsidianCardIcon()
    --默认下载当前赛季资源
    CardSysManager:checkDownLoadSeason()

    

    if globalData.deluexeHall == true then
        self:showDeluexeClubView()
    end

    -- 重置 Top&Bottom Node的位置，便于做出场动画  202007071604 --
    self.m_topNode:setPosition(cc.p(0, 100))
    self.m_bottomNode:setPosition(cc.p(0, -200))
    -- 重置 Top&Bottom Node的位置，便于做出场动画  202007071604 --
    local topActionList = {}
    topActionList[1] = cc.MoveTo:create(0.5, cc.p(0, 0))
    topActionList[2] = cc.CallFunc:create(
        function()
            if not tolua.isnull(self.m_topNode) then
                self.m_topNode:updateCuyFlyPos()
            end
        end
    )
    self.m_topNode:runAction(cc.Sequence:create(topActionList))

    local bottomMoveto = cc.MoveTo:create(0.5, cc.p(0, 0))
    local isQuestLobby = false
    local isDiyLobby = self:dealDiy()
    if not isDiyLobby then
        isQuestLobby = self:dealQuest()
    end
    self.m_bottomNode:runAction(
        cc.Sequence:create(
            bottomMoveto,
            cc.CallFunc:create(
                function()
                    -- quest界面提前创建了 需要在大厅完全展示出来以后再激活quest界面
                    -- local phaseView = gLobalViewManager:getViewByExtendData("QuestIslandPhaseView")
                    -- if phaseView then
                    --     phaseView:setActive()
                    -- end
                    --quest返回大厅不弹窗界面
                    if not isQuestLobby and not isDiyLobby and not self:showCoinPusherSelectView() and not self:showNewCoinPusherSelectView() and not self:showEgyptCoinPusherSelectView() then
                        self:initNoob()
                    end
                end
            )
        )
    )

    if G_GetMgr(ACTIVITY_REF.ActivityMissionRushNew) and G_GetMgr(ACTIVITY_REF.ActivityMissionRushNew):getData() then
        G_GetMgr(ACTIVITY_REF.ActivityMissionRushNew):lobbyOnEnter()
    end
    -- addCostRecord("login_to_lobby", socket.gettime() - GD.loginSuccTime)
    -- printCostRecord()
    -- 重置 进入关卡 spin 标识
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAR_RIPPLEDASH_LEVEL_SIGN)
    self:getInviteData()
    if G_GetMgr(G_REF.Flower) and G_GetMgr(G_REF.Flower):getData() then
        G_GetMgr(G_REF.Flower):setFlowerData()
    end

    if G_GetMgr(ACTIVITY_REF.LevelDashPlus) and G_GetMgr(ACTIVITY_REF.LevelDashPlus):getData() then
        G_GetMgr(ACTIVITY_REF.LevelDashPlus):lobbyOnEnter()
    end

    --G_GetMgr(G_REF.FBFriend):pGetAllFriendList(nil, true)
    if G_GetMgr(G_REF.Friend) then
        G_GetMgr(G_REF.Friend):requestAddFriendList()
        G_GetMgr(G_REF.Friend):pGetAllFriendList(nil, true)
    end
    -- 清除 记录的关卡热玩 玩家数据
    self:clearMachineHotPlayerList()

    local isPlayLobbyMusic = true
    if self.m_isShowBonusWheelView == true then
        isPlayLobbyMusic = false
    end
    if isPlayLobbyMusic then
        --上线兼容使用方式
        local lobbyBgmPath = "Sounds/bkg_lobby_new.mp3"
        if gLobalActivityManager.getLobbyMusicPath then
            lobbyBgmPath = gLobalActivityManager:getLobbyMusicPath()
        end
        gLobalSoundManager:playBgMusic(lobbyBgmPath)
    end
    G_GetMgr(G_REF.UserInfo):sendInfoMationReq(globalData.userRunData.userUdid, "","",globalData.userRunData.HeadName,1)
end

function LobbyView:showCoinPusherSelectView()
    --推币机mananger

    if G_GetMgr(ACTIVITY_REF.CoinPusher):getShowSelectView() then
        gLobalActivityManager:showActivityMainView("Activity_CoinPusher", "CoinPusherSelectUI", nil, nil)
        G_GetMgr(ACTIVITY_REF.CoinPusher):setShowSelectView(false)
        return true
    end

    return false
end

function LobbyView:showNewCoinPusherSelectView()
    --新推币机mananger

    if G_GetMgr(ACTIVITY_REF.NewCoinPusher):getShowSelectView() then
        gLobalActivityManager:showActivityMainView("Activity_NewCoinPusher", "NewCoinPusherSelectUI", nil, nil)
        G_GetMgr(ACTIVITY_REF.NewCoinPusher):setShowSelectView(false)
        return true
    end

    return false
end

function LobbyView:showEgyptCoinPusherSelectView()
    --埃及推币机mananger

    if G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):getShowSelectView() then
        gLobalActivityManager:showActivityMainView("Activity_EgyptCoinPusher", "EgyptCoinPusherSelectUI", nil, nil)
        G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):setShowSelectView(false)
        return true
    end

    return false
end

function LobbyView:dealQuest()
    local curType = G_GetMgr(G_REF.NewUserExpand):getCurLobbyStyle()
    if curType == NewUserExpandConfig.LOBBY_TYPE.PUZZLE then
        -- 当前扩圈大厅 不用处理quest
        return false
    end

    local isQuestLobby = false
    local quest_mgr = G_GetMgr(ACTIVITY_REF.Quest)
    local quest_data = quest_mgr:getRunningData()
    if not quest_data then
        local quest_new_mgr = G_GetMgr(ACTIVITY_REF.QuestNew)
        local quest_new_data = quest_new_mgr:getRunningData()
        if quest_new_data then
            isQuestLobby = quest_new_mgr:needShowInLobby(self.m_isLogin)
            if isQuestLobby then
                --普通关卡点击进入quest 不发送这个位置
                if not quest_new_data:isEnterQuestFromGame() then
                    gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("gameBackLobby")
                end
                if not quest_new_mgr:jumpToMainMapViewAndPrepareChooseLayer() then
                    quest_new_mgr:showMainLayer()
                end
            else
                quest_new_data:setEnterQuestFromGame(false)
            end
            return isQuestLobby
        end
        return false
    else
        isQuestLobby = quest_mgr:needShowInLobby(self.m_isLogin)
        if isQuestLobby then
            --普通关卡点击进入quest 不发送这个位置
            if not quest_data.p_isLevelEnterQuest then
                gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("gameBackLobby")
            end
            if not quest_mgr:jumpToPhaseViewAndWait() then
                quest_mgr:showMainLayer(nil, true)
            end
        else
            quest_data.p_isLevelEnterQuest = false
        end
    end

    -- 查看 是否显示quest 底部入口引导
    if self.m_isLogin and quest_mgr:checkQuestUlkLobbyBtmGuide() then
        quest_mgr:showLobbyBtmGuideLayer()
    end
    return isQuestLobby
end

function LobbyView:dealDiy()
    local diy = G_GetMgr(ACTIVITY_REF.DiyFeature)
    if diy and diy:getRunningData() and diy:willShowMainLayer() then
        diy:showMainLayer()
        return true
    end
    return false
end
-- 从关卡回到大厅验证是否要自动进入集卡系统
function LobbyView:checkAutoEnterCard()
    -- 从关卡回到大厅才会检测
    if self.m_isLogin then
        return false
    end
    if not CardSysManager:getAutoEnterCard() then
        return false
    end
    return true
end

function LobbyView:updateUiByDeluxe(open)
    if self.m_levelNodeControl and self.m_levelNodeControl.updateDeluxeLevels then
        self.m_levelNodeControl:updateDeluxeLevels(open)
        self.m_topNode:updateUiByDeluxe(open)
        self.m_bottomNode:updateUiByDeluxe(open)

        local bottomExtra = gLobalViewManager:getViewByName("BottomExtraNode")
        if bottomExtra then
            bottomExtra:updateUiByDeluxe(open)
        end
    end

    globalData.deluexeClubData:changeClubOpenLevelConstantValue()
end

function LobbyView:showDailyBonus()
end

function LobbyView:getRewardList()
    local curLevel = globalData.userRunData.levelNum
    local levelIndex = 1
    for i = #STORE_LEVEL_LIST, 1, -1 do
        if curLevel >= STORE_LEVEL_LIST[i] then
            levelIndex = i
            break
        end
    end
    return RANDOM_REWARDS_LIST[levelIndex]
end

function LobbyView:onKeyBackExit()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASHBONUS_TISHI_CLOSE)
    local view =
        gLobalViewManager:showDialog(
        "Dialog/ExitGame.csb",
        function()
            globalLocalPushManager:commonBackGround()
            G_GetMgr(G_REF.OperateGuidePopup):saveGuideArchiveData()
            local director = cc.Director:getInstance()
            director:endToLua()
        end,
        function()
            if self.m_ExitGame then
                self:stopAction(self.m_ExitGame)
                self.m_ExitGame = nil
                print("Cool测试～～～～～～～")
            else
                --globalNoviceGuideManager:NextShow()
                globalNoviceGuideManager:attemptShowRepetition()
            end
        end,
        nil,
        nil,
        {
            {buttomName = "btn_later", labelString = "LATER"},
            {buttomName = "btn_ok", labelString = "QUIT"}
        }
    )
    view:setLocalZOrder(40000)
    local contentNode = view:findChild("content")
    local content =
        util_createView(
        "views.dialogs.ExitGameContent",
        function()
            if self.m_ExitGame then
                self:stopAction(self.m_ExitGame)
                self.m_ExitGame = nil
                print("Cool测试1～～～～～～～")
            end

            view:removeFromParent()
        end
    )
    contentNode:addChild(content)
end
function LobbyView:onKeyBack()
    -- if globalData.activityInfoOne then
    --     self:onKeyBackExit()
    -- else
    local view =
        gLobalViewManager:showDialog(
        "Dialog/ExitGame_loading.csb",
        function()
            globalLocalPushManager:commonBackGround()
            G_GetMgr(G_REF.OperateGuidePopup):saveGuideArchiveData()
            local director = cc.Director:getInstance()

            -- local iWaitTime = getHourRewardLeftTime()
            -- xcyy.GameBridgeLua:sendGameExitFlag(iWaitTime)

            director:endToLua()
        end,
        nil,
        nil,
        nil
    )
    view:setLocalZOrder(40000)
    -- end
end

--活动开启
function LobbyView:initActivityNode()
    local data = {}
    data["img_bg"] = self:findChild("img_bg")
    data["layerMask"] = self:findChild("layerMask")
    gLobalActivityManager:InitLobbyBackground(data)
end

-- 申请卡牌数据信息 --
function LobbyView:getCardSysInfo()
    CardSysManager:requestCardCollectionSysInfo()
end

--显示 高倍场
function LobbyView:showDeluexeClubView()
    globalDeluxeManager:showDeluexeClubView()
end
function LobbyView:pushDeluexeClubViews()
    globalDeluxeManager:pushDeluexeClubViews()
end

--TODO-NEWGUIDE 改变关卡图标层级
function LobbyView:changeLevelZorder(params)
    if not self.m_levelNodeControl then
        return
    end
    local moveX, idxCol, idxRow = self.m_levelNodeControl:getLevelPosXById(params)
    local cellNode = self.m_levelNodeControl:getNodeCell(idxCol, idxRow)
    if not cellNode then
        release_print("find cell col:" .. tostring(idxCol) .. " row:" .. tostring(idxRow))
        release_print("is login enter: " .. tostring(self.m_isLogin))
        local logNodePool = ""
        local _nodePools = self.m_levelNodeControl.m_nodePool or {}
        for i = 1, #_nodePools do
            local lvNode = _nodePools[i]
            if lvNode and lvNode ~= "nil" then
                logNodePool = logNodePool .. " || pool index = " .. tostring(lvNode.m_index)
                for j = 1, #lvNode.m_nodes do
                    local _lv = lvNode.m_nodes[j]
                    if _lv then
                        logNodePool = logNodePool .. ";level name = " .. _lv.m_levelName .. ",level id = " .. _lv.m_levelId
                    end
                end
            end
        end
        release_print(logNodePool)
        local txtErr = "cellNode not find!!! levelId = " .. tostring(params)
        assert(cellNode, txtErr)
        return
    end
    local wordPos = cellNode:getParent():convertToWorldSpace(cc.p(cellNode:getPosition()))
    util_changeNodeParent(gLobalViewManager:getViewLayer(), cellNode, ViewZorder.ZORDER_GUIDE)
    cellNode:setPosition(wordPos)
    -- csc 2021-05-20 20:20:33 添加新手引导期间 2s自动进入关卡
    if globalData.GameConfig:checkUseNewNoviceFeatures() and cellNode.openScheduleEnter then
        cellNode:openScheduleEnter()
    end

    local arrow = util_createView("views.newbieTask.GuideArrowNode")
    cellNode:addChild(arrow)
    arrow:showIdle(1)
    arrow:setPosition(cc.p(120, -100)) -- csc 2021-11-04 16:37:22 修改坐标
end

--------------------------- 关卡热玩 玩家 ---------------------------
-- 清除 记录的关卡热玩 玩家数据
function LobbyView:clearMachineHotPlayerList()
    local mgr = G_GetMgr(G_REF.AvatarFrame)
    if mgr then
        mgr:clearMachineHotPlayerList()
    end
end

-- 清除 记录的关卡热玩 玩家数据 5 分钟请一起热玩玩家数据
function LobbyView:checkClearMachineHotPlayerList()
    if not self.m_hotPlayerTime then
        self.m_hotPlayerTime = 0
        return
    end

    self.m_hotPlayerTime = self.m_hotPlayerTime + 1
    if self.m_hotPlayerTime > 300 then
        self.m_hotPlayerTime = 0
        self:clearMachineHotPlayerList()
    end
end
--------------------------- 关卡热玩 玩家 ---------------------------
-- 监测自身头像框是否过期
function LobbyView:checkSelfAvartarBEnabled()
    if not G_GetMgr(G_REF.AvatarFrame):checkSelfFrameIdIsLimitType() then
        return
    end

    G_GetMgr(G_REF.AvatarFrame):updateSelfAvatarFrameID()
end

-- 事件
function LobbyView:addObserverRegister()
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            gLobalViewManager:removeLoadingAnima()

            if data[1] == true then
                self:showDailyBonus()
            else
                --失败弹窗       --弹窗
                gLobalViewManager:showReConnect()
            end
        end,
        ViewEventType.NOTIFY_COLLECT_DIALY_BONUS
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, data)
            if globalData.iapLuckySpinFunc then
                globalData.iapLuckySpinFunc()
                globalData.iapLuckySpinFunc = nil
            else
                self:initNoob()
            end
        end,
        ViewEventType.NOTIFY_LUCKY_SPIN_RECONNECT
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            if data[1] == true then
                --购买成功提示界面
                local view = util_createView("views.logon.FbLoginReward")
                if gLobalSendDataManager.getLogPopub then
                    gLobalSendDataManager:getLogPopub():addNodeDot(view, "Push", DotUrlType.UrlName, true, DotEntrySite.UpView, DotEntryType.Lobby)
                end
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            else
                --失败弹窗       --弹窗
                gLobalViewManager:showReConnect()
            end
        end,
        ViewEventType.NOTIFY_FB_BINING_REWARD
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            gLobalViewManager:removeLoadingAnima()
            if params[1] == true then
                --弹窗逻辑执行下一个事件
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "configPushAds")
            else
                gLobalViewManager:showReConnect()
            end
        end,
        ViewEventType.NOTIFY_COLLECT_WATCH_VIDEO_REWARD
    )

    -- 高倍场界面
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showDeluexeClubView()
        end,
        ViewEventType.NOTIFY_SHOW_DELUEXECLUB_VIEW
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:pushDeluexeClubViews()
        end,
        ViewEventType.NOTIFY_PUSH_DELUEXECLUB_VIEWS
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if globalData.deluexeClubData:getDeluexeClubStatus() == true then
                local strTime, isOver = globalData.deluexeClubData:getLeftTimeStr()
                if isOver == false then
                    self:updateUiByDeluxe(true)
                end
            end
        end,
        ViewEventType.NOTIFY_DELUEXECLUB_POINT_UPDATE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:changeTopBottomZorder(params)
        end,
        ViewEventType.NOTIFY_CHANGE_TOPDOWN_ZORDER
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not self.m_levelNodeControl then
                return
            end
            local moveX, idxCol, idxRow = self.m_levelNodeControl:getLevelPosXById(params)
            -- if not cellNode then
            --     --高倍场补丁
            --     local hiGameID = "2" .. string.sub(tostring(params), 2)
            --     hiGameID = tonumber(hiGameID)
            --     moveX, cellNode = self.m_levelNodeControl:getLevelPosXById(hiGameID)
            -- end
            self:jumpToLevelNode(-moveX)
            local cellNode = self.m_levelNodeControl:getNodeCell(idxCol, idxRow)
            if cellNode then
                cellNode:checkGotoLevel()
                --cellNode:specialEnterLevel()
            end
        end,
        ViewEventType.NOTIFY_FORCE_INTO_LEVEL_BY_ID
    )

    -- 更新LobbyView显示状态
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local isVisibled = params.isHideLobby
            local oldRef = self.m_visibledRef
            if isVisibled then
                self.m_visibledRef = math.max(0, self.m_visibledRef + 1)
            else
                self.m_visibledRef = math.max(0, self.m_visibledRef - 1)
            end

            if oldRef == 0 and self.m_visibledRef > 0 then
                self:setLobbyVisible(false)
            elseif oldRef > 0 and self.m_visibledRef == 0 then
                if self.m_levelNodeControl then
                    self.m_levelNodeControl:setBackFrontBtnVisible(true)
                end
                if self.m_clTipview then
                    self.m_clTipview:setCollectVisible(true)
                end
                self:setLobbyVisible(true)
            end
        end,
        ViewEventType.NOTIFY_LOBBY_SHOW_VISIBLED
    )

    --拉新点链接进入游戏回调
    gLobalNoticManager:addObserver(
        self,
        function(Target, _type)
            performWithDelay(
                self,
                function()
                    self:checkInvite(_type)
                    gLobalDataManager:setStringByField("commonLink", "")
                end,
                0.8
            )
        end,
        ViewEventType.NOTIFY_ACTIVITY_INVITE_UID
    )

    --收藏功能返回大厅
    gLobalNoticManager:addObserver(
        self,
        function(Target, _type)
            self:findChild("node_center"):setVisible(true)
            self:findChild("node_broadcast"):setVisible(true)
            self:findChild("layerMask"):setVisible(true)
            self.m_levelNodeControl:setBackFrontBtnVisible(true)
        end,
        ViewEventType.NOTIFY_COLLECTLEVEL_UP
    )
    --打开收藏
    gLobalNoticManager:addObserver(
        self,
        function(Target, _type)
            self:findChild("node_center"):setVisible(false)
            self:findChild("node_broadcast"):setVisible(false)
            self:findChild("layerMask"):setVisible(false)
            self.m_levelNodeControl:setBackFrontBtnVisible(false)
        end,
        ViewEventType.NOTIFY_COLLECTLEVEL_DOWN
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not self.m_levelNodeControl then
                return
            end
            local moveX, idxCol, idxRow = self.m_levelNodeControl:getLevelPosXById(params.levelId)
            self:jumpToLevelNode(-moveX)
            if params.autoEnter then
                local cellNode = self.m_levelNodeControl:getNodeCell(idxCol, idxRow)
                if cellNode then
                    cellNode:checkGotoLevel()
                end
            end
        end,
        ViewEventType.NOTIFY_GOTO_LEVEL_BY_ID
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, gameId, params)
            self:openNewLevel(gameId, params)
        end,
        ViewEventType.NOTIFY_OPEN_NEWLEVEL
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not self.m_levelNodeControl then
                return
            end
            local moveX = self.m_levelNodeControl:getLevelPosXByName(params.machineName)
            self:jumpToLevelNode(-moveX)
        end,
        ViewEventType.NOTIFY_LOBBY_ROLLTO_LEVEL_POS
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not self.m_levelNodeControl then
                return
            end
            self.m_levelNodeControl:updateRecmdLevelAction(params.secs, params.isShow)
        end,
        ViewEventType.NOTIFY_LOBBY_CHANGE_RECMD_LEVEL_VISIBLE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not self.m_levelNodeControl then
                return
            end
    
            local isPlaying = params.isPlaying or false
            local secs = params.secs or 0
            if isPlaying then
                local group = params.group
                local posX = self.m_levelNodeControl:getRecmdLevelToLeftPos(group)
                if secs and secs > 0 then
                    self:moveToLevelNode(posX, secs)
                else
                    self:jumpToRecmdNode(posX)
                end
            end
        end,
        ViewEventType.NOTIFY_LOBBY_CHANGE_RECMD_LEVEL_ACTION
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.initNoob then
                self:initNoob()
            end
        end,
        ViewEventType.NOTIFY_NEWUSER_LOBBY_INITNOOB
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.id == NOVICEGUIDE_ORDER.goldenEntrepotOpen.id then
                self:openCashBonusTishi(1)
            elseif params.id == NOVICEGUIDE_ORDER.goldenEntrepotClose.id then
                self:openCashBonusTishi(2)
            end
        end,
        ViewEventType.NOTIFY_NOVICEGUIDE_SHOW
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, activityId)
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveActivity then
                self.m_levelNodeControl:checkRemoveActivity(activityId)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_CLOSE
    )

    -- 以后替代 NOTIFY_ACTIVITY_CLOSE 事件
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveActivity then
                self.m_levelNodeControl:checkRemoveActivity(params.id)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    -- 活动完成条件达成
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveActivity then
                self.m_levelNodeControl:checkRemoveActivity(params.id)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_COMPLETED
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, activityId)
            self:updateUiByDeluxe(true)
        end,
        ViewEventType.NOTIFY_DELUXE_UPDATE_LOBBY
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- 小猪银行购买后，刷新大厅展示图
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                self.m_levelNodeControl:checkRemoveFeature("PiggyNoviceDiscount")
            end
        end,
        ViewEventType.NOTIFY_UPDATE_PIGBANK_DATA
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- 新手quest到期，刷新大厅展示图
            if not self.m_levelNodeControl then
                return
            end
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                local featureName = "QuestNewUser"
                if globalData.GameConfig:checkUseNewNoviceFeatures() then
                    featureName = "QuestNewUserHall"
                end
                self.m_levelNodeControl:checkRemoveFeature(featureName)
            end
        end,
        ViewEventType.NOTIFY_UPDATE_QUEST_NEWUSER
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            if not G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData() then
                -- 移除首充促销轮播图
                if not self.m_levelNodeControl then
                    return
                end
                if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                    self.m_levelNodeControl:checkRemoveFeature("FirstCommomSaleHall")
                end
            end
        end,
        ViewEventType.NOTIFY_FIRST_SALE_BUYSUCCESS
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            if data and data.type ~= "failed" then
                -- 移除促销轮播图
                if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                    self.m_levelNodeControl:checkRemoveFeature("holidayEndSaleHall")
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_HOLIDAY_END_SALE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, func)
            --FBLink领奖, 邮件推送奖励
            globalPlatformManager:checkShowFacebookLinkReward(func)
        end,
        ViewEventType.NOTIFY_CHECK_FBLINK_REWARD
    )
    
    gLobalNoticManager:addObserver(
        self,
        function(self, func)
            if self.m_CardOverFunc then
                self.m_CardOverFunc()
                self.m_CardOverFunc = nil
            end
        end,
        ViewEventType.NOTIFY_CARD_SYS_OVER
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params == "autoCard" then
                self:checkAutoCard()
            end
        end,
        ViewEventType.NOTIFY_POPVIEW_EVENT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.changeLevelZorder then
                self:changeLevelZorder(params)
            end
        end,
        ViewEventType.NOTIFY_CHANGE_LOBBYENTER_ZORDER
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_levelNodeControl:jumpToFront()
        end,
        ViewEventType.NOTIFY_LOBBY_CLICK_BACKFRONT
    )

    -- 切换大厅 显示风格
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.updateLobbyNewUserExpandUIVisible then
                self:updateLobbyNewUserExpandUIVisible()
            end
            if not self.m_initNoob and self.initNoob then
                self:initNoob()
            end
        end,
        NewUserExpandConfig.EVENT_NAME.UPDATE_LOBBY_VIEW_EXPAND_TYPE
    )

    -- 扩圈系统加载完毕
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.initNewUserExpandEntryUI then
                self:initNewUserExpandEntryUI()
            end
        end,
        NewUserExpandConfig.EVENT_NAME.LOAD_EXPAND_FEATURE
    )

    -- 破冰促销结束
    local IcebreakerSaleConfig = util_require("GameModule.IcebreakerSale.config.IcebreakerSaleConfig")
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 破冰促销结束 移除 展示图
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                self.m_levelNodeControl:checkRemoveFeature("IcebreakerSaleHall")
            end
        end,
        IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_OVER
    )

    -- 限时促销
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 移除限时促销广告位
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                self.m_levelNodeControl:checkRemoveFeature("HourDealHall")
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_HOUR_DEAL_TIMEOUT
    )

    -- 插入一个展示图
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- 活动开启，插入展示图
            if self.m_levelNodeControl and self.m_levelNodeControl.insertHallNode then
                self.m_levelNodeControl:insertHallNode(params)
            end
        end,
        ViewEventType.NOTIFY_LOBBY_INSERT_HALL_AND_SLIDE
    )

    -- 生日促销
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 移除生日促销广告位
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                self.m_levelNodeControl:checkRemoveFeature("BirthdaySaleHall")
            end
        end,
        ViewEventType.NOTIFY_BIRTHDAY_PROMOTION_TIMEOUT
    )

    -- 新手期集卡开启活动 到期移除轮播展示
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 新手期集卡开启活动 到期移除 展示图
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                self.m_levelNodeControl:checkRemoveFeature("NewUserCardOpenHall")
            end
        end,
        ViewEventType.CLOSE_REMOVE_NEW_USER_CARD_OPEN_HALL_SLIDE
    )

    -- 新手期集卡 促销 结束 移除轮播展示
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 新手期集卡 促销 结束 移除  展示图
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                self.m_levelNodeControl:checkRemoveFeature("CardNoviceSaleHall")
            end
        end,
        CardNoviceCfg.EVENT_NAME.REMOVE_CARD_NOVICE_SALE_HALL_SLIDE
    )

    -- 新手期集卡 双倍奖励 结束 移除轮播展示
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 新手期集卡 双倍奖励 结束 移除  展示图
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                self.m_levelNodeControl:checkRemoveFeature("CardNoviceDoubleRewardHall")
            end
        end,
        CardNoviceCfg.EVENT_NAME.REMOVE_CARD_NOVICE_DOUBLE_REWARD_HALL_SLIDE
    )
    
    -- 三档首冲
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 移除三档首冲 展示图
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                self.m_levelNodeControl:checkRemoveFeature("FirstSaleMultiHall")
            end
        end,
        ViewEventType.NOTIFY_REMOVE_FIRST_SALE_MULTI_HALL_SLIDE
    )

    -- 限时集卡多倍奖励
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                self.m_levelNodeControl:checkRemoveFeature("AlbumMoreAwardHall")
                self.m_levelNodeControl:checkRemoveFeature("AlbumMoreAwardSaleHall")
            end
        end,
        ViewEventType.NOTIFY_ALBUM_MORE_AWARD_TIME_END
    )
    -- 亿万赢钱挑战
    local TrillionChallengeConfig = util_require("GameModule.TrillionChallenge.config.TrillionChallengeConfig")
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 亿万赢钱挑战 移除展示图
            if self.m_levelNodeControl and self.m_levelNodeControl.checkRemoveFeature then
                self.m_levelNodeControl:checkRemoveFeature("TrillionChallengeHall")
            end
        end,
        TrillionChallengeConfig.EVENT_NAME.NOTIFY_REMOVE_TRILLION_CHALLENGE_HALL
    )
end

return LobbyView
