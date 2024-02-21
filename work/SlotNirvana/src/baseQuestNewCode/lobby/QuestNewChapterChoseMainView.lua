--
-- 梦幻 Quest活动主界面
--

local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local QuestNewChapterChoseMainView = class("QuestNewChapterChoseMainView", BaseActivityMainLayer)

function QuestNewChapterChoseMainView:ctor()
    QuestNewChapterChoseMainView.super.ctor(self)
    self:setLandscapeCsbName(QUESTNEW_RES_PATH.QuestNewChapterChoseMainView)

    --self:setShowActionEnabled(false)
    --self:setHideActionEnabled(false)
    self:setHideLobbyEnabled(true)
    --self:setIgnoreAutoScale(true)

    self:setBgm(QUESTNEW_RES_PATH.QuestNewBGMPath)
    self:setExtendData("QuestNewChapterChoseMainView")
end

--初始化数据
function QuestNewChapterChoseMainView:initDatas()
    globalData.slotRunData.isDeluexeClub = false
    globalData.deluexeHall = false
    self.m_activityData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()

    self.m_questCellList = {}
    --读取quest配置文件
    --请求quest排行数据
    G_GetMgr(ACTIVITY_REF.QuestNew):requestQuestRank()

    --G_GetMgr(ACTIVITY_REF.QuestNew):requestGetPool()
end

function QuestNewChapterChoseMainView:initCsbNodes()
    
    self.node_top = self:findChild("node_top") -- 顶部三个金币奖励总结点 
    
    local node_minorbanzi  = self:findChild("node_minorbanzi") 
    local node_grandbanzi = self:findChild("node_grandbanzi") 
    local node_majorbanzi = self:findChild("node_majorbanzi") 
    self.m_topCoinsNodeArray = {node_minorbanzi,node_majorbanzi,node_grandbanzi}


    self.m_node_Entrance = self:findChild("node_Entrance")
    self.m_touchLayer = self:findChild("touch")
    self.m_touchLayer:setSwallowTouches(false)
    self:addNodeClicked(self.m_touchLayer)

    self.m_lb_time = self:findChild("lb_djs") -- 倒计时
    
end

function QuestNewChapterChoseMainView:addNodeClicked(node)
    if not node then
        return
    end
    node:addTouchEventListener(handler(self, self.clickFunc))
end

--初始化
function QuestNewChapterChoseMainView:initView()
    self:initTopGoldNode()
    self:initChapterCellList()
    self:showDownTimer()
    --self:addMask()
end

function QuestNewChapterChoseMainView:initChapterCellList()
    local currentChapterId = G_GetMgr(ACTIVITY_REF.QuestNew):getCurrentChapter()
    local allChapterData = G_GetMgr(ACTIVITY_REF.QuestNew):getAllChapterData()

    if allChapterData ~= nil then
        if not self.uiList then
            self.uiList = {}
            local conSize =  0
            for index, chapterData in pairs(allChapterData) do
                -- 创建章节cell
                local albumCell = util_createView(QUESTNEW_CODE_PATH.QuestNewChapterChossCellNode)
                albumCell:updateCell(index, chapterData)
                table.insert(self.uiList, albumCell)
                conSize =  albumCell:getContentSize()
            end

            local circleScrollUI = util_createView("base.CircleScrollUI")
            circleScrollUI:setMargin(0)
            circleScrollUI:setMarginXY(120, 20)
            circleScrollUI:setMaxTopYPercent(0.5)
            circleScrollUI:setTopYHeight(240)
            circleScrollUI:setMaxAngle(20)
            circleScrollUI:setRadius(5000)
            
            if currentChapterId > 2 then
                local moveNum = currentChapterId - 2
                if currentChapterId == #allChapterData then
                    moveNum = currentChapterId - 3
                end
                circleScrollUI:scrollToHorizontalByIndex(
                    - moveNum * conSize.width,
                    1.5,
                    function()
                        --self:addGuideLayer()
                        self:checkHasUnlockNewChapter()
                    end
                )
            else
                performWithDelay(
                    self,
                    function()
                        if not tolua.isnull(self) then
                            --self:addGuideLayer()
                            self:checkHasUnlockNewChapter()
                        end
                    end,
                    1
                )
            end

            circleScrollUI:setUIList(self.uiList)

            local scale = self:findChild("root"):getScale()
            circleScrollUI:setDisplaySize(display.width / scale, display.height - 200)
            circleScrollUI:setPosition(-display.width / scale / 2, -4770 - display.height / 2-200)
            self.m_node_Entrance:addChild(circleScrollUI)
            util_setCascadeOpacityEnabledRescursion(self, true)
        else
            for i = 1, #self.uiList do
                local albumCell = self.uiList[i]
                albumCell:updateCell(i, allChapterData[i])
            end
        end
    end
