--
-- Quest活动主界面
--

local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local QuestNewMainMapView = class("QuestNewMainMapView", BaseLayer)

function QuestNewMainMapView:ctor()
    QuestNewMainMapView.super.ctor(self)
    --self:setShowActionEnabled(false)
    --self:setHideActionEnabled(false)
    self:setHideLobbyEnabled(true)
    --self:setIgnoreAutoScale(true)
    self:setLandscapeCsbName(QUESTNEW_RES_PATH.QuestNewMainMapView)
    self:setExtendData("QuestNewMainMapView")
    self:setHasGuide(true)
    self:setBgm(QUESTNEW_RES_PATH.QuestNewBGMPath)
end

--初始化数据
function QuestNewMainMapView:initDatas(chapterId)
    globalData.slotRunData.isDeluexeClub = false
    globalData.deluexeHall = false

    self.m_activityData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    self.m_chapterId = chapterId

    -- if not self.m_activityData:isCanShowRunGold() then
    --     G_GetMgr(ACTIVITY_REF.QuestNew):requestGetPool()
    -- end
end

function QuestNewMainMapView:initCsbNodes()
    
    self.node_top = self:findChild("node_top") -- 顶部三个金币奖励总结点 
    
    local node_minorbanzi  = self:findChild("node_minorbanzi") 
    local node_grandbanzi = self:findChild("node_grandbanzi") 
    local node_majorbanzi = self:findChild("node_majorbanzi") 
    self.m_topCoinsNodeArray = {node_minorbanzi,node_majorbanzi,node_grandbanzi}
    
    self.node_logo = self:findChild("Node_log") -- logo节点
    self.node_rank = self:findChild("Node_rank") -- 排行榜节点
    local rank_posX = self.node_rank:getPositionX()
    self.node_rank:setPositionX(rank_posX - util_getBangScreenHeight())

    self.node_sale = self:findChild("Node_sale") -- 促销节点
    local sale_posX = self.node_sale:getPositionX()
    self.node_sale:setPositionX(sale_posX - util_getBangScreenHeight())

    self.node_rush = self:findChild("Node_rush") -- rush
    local rush_posX = self.node_rush:getPositionX()
    self.node_rush:setPositionX(rush_posX - util_getBangScreenHeight())

    self.btn_sale = self:findChild("btn_chuxiao")

    self.node_reward = self:findChild("node_reward")

    self.node_bg = self:findChild("questbg")


    self.node_starmeter_entrance = self:findChild("node_starmeter_entrance")

    self.m_nodeMapRoad = self:findChild("node_map")
end

--初始化
function QuestNewMainMapView:initView()
    G_GetMgr(ACTIVITY_REF.QuestNew):setDoingMapCheckLogic(true)
    self:initTopGoldNode()
    self:initIconNode()
    self:initRushEntryNode()
    self:initScrollLayer()
end


-- 顶部金币滚动节点
function QuestNewMainMapView:initTopGoldNode()
    self.m_topCoinsShowNodeArray = {}
    for i=1,3 do
        local coinsShowNode = util_createFindView(QUESTNEW_CODE_PATH.QuestNewTopCoinsShowNode,{type = i})
        self.m_topCoinsShowNodeArray[i] = coinsShowNode
        local node = self.m_topCoinsNodeArray[i]
        if node then
            node:addChild(coinsShowNode)
        end
    end
    self:initGoldTimer()
end

function QuestNewMainMapView:initGoldTimer()
    local updateFun = function(isInit)
        if self.m_activityData:isCanShowRunGold() then
            if G_GetMgr(ACTIVITY_REF.QuestNew):isStopPoolRun() then
                return
            end
            G_GetMgr(ACTIVITY_REF.QuestNew):updateQuestGoldIncrease(false)
            for index, coinsShowNode in ipairs(self.m_topCoinsShowNodeArray) do
                coinsShowNode:updateCoins()
            end
        end
    end
    updateFun(true)
    schedule(
        self,
        function()
            updateFun()
        end,
        0.1
    )
end

--初始化quest大厅节点
function QuestNewMainMapView:initIconNode()
    --logo
    if self.node_logo then
        local icon_logo = util_createFindView(QUESTNEW_CODE_PATH.QuestNewLobbyLogoNode)
        if icon_logo then
            icon_logo:addTo(self.node_logo)
        end
    end

    --排行
    if self.node_rank then
        local icon_rank = util_createFindView(QUESTNEW_CODE_PATH.QuestNewLobbyRankNode)
        if icon_rank then
            icon_rank:addTo(self.node_rank)
        end
    end

    --促销
    if self.node_sale then
        local icon_sale = util_createFindView(QUESTNEW_CODE_PATH.QuestNewLobbySaleNode)
        if icon_sale then
            icon_sale:addTo(self.node_sale)
        end
    end

    --星星奖励
    if self.node_starmeter_entrance then
        local icon_star = util_createFindView(QUESTNEW_CODE_PATH.QuestNewLobbyStarNode ,self.m_chapterId)
        if icon_star then
            icon_star:addTo(self.node_starmeter_entrance)
        end
    end
