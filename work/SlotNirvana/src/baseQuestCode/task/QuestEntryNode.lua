-- Created by jfwang on 2019-05-21.
-- Activity_Quest入口
--
local QuestEntryNode = class("QuestEntryNode", BaseView)

local TASK_STATUS = {
    HIDE = 1,
    SHOW = 2,
    DOING = 3
}

function QuestEntryNode:getCsbNodePath()
    return QUEST_RES_PATH.QuestEntryNode
end

function QuestEntryNode:initUI(data)
    self:createCsbNode(self:getCsbNodePath())

    self.m_fScale = 1.2
    --收起按钮
    self.m_packupAniEnd = true
    self.m_packupState = 0

    self.m_IsQuestLogin = false
    self.m_taskData = {}
    self.m_taskNodeList = {}

    self.m_taskStatus = TASK_STATUS.HIDE
    self.m_nextStatus = nil
    self.m_isResetTaskStatus = nil

    self.m_bOpenProgress = false
    self.m_config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
end

function QuestEntryNode:initCsbNodes()
    self.m_lockNode = self:findChild("Sprite_lock")
    if self.m_lockNode then
        self.m_lockNode:setVisible(false)
    end

    self.m_logoNode = self:findChild("node_sp_1")
    if not tolua.isnull(self.m_logoNode) then
        self.m_logoNode:setVisible(true)
    end

    self.m_saleNode = self:findChild("node_sp_3")
    if not tolua.isnull(self.m_saleNode) then
        self.m_saleNode:setVisible(false)
    end

    self.bar_var = self:findChild("bar_var")
    if self.bar_var then
        self.bar_var:setPercent(0)
    end

    self.m_lb_bar = self:findChild("m_lb_bar")
    if self.m_lb_bar then
        self.m_lb_bar:setString("0%")
    end

    self.node_task = self:findChild("node_task")

    self.m_panelSmall = self:findChild("Node_PanelSize")
    self.m_panelNormal = self:findChild("Node_PanelSize_launch")
end

--切换任务状态
function QuestEntryNode:changeTaskStatus()
    if self.m_isResetTaskStatus then
        return
    end
    if self.m_taskStatus == TASK_STATUS.DOING then
        return
    elseif self.m_taskStatus == TASK_STATUS.SHOW then
        self.m_nextStatus = TASK_STATUS.HIDE
    elseif self.m_taskStatus == TASK_STATUS.HIDE then
        self.m_nextStatus = TASK_STATUS.SHOW
    end
    self.m_taskStatus = TASK_STATUS.DOING
    self:runChangeTaskAnima(
        function()
            if self.m_isResetTaskStatus then
                return
            end
            self.m_taskStatus = self.m_nextStatus
            self.m_nextStatus = nil
        end
    )
end

--重置状态
function QuestEntryNode:resetTaskStatus()
    self:stopAllActions()
    self.m_isResetTaskStatus = true
    self.m_taskStatus = TASK_STATUS.HIDE
    self.m_nextStatus = nil
    local count = #self.m_taskNodeList
    for i = 1, count do
        local taskNode = self.m_taskNodeList[i]
        if taskNode ~= nil then
            taskNode:hideTipsView(true)
        end
    end

    -- 需要重新开启计时器
    schedule(
        self,
        function()
            if self.isClose then
                return
            end
            self:updateTime()
        end,
        1
    )
end

function QuestEntryNode:taskCellAnima(index, isShow)
    if self.m_isResetTaskStatus then
        return
    end
    local taskNode = self.m_taskNodeList[index]
    if taskNode ~= nil then
        if isShow then
            taskNode:showTipsView(true)
            self:hideLater()
        else
            taskNode:hideTipsView()
        end
    end
end

function QuestEntryNode:hideLater()
    performWithDelay(
        self,
        function()
            if self.m_taskStatus == TASK_STATUS.HIDE then
                return
            end
            self:changeTaskStatus()
        end,
        10
    )
end