end

-- 顶部金币滚动节点
function QuestNewChapterChoseMainView:initTopGoldNode()
    self.m_topCoinsShowNodeArray = {}
    for i=1,3 do
        local coinsShowNode = util_createView(QUESTNEW_CODE_PATH.QuestNewTopCoinsShowNode,{type = i})
        self.m_topCoinsShowNodeArray[i] = coinsShowNode
        local node = self.m_topCoinsNodeArray[i]
        if node then
            node:addChild(coinsShowNode)
        end
    end
    self:initGoldTimer()
end

function QuestNewChapterChoseMainView:initGoldTimer()
    local updateFun = function(isInit)
        if self.m_activityData:isCanShowRunGold() then
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

function QuestNewChapterChoseMainView:showActionCallback()
    QuestNewChapterChoseMainView.super.showActionCallback(self)
end

function QuestNewChapterChoseMainView:getLanguageTableKeyPrefix()
    local theme = self.m_activityData:getThemeName()
    return theme .. "MainView"
end

function QuestNewChapterChoseMainView:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_info" then
        G_GetMgr(ACTIVITY_REF.QuestNew):showInfo()
    end
end

function QuestNewChapterChoseMainView:onEnter()
    QuestNewChapterChoseMainView.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:afterRequestNextRound(params)
        end,
        ViewEventType.NOTIFY_REQUEST_AFTER_DONEXTROUND
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.type == "success" then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_REQUEST_AFTER_WHEELREWARD
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:checkHasUnlockNewChapter()
        end,
        ViewEventType.NOTIFY_NEWQUEST_MAINMAP_CLOSE
    )

    -- 活动结束事件
    gLobalNoticManager:addObserver(
       self,
       function(self, params)
           if params.name == ACTIVITY_REF.QuestNew then
               self:closeUI()
           elseif params.name == ACTIVITY_REF.QuestNewRush then
               self:resetQuestRushState()
           end
       end,
       ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function QuestNewChapterChoseMainView:onExit()
    G_GetMgr(ACTIVITY_REF.QuestNew):setIsEnterQuestLayer(false)
    
    QuestNewChapterChoseMainView.super.onExit(self)
end

-- 请求开启下一轮 之后
function QuestNewChapterChoseMainView:afterRequestNextRound(params)
    if params.type == "success" then
        self:closeUI(
            function ()
                util_nextFrameFunc(function ()
                    G_GetMgr(ACTIVITY_REF.QuestNew):showMainLayer()
                end)
            end
        )
    end
end

function QuestNewChapterChoseMainView:onKeyBack()
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

--关闭quest
function QuestNewChapterChoseMainView:closeUI(callback)
    self:stopTimerAction()
    QuestNewChapterChoseMainView.super.closeUI(self,callback)
end

-- quest挑战活动结束,清楚活动入口
function QuestNewChapterChoseMainView:resetQuestRushState()
    if tolua.isnull(self.m_nodeRushEntry) then
        return
    end

    self.m_nodeRushEntry:removeSelf()
    self.m_nodeRushEntry = nil
end

function QuestNewChapterChoseMainView:getRefName()
    return ACTIVITY_REF.QuestNew
end

-----------------------------------------检测是否开启新章节-------------------------------------------
function QuestNewChapterChoseMainView:checkHasUnlockNewChapter()
    if not tolua.isnull(self) then
        self:checkCompleteAct()
    end
end

function QuestNewChapterChoseMainView:checkCompleteAct()
    local allChapterData = G_GetMgr(ACTIVITY_REF.QuestNew):getAllChapterData()
    local willDo = false
    for i,cellNode in ipairs(self.uiList) do
        local doAct = cellNode:doCompleteAct(function ()
            self:checkUnlockAct()
        end)
        if doAct then
            willDo = true
        end
    end
    if not willDo then
        self:checkUnlockAct()
    end
end

function QuestNewChapterChoseMainView:checkUnlockAct()
    for i,cellNode in ipairs(self.uiList) do
        cellNode:doUnlockAct(function ()
            -- body
        end)
    end
end

-------------------------------------------倒计时--------------------------------------
--显示倒计时
function QuestNewChapterChoseMainView:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 0.1)
    self:updateLeftTime()