end

-- 增加quest挑战活动入口
function QuestNewMainMapView:initRushEntryNode()
    if not self.node_rush then
        return
    end

    local bOpenLoad = gLobalActivityManager:checktActivityOpen(ACTIVITY_REF.QuestNewRush)
    if not bOpenLoad then
        return
    end

    -- if tolua.isnull(self.btn_sale) or tolua.isnull(self.node_sale) then
    --     return
    -- end
    local nodeRushEntry = util_createFindView(QUESTNEW_CODE_PATH.QuestNewRushEntry, false)
    if tolua.isnull(nodeRushEntry) then
        return
    end

    nodeRushEntry:setScale(0.5)
    nodeRushEntry:addTo(self.node_rush)
    -- local pos = cc.p(self.node_sale:getPosition())
    -- local posY = pos.y
    -- if self.node_sale:isVisible() then
    --     local size = self.btn_sale:getContentSize()
    --     local offsetY = 0 -- -30
    --     posY = pos.y - size.height + offsetY
    -- end
    -- nodeRushEntry:move(pos.x, posY)
    self.m_nodeRushEntry = nodeRushEntry
end

function QuestNewMainMapView:checkUpdateRushEntry()
    local bFinish = false
    if self.m_activityData then
        bFinish = self.m_activityData:IsTaskAllFinish()
    end
    if not bFinish then
        self:updateRushEntry()
    end
end

-- 更新quest挑战活动入口
function QuestNewMainMapView:updateRushEntry(_delayTime)
    if tolua.isnull(self.m_nodeRushEntry) then
        return
    end

    _delayTime = _delayTime or 0
    performWithDelay(
        self,
        function()
            if tolua.isnull(self.m_nodeRushEntry) then
                return
            end
            self.m_nodeRushEntry:updateProgressUI()
        end,
        _delayTime
    )
end
-- quest挑战活动结束,清楚活动入口
function QuestNewMainMapView:resetQuestRushState()
    if tolua.isnull(self.m_nodeRushEntry) then
        return
    end

    self.m_nodeRushEntry:removeSelf()
    self.m_nodeRushEntry = nil
end

--------------------------------------滑动部分--------------------------------------------

function QuestNewMainMapView:initScrollLayer( )
    -- 初始化滑动界面
    local displayX = display.width
    local scaleUI = self:getUIScalePro()
    -- 创建 road 滑动界面
    self.m_nodeScrollRoad = util_createView(QUESTNEW_CODE_PATH.QuestNewMapRoadLayer,{chapterId = self.m_chapterId})
    self.m_nodeMapRoad:addChild(self.m_nodeScrollRoad )

    self.m_nodeScrollRoad:setCheckStarMeterFunc(function ()
        self:checkHasStarMetersRewardToGain() --检测starMeter 奖励
    end)
    --self.m_nodeMapRoad:setPosition(-display.cx,-display.cy)
    
    --创建 路 滑动类 默认创建出来是在layer 的中心点
    self.m_scrollRoad = util_createView(QUESTNEW_CODE_PATH.QuestNewMapRoadScroll, self.m_nodeScrollRoad, cc.p(0,0))
    local mapLimitLenRoad = displayX/scaleUI - 3900 
    self.m_scrollRoad:setMoveLen(mapLimitLenRoad)

    -- 根据当前小车的位置计算出默认的 起始坐标
    local startX = self.m_nodeScrollRoad:getStartX()
    self:updateScrollPos(startX)

    -- 默认不可滑动 需要等到星星都加载完毕
    --self:setScrollMoveFlag(true)
end


-- 小车移动的同时滑动背景条
function QuestNewMainMapView:updateScrollPos(_moveX)
    --更新滑动层坐标
    self.m_scrollRoad:startMove(_moveX)
end

function QuestNewMainMapView:setScrollMoveFlag(_canMove)
    if _canMove == false then
        self.m_scrollRoad:stopAutoScroll()
    end
    self.m_scrollRoad:setMoveState(_canMove)

    self.m_isMoving = not _canMove
end

--------------------------------------滑动部分--------------------------------------end------


function QuestNewMainMapView:checkHasStarMetersRewardToGain()
    if self:isInGuide() then
        G_GetMgr(ACTIVITY_REF.QuestNew):setDoingMapCheckLogic(false)
        return
    end

    local chapterData = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterDataByChapterId(self.m_chapterId)
    local firstEnter = G_GetMgr(ACTIVITY_REF.QuestNew):checkFirstEnterChapter(self.m_chapterId)
    if chapterData:checkHasStarMetersRewardToGain() or firstEnter then
        G_GetMgr(ACTIVITY_REF.QuestNew):showStarPrizeView(self.m_chapterId,function ()
            if not self:checkGuide() then
                self:checkShowRankLayer()
                self:checkShowRushLayer()
                G_GetMgr(ACTIVITY_REF.QuestNew):setDoingMapCheckLogic(false)
            else
                self.m_nodeScrollRoad:checkGuide()
            end
        end)
    else
        self:checkShowRankLayer()
        self:checkShowRushLayer()
        G_GetMgr(ACTIVITY_REF.QuestNew):setDoingMapCheckLogic(false)
    end