--播放切换动画
function QuestEntryNode:runChangeTaskAnima(func)
    if self.m_nextStatus == TASK_STATUS.SHOW then
        local count = #self.m_taskNodeList
        for i = 1, count do
            if i == 1 then
                self:taskCellAnima(i, true)
            else
                performWithDelay(
                    self,
                    function()
                        self:taskCellAnima(i, true)
                    end,
                    (i - 1) * 0.3
                )
            end
        end
        performWithDelay(self, func, count * 0.3)
    elseif self.m_nextStatus == TASK_STATUS.HIDE then
        local count = #self.m_taskNodeList
        for i = 1, count do
            if i == 1 then
                self:taskCellAnima(i, false)
            else
                performWithDelay(
                    self,
                    function()
                        self:taskCellAnima(i, false)
                    end,
                    (i - 1) * 0.3
                )
            end
        end
        performWithDelay(self, func, count * 0.3)
    else
        func()
    end
end

function QuestEntryNode:initView()
    --是否通过quest大厅，进入关卡
    if self.m_config ~= nil and self.m_config:isRunning() then
        self.m_IsQuestLogin = self.m_config.class.m_IsQuestLogin
        --获取任务信息
        local phase_idx = self.m_config:getPhaseIdx()
        self.m_taskData = self.m_config:getCurTaskInfo()
    end

    if not self.m_IsQuestLogin then
        self:runCsbAction("idle", true)
        self.m_packupState = 2
        self:updateEnrtyNode(2, true)
        self:updateIcon()
    else
        G_GetMgr(G_REF.FloatView):jumpEntryNode(ACTIVITY_REF.Quest)
        self:runCsbAction(
            "show",
            false,
            function()
                self:updateIcon()
            end
        )
        self:initTaskView()
        self:updateEnrtyNode(0, true)

        local mask = util_newMaskLayer()
        mask:setOpacity(0)
        gLobalViewManager:getViewLayer():addChild(mask, 9999)
        --1s后移除遮罩
        performWithDelay(
            self,
            function()
                mask:removeFromParent()
            end,
            0.5
        )
        --1s后 默认展示task任务
        if QUEST_CONFIGS.show_task_pop then
            performWithDelay(
                self,
                function()
                    G_GetMgr(ACTIVITY_REF.Quest):showEnterLayer()
                end,
                0.5
            )
        end
    end

    self:updateTime()
    schedule(
        self,
        function()
            if self.isClose then
                return
            end
            self:updateTime()
        end,
        1
    )
    self:updateView()
end

function QuestEntryNode:updateIcon()
    if not self.m_config then
        return
    end
    -- 收起状态
    if self.m_packupState == 2 then
        if not tolua.isnull(self.m_logoNode) then
            self.m_logoNode:setVisible(true)
        end
        if not tolua.isnull(self.m_saleNode) then
            self.m_saleNode:setVisible(false)
        end
        return
    end

    -- 打开状态
    if self.m_packupState == 0 then
        local is_trigger = false
        local sale_data = G_GetMgr(ACTIVITY_REF.QuestSale):getRunningData()
        if sale_data and not G_GetMgr(ACTIVITY_REF.Quest):isNewUserQuest() then
            if not tolua.isnull(self.m_saleNode) then
                is_trigger = true
                self.m_saleNode:setVisible(is_trigger)
            end
        end

        if not tolua.isnull(self.m_logoNode) then
            self.m_logoNode:setVisible(not is_trigger)
        end
    end
end

function QuestEntryNode:initSaleView()
    if tolua.isnull(self.m_saleNode) then
        return
    end
    local icon_sale = util_createFindView(QUEST_CODE_PATH.QuestLobbySale)
    icon_sale:runBuffEff()
    icon_sale:addTo(self.m_saleNode)
    icon_sale:setName("promotSaleView")
    icon_sale:setVisible(false)

    local icon_skip = util_createAnimation(QUEST_RES_PATH.QuestSkipIcon)
    icon_skip:runCsbAction("idle", true, nil, 60)
    icon_skip:addTo(self.m_saleNode)
    icon_skip:setName("skipSaleView")
    icon_skip:setVisible(false)

    local skip_sale = nil
    local hasSkipSale_PlanB = false
    self.m_isAlternateShowSale = false
    if self.m_config then
        skip_sale = self.m_config:getSkipSaleDate()
        hasSkipSale_PlanB = self.m_config:isHaveSkipSale_PlanB()
    end
    if skip_sale and skip_sale:getIsActive() then
        self.m_isAlternateShowSale = true
    else
        if hasSkipSale_PlanB then
            self.m_isAlternateShowSale = true
        end
    end
    if self.m_isAlternateShowSale then
        self:showSaleNode("skipSaleView")
    else
        self:showSaleNode("BoostPromot")
    end
    self:alternateShowSaleNode()