end

function QuestNewChapterChoseMainView:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function QuestNewChapterChoseMainView:updateLeftTime()
    local gameData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    if gameData ~= nil then
        local leftTime = math.max(gameData:getExpireAt(), 0)
        local strLeftTime,isOver,isFullDay = util_daysdemaining(leftTime,true)
        self.m_lb_time:setString(strLeftTime)
    else
        self:stopTimerAction()
    end
end

-----------------------------------------------------华丽的分割线---------新手引导相关----start------------

function QuestNewChapterChoseMainView:addMask()
    if G_GetMgr(ACTIVITY_REF.QuestNew):canDoChapterGuide() then
        self.mask = util_newMaskLayer()
        self.mask:setOpacity(0)
        gLobalViewManager:getViewLayer():addChild(self.mask, ViewZorder.ZORDER_GUIDE)
    end
end

function QuestNewChapterChoseMainView:addGuideLayer()
    if G_GetMgr(ACTIVITY_REF.QuestNew):canDoChapterGuide() then
        self.data = {
            pos = nil,
            zorder = 1,
            parent = nil
        }
        local callback =function ()
            self:resetGuideNodeZOrder()
        end
        self.m_guideLayer = util_createView(QUESTNEW_CODE_PATH.QuestNewChapterChoseGuideView,callback)
        gLobalViewManager:showUI(self.m_guideLayer, ViewZorder.ZORDER_GUIDE + 1)
        self:changeGuideNodeZorder()
    end
end

function QuestNewChapterChoseMainView:changeGuideNodeZorder()
    local node = self.uiList[#self.uiList]
    self.data.node = node
    self.data.zorder = node:getZOrder()
    self.data.parent = node:getParent()
    
    self.data.pos = cc.p(node:getPosition())

    local par =  node:getParent()
    local x2,y2 = par:getPosition()
    
    local newPos = par:getParent():convertToWorldSpace(cc.p(x2,y2)) 
    newPos.y = newPos.y + 300
    newPos.x=  newPos.x + 240
 
    node:setPosition(newPos)

    util_changeNodeParent(gLobalViewManager:getViewLayer(), node, ViewZorder.ZORDER_GUIDE + 2)
    -- 横竖版都需要适配
    local currLayerScale = self.m_csbNode:getChildByName("root"):getScale()
    node:setScale(currLayerScale)
end

function QuestNewChapterChoseMainView:resetGuideNodeZOrder()
    if self.mask then
        self.mask:removeFromParent()
        self.mask = nil
    end
    if self.data and self.data.node ~= nil then
        util_changeNodeParent(self.data.parent, self.data.node, self.data.zorder)
        self.data.node:setScale(1)
        self.data.node:setPosition(self.data.pos)
        self.data.parent = nil
        self.data.node = nil
        self.data.zorder = 1
        self.data.pos = nil
    end
end

return QuestNewChapterChoseMainView