end

function QuestNewMainMapView:checkShowRankLayer()
    if G_GetMgr(ACTIVITY_REF.QuestNew):isWillAutoShowRankLayer() then
        G_GetMgr(ACTIVITY_REF.QuestNew):showRankView()
    end
end

function QuestNewMainMapView:checkShowRushLayer()
    if G_GetMgr(ACTIVITY_REF.QuestNew):isWillAutoShowRushLayer() then
        G_GetMgr(ACTIVITY_REF.QuestNew):setWillAutoShowRushLayer(false)
        G_GetMgr(ACTIVITY_REF.QuestNewRush):showMainView()
    end
end

function QuestNewMainMapView:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_info" then
       G_GetMgr(ACTIVITY_REF.QuestNew):showInfo()
    end
end

function QuestNewMainMapView:onEnter()
    QuestNewMainMapView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(target, params)
        local moveX = params.moveX
        self:updateScrollPos(moveX)
    end,ViewEventType.NOTIFY_NEWQUEST_DOMAPMOVE)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self.m_isBackToChoose = true
            self:closeUI()
        end,
        ViewEventType.NOTIFY_REQUEST_AFTER_WHEELLAYERCLOSE
    )

    gLobalNoticManager:addObserver(self,function(target, params)
        local flag = params.flag
        self:setScrollMoveFlag(flag)
    end,ViewEventType.NOTIFY_NEWQUEST_DOMAPMOVE_FLAG)

    -- 活动结束事件
    gLobalNoticManager:addObserver(
       self,
       function(self, params)
           if params.name == ACTIVITY_REF.Quest then
               self:closeUI()
           elseif params.name == ACTIVITY_REF.QuestNewRush then
               self:resetQuestRushState()
           end
       end,
       ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    -- 刷新 挑战活动 入口UI
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateRushEntry()
        end,
        ViewEventType.NOTIFY_QUEST_RUSH_ENTERY_UPDATE
    )
    
    self:checkUpdateRushEntry()
end

function QuestNewMainMapView:onShowedCallFunc()
    self:checkGuide()
end

function QuestNewMainMapView:onExit()
    G_GetMgr(ACTIVITY_REF.QuestNew):setIsEnterQuestLayer(false)
    
    QuestNewMainMapView.super.onExit(self)
end

function QuestNewMainMapView:onKeyBack()
    -- --引导期间不能点击返回键
    -- if self.m_activityData and self.m_activityData.p_expireAt then
    --     --不是第一关 可能是清除本地数据
    --     if self.m_activityData:getIsFirstStage() then
    --         local isWheelGuide = gLobalDataManager:getBoolByField("quest_wheelGuide" .. self.m_activityData.p_expireAt, true)
    --         if isWheelGuide then
    --             return
    --         end
    --     end
    -- end
    -- local view =
    --     gLobalViewManager:showDialog(
    --     "Dialog/ExitGame_Lobby.csb",
    --     function()
    --         self:closeUI()
    --     end
    -- )
    -- view:setLocalZOrder(ViewZorder.ZORDER_LOADING)
end


function QuestNewMainMapView:setBackToChooseMainLayer(isBackToChoose)
    self.m_isBackToChoose = isBackToChoose
end
--关闭quest
function QuestNewMainMapView:closeUI(callFunc)

    local isBackToChoose = self.m_isBackToChoose 
    
    QuestNewMainMapView.super.closeUI(self,function ()
        if callFunc then
            callFunc()
        end
        if isBackToChoose then
            G_GetMgr(ACTIVITY_REF.QuestNew):showMainLayer(false)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWQUEST_MAINMAP_CLOSE)
        end
    end)
end

----------------------------------------引导相关------------------------------------
function QuestNewMainMapView:isInGuide()
    local guideStep = 0
    local willDoStep1 = G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():isGuideGoing("enterQuestMap_1")
    if willDoStep1 then
        guideStep = 1
    else
        local willDoStep2 = G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():isGuideGoing("enterQuestMap_2")
        if willDoStep2 then
            if self.m_chapterId == 1 then
                local chapterData = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterDataByChapterId(self.m_chapterId)
                if chapterData and chapterData:getCurrentStage() == 2 then
                    guideStep = 2
                end
            end
        else
            local willDoStep3 = G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():isGuideGoing("enterQuestMap_3")
            if willDoStep3 then
                guideStep = 3
            else
                local willDoStep4 = G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():isGuideGoing("enterQuestMap_4")
                if willDoStep4 then
                    guideStep = 4
                end
            end
        end
    end
    --guideStep = 0
    return guideStep > 0,guideStep
end

function QuestNewMainMapView:checkGuide()
    local inGuide ,guideStep  = self:isInGuide()
    if guideStep == 2 then
        G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():triggerGuide(self, "enterQuestMap_2", ACTIVITY_REF.QuestNew)
    end
    return inGuide
end


return QuestNewMainMapView