end

function QuestEntryNode:alternateShowSaleNode()
    if self.m_isAlternateShowSale then
        performWithDelay(
            self,
            function()
                if self.cur_sale  == "promotSaleView" then
                    self:showSaleNode("skipSaleView")
                else
                    self:showSaleNode("BoostPromot")
                end
                self:alternateShowSaleNode()
            end,
            5
        )
    end
end

function QuestEntryNode:showSaleView()
    if tolua.isnull(self.m_saleNode) then
        return
    end
    local skipNode = self.m_saleNode:getChildByName("skipSaleView")
    local promotNode = self.m_saleNode:getChildByName("promotSaleView")
    if promotNode then
        promotNode:setVisible(true)
        self.cur_sale = "promotSaleView"
    end
    if skipNode then 
        skipNode:setVisible(false)
    end
end

function QuestEntryNode:showSkipSale()
    if tolua.isnull(self.m_saleNode) then
        return
    end
    local skipNode = self.m_saleNode:getChildByName("skipSaleView")
    if skipNode then
        skipNode:setVisible(true)
        self.cur_sale = "skipSaleView"
    end
    local promotNode = self.m_saleNode:getChildByName("promotSaleView")
    if promotNode then
        promotNode:setVisible(false)
    end
end

function QuestEntryNode:showSaleNode(sale_name)
    if sale_name == "skipSaleView" then
        self:showSkipSale()
    elseif sale_name == "BoostPromot" then
        self:showSaleView()
    end
end

function QuestEntryNode:getTouchSaleNodeName()
    local node = self.m_saleRuningTable[self.m_runIndex]
    local strName = node:getName()
    return strName
end

function QuestEntryNode:removeBoostEffect()
    if self.m_boost then
        self.m_boost:setVisible(false)
    end
end

function QuestEntryNode:updateTime()
    if not self.m_config then
        self:closeUI()
        return
    end

    --活动结束时间
    local expireTime = self.m_config:getLeftTime()
    if expireTime <= 0 then
        self:closeUI()
        return
    end

    --活动剩余24小时，请求刷新数据
    if expireTime == self.m_config.p_questExtraPrize then
        self:onUpdateActivityStart()
    end

    self:updateIcon()
end

--初始化Task相关
function QuestEntryNode:initTaskView()
    if self.m_taskData == nil then
        return
    end

    local len = #self.m_taskData
    local posList = util_TypeSettingWidth(50, 15, len)
    for i = 1, len do
        local d = self.m_taskData[i]
        local cellNode = self:createTaskNode(d)
        if cellNode ~= nil then
            cellNode:setPositionY(posList[len - i + 1])
            if not tolua.isnull(self.node_task) then
                self.node_task:addChild(cellNode)
                self.m_taskNodeList[#self.m_taskNodeList + 1] = cellNode
            end
        end
    end
end

--刷新任务
function QuestEntryNode:updateView()
    if self.m_config == nil then
        return
    end
    self.m_taskData = self.m_config:getCurTaskInfo()
    if self.m_taskData == nil then
        return
    end

    local rateVarList = {}
    local len = #self.m_taskData
    for i = 1, len do
        local taskNode = self.m_taskNodeList[i]
        local d = self.m_taskData[i]
        if taskNode ~= nil then
            taskNode:updateView(d)
        end
        rateVarList[#rateVarList + 1] = d.p_process[1] * 100 / d.p_params[1]
    end
    local rateVar = 0
    local maxVar = 0
    local taskCount = #rateVarList
    for i = 1, taskCount do
        maxVar = maxVar + math.min(rateVarList[i], 100)
    end
    if taskCount > 0 then
        rateVar = math.floor(maxVar / taskCount + 0.0001)
    end

    if not tolua.isnull(self.bar_var) then
        self.bar_var:setPercent(rateVar)
    end

    if not tolua.isnull(self.m_lb_bar) then
        self.m_lb_bar:setString(rateVar .. "%")
    end
end

--创建task node
function QuestEntryNode:createTaskNode(data)
    if data == nil then
        return nil
    end
    local propNode = util_createFindView(QUEST_CODE_PATH.QuestTaskProgress, data)
    return propNode
end

--显示任务完成界面
function QuestEntryNode:showTaskDoneView()
    if not self.m_IsQuestLogin then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
        return
    end
    self:updateView()
    --判断当前阶段是否完成
    local isShowSkipView = G_GetMgr(ACTIVITY_REF.Quest):isShowSkipSaleView()
    if isShowSkipView then
        G_GetMgr(ACTIVITY_REF.Quest):showSkipSaleView(true, true)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
    end
end

function QuestEntryNode:showTaskDoneViewAfterBuy()
    if not self.m_IsQuestLogin then
        return
    end
    self:updateView()
    --判断当前阶段是否完成
    local isFinish = G_GetMgr(ACTIVITY_REF.Quest):isTaskDone()
    if isFinish then
        G_GetMgr(ACTIVITY_REF.Quest):showTaskDoneView()
    end
end

--收缩/展示 (收起按钮)
function QuestEntryNode:retractLayer()
    if not self.m_packupAniEnd then
        return
    end
    if self.m_packupState == 0 then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickPackUp()
    elseif self.m_packupState == 2 then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickPutDown()
    end
end

function QuestEntryNode:clickPackUp()
    self:resetTaskStatus()
    self.m_packupState = 1
    self:runCsbAction(
        "over",
        false,
        function()
            self.m_packupAniEnd = true
            self.m_packupState = 2
            self:runCsbAction("idle", true)
            self:updateIcon()
        end,
        60
    )
    self:updateEnrtyNode(2, false)
end

function QuestEntryNode:clickPutDown()
    if self._bForbidUnflod then
        return
    end
    self.m_isResetTaskStatus = nil
    self.m_packupState = 1
    self:runCsbAction(
        "show",
        false,
        function()
            self.m_packupAniEnd = true
            self.m_packupState = 0
            self:updateIcon()
        end,
        60
    )
    self:updateEnrtyNode(0, false)
end

function QuestEntryNode:onUpdateActivityStart()
    --请求更新难度数据
    gLobalSendDataManager:getNetWorkFeature():sendActivityConfig()
end

function QuestEntryNode:onUpdateActivityEnd()
    gLobalNoticManager:postNotification(ViewEventType.UPDATE_SLIDEANDHALL_FINISH)
end

function QuestEntryNode:onEnter()
    self:initView()
    self:initSaleView()
    --注册通知
    self:registerHandler()
    if not self.m_IsQuestLogin then
        return
    end

    ---- 测试quest结算面板
    --if DEBUG == 2 then
    --    G_GetMgr(ACTIVITY_REF.Quest):showTaskDoneView()
    --end
end

function QuestEntryNode:registerHandler()
    --注册通知 spin之后通知
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_DONE_ADDEFF, true)
        end,
        ViewEventType.CHECK_QUEST_WITH_SPINRESULT
    )

    --log打点
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.m_IsQuestLogin then
                -- 每次spin赢钱coins
                if params and params[1] == true then
                    local spinData = params[2]
                    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
                    if questConfig then
                        questConfig:parseDataFromSpinResult(spinData)
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    --更新活动配置成功
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:onUpdateActivityEnd()
        end,
        ViewEventType.UPDATE_ACTIVITY_CONFIG_FINISH
    )

    --任务完成弹版
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showTaskDoneView()
        end,
        ViewEventType.NOTIFY_QUEST_DONE_SHOW
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showTaskDoneViewAfterBuy()
        end,
        ViewEventType.NOTIFY_QUEST_DONE_VIEW_AFTER_BUY
    )

    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeTaskStatus()
        end,
        ViewEventType.NOTIFY_QUEST_TASK_CHOICE_VIEW_CLOSE
    )

    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeTaskStatus()
        end,
        ViewEventType.NOTIFY_QUEST_TASK_CELL_CHANGE
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:showTaskDoneView()
        end,
        ViewEventType.NOTIFY_QUEST_SKIP_TASK
    )

    -- 监听强制收回展开状态的消息
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.name == ACTIVITY_REF.Quest then
                -- 如果当前是自己触发的强制收回的话
                self.m_bPauseFunc = true
            else
                if self.m_bOpenProgress then
                    -- 直接调用缩小动画
                    self:clickPackUp()
                end
            end
        end,
        ViewEventType.NOTIFY_FRAME_LAYER_FORCE_HIDE
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            -- 监听悬浮条移动到左侧后应该做的动画
            if not self.m_bPauseFunc then
                if self.m_updateEntryNodeFunc then
                    self.m_updateEntryNodeFunc()
                    self.m_updateEntryNodeFunc = nil
                end
            else
                self.m_bPauseFunc = nil
            end
        end,
        ViewEventType.NOTIFY_FRAME_LAYER_MOVEIN
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- 监听悬浮条移动到左侧后应该做的动画
            if params.name == "QuestSkip" then
                local skip_sale
                local hasSkipSale_PlanB = false
                if self.m_config then
                    skip_sale = self.m_config:getSkipSaleDate()
                    hasSkipSale_PlanB = self.m_config:isHaveSkipSale_PlanB()
                end
                if skip_sale and skip_sale:getIsActive() then
                    self:showSaleNode("skipSaleView")
                else
                    if hasSkipSale_PlanB then
                        self:showSaleNode("skipSaleView")
                    else
                        self:showSaleNode("BoostPromot")
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH
    )
end

function QuestEntryNode:touchBtnBet()
    if self.m_packupState == 0 then
        if self.cur_sale == "promotSaleView" then
            -- 展开状态
            G_GetMgr(ACTIVITY_REF.QuestSale):showMainLayer()
        elseif self.cur_sale == "skipSaleView" then
            G_GetMgr(ACTIVITY_REF.Quest):showSkipSaleView()
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TOUCH_SALE_NODE, self.cur_sale)
        end
    else
        if not self.m_IsQuestLogin then
            if self.m_config ~= nil then
                self.m_config.class.m_IsQuestLogin = true
                self.m_config.p_isLevelEnterQuest = true
            end
            gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("gameToQuestIcon")
            release_print("QuestEntryNode back to lobby!!!")
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        else
            self:retractLayer()
        end
    end
end

function QuestEntryNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "btn_bet" then
        self:touchBtnBet()
    elseif name == "btn_packup" then
        --收起
        self:retractLayer()
    end
end

--倒计时结束，收起关闭
function QuestEntryNode:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true

    gLobalNoticManager:removeAllObservers(self)
    self:setVisible(false)

    gLobalActivityManager:removeActivityEntryNode(ACTIVITY_REF.Quest)
end

-- 返回entry 大小
function QuestEntryNode:getPanelSize()
    local size = cc.size(0, 0)
    if not tolua.isnull(self.m_panelSmall) then
        size = self.m_panelSmall:getContentSize()
    end
    local size_launch = cc.size(0, 0)
    if not tolua.isnull(self.m_panelNormal) then
        size_launch = self.m_panelNormal:getContentSize()
    end
    return {widht = size.width, height = size.height, launchHeight = size_launch.height, scale = self.m_fScale}
end

function QuestEntryNode:updateEnrtyNode(status, init)
    if status == 2 and init == true then
        -- 什么都不做
        self.m_bOpenProgress = false
    elseif status == 2 and init == false then -- 合上
        self.m_bOpenProgress = false
        self:setNodeScale(1)
        gLobalActivityManager:resetEntryNodeInfo(ACTIVITY_REF.Quest)
    elseif status == 0 or init then -- 展开
        self.m_bOpenProgress = true
        self:setNodeScale(self.m_fScale)
        gLobalActivityManager:showEntryNodeInfo(ACTIVITY_REF.Quest)
    end
end

function QuestEntryNode:getEntryNodeOpenState()
    -- 获取当前进度条是否展开
    return self.m_bOpenProgress
end

function QuestEntryNode:setNodeScale(scale)
    self.m_csbNode:setScale(scale)
end

-- 监测 有小红点或者活动进度满了
function QuestEntryNode:checkHadRedOrProgMax()
    local bHadRed = false
    local bProgMax = false
    if self.bar_var then
        bProgMax = self.bar_var:getPercent() >= 100
    end
    return {bHadRed, bProgMax}
end
-- 禁止 该入口 支持可展开状态
function QuestEntryNode:forbidEntryUnflodState(_bForbidUnflod)
    self._bForbidUnflod = _bForbidUnflod
end

return QuestEntryNode
