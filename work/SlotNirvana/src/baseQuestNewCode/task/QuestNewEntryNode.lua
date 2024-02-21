-- Created by jfwang on 2019-05-21.
-- Activity_QuestNew入口
--
local QuestNewEntryNode = class("QuestNewEntryNode", util_require("base.BaseView"))

local TASK_STATUS = {
    HIDE = 1,
    SHOW = 2,
    DOING = 3
}

function QuestNewEntryNode:getCsbNodePath()
    return QUESTNEW_RES_PATH.QuestNewEntryNode
end

function QuestNewEntryNode:initUI(data)
    self:createCsbNode(self:getCsbNodePath())

    self.m_fScale = 1.2
    --收起按钮
    self.m_packupAniEnd = true
    self.m_packupState = 0

    self.m_IsQuestLogin = false
    self.m_taskData = {}
    self.m_taskNodeList = {}

    self.m_lockNode = self:findChild("Sprite_lock")
    if self.m_lockNode then
        self.m_lockNode:setVisible(false)
    end

    self.m_node_sp_1 = self:findChild("node_sp_1")
    self.m_node_sp_3 = self:findChild("node_sp_3")
    self.m_node_sp_1:setVisible(true)
    self.m_node_sp_3:setVisible(false)
    local bar_var = self:findChild("bar_var")
    local m_lb_bar = self:findChild("m_lb_bar")
    if bar_var then
        bar_var:setPercent(0)
    end
    if m_lb_bar then
        m_lb_bar:setString("0%")
    end
    self.m_taskStatus = TASK_STATUS.HIDE
    self.m_nextStatus = nil
    self.m_isResetTaskStatus = nil

    self.m_bOpenProgress = false
    self.activityData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
end

function QuestNewEntryNode:initView()
    --是否通过quest大厅，进入关卡
    if self.activityData ~= nil and self.activityData:isRunning() then
        self.m_IsQuestLogin = self.activityData:isEnterGameFromQuest()
        --获取任务信息
        self.m_taskData = self.activityData:getEnterGameTaskInfo()
    end

    if not self.m_IsQuestLogin then
        self.m_isShowIcon = true
        self:updateIcon()
        self:runCsbAction("idle", true)
        self.m_packupState = 2
        self:updateEnrtyNode(2, true)
    else
        self:runCsbAction(
            "show",
            false,
            function()
                self.m_isShowIcon = false
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
        performWithDelay(
            self,
            function()
                self:changeTaskStatus()
            end,
            1
        )
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


--切换任务状态
function QuestNewEntryNode:changeTaskStatus()
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
function QuestNewEntryNode:resetTaskStatus()
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

function QuestNewEntryNode:taskCellAnima(index, isShow)
    if self.m_isResetTaskStatus then
        return
    end
    local taskNode = self.m_taskNodeList[index]
    if taskNode ~= nil then
        if isShow then
            taskNode:showTipsView(nil, true)
            self:hideLater()
        else
            taskNode:hideTipsView()
        end
    end
end

function QuestNewEntryNode:hideLater()
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
function QuestNewEntryNode:runChangeTaskAnima(func)
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



function QuestNewEntryNode:updateIcon()
    if self.activityData then
        if self.m_isShowIcon then
            self.m_node_sp_1:setVisible(true)
            self.m_node_sp_3:setVisible(false)
            --删除添加的特效消息
            if self.m_bAddEffect then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_REMOVE_PROMOT_EFFECT)
                self.m_bAddEffect = false
            end
        else
            self.m_node_sp_1:setVisible(false)
            local buffExpire = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPY_QUEST_FAST)
            if buffExpire > 0 then
                self.m_node_sp_3:setVisible(true)
                --发送progress添加特效消息
                if not self.m_bAddEffect then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_ADD_PROMOT_EFFECT)
                    self.m_bAddEffect = true
                end
            else
                self.m_node_sp_3:setVisible(true)
                --删除添加的特效消息
                if self.m_bAddEffect then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_REMOVE_PROMOT_EFFECT)
                    self.m_bAddEffect = false
                end
            end
        end
    end
end

function QuestNewEntryNode:initSaleView()
    self.m_saleNode = self:findChild("node_sp_3")

    local icon_sale = util_createFindView(QUESTNEW_CODE_PATH.QuestNewLobbySaleNode)
    icon_sale:addTo(self.m_saleNode)
    icon_sale:setName("promotSaleView")
    icon_sale:setVisible(false)
    self.m_icon_sale = icon_sale

    self:showSaleNode("BoostPromot")
end

function QuestNewEntryNode:showSaleView()
    local skipNode = self.m_saleNode:getChildByName("skipSaleView")
    local promotNode = self.m_saleNode:getChildByName("promotSaleView")
    if skipNode and skipNode:isVisible() then
        promotNode:setVisible(false)
    else
        promotNode:setVisible(true)
        self.cur_sale = "promotSaleView"
    end
end

function QuestNewEntryNode:showSkipSale()
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

function QuestNewEntryNode:showSaleNode(sale_name)
    if sale_name == "skipSaleView" then
        self:showSkipSale()
    elseif sale_name == "BoostPromot" then
        self:showSaleView()
    end
end

function QuestNewEntryNode:getTouchSaleNodeName()
    local node = self.m_saleRuningTable[self.m_runIndex]
    local strName = node:getName()
    return strName
end

function QuestNewEntryNode:removeBoostEffect()
    if self.m_boost then
        self.m_boost:setVisible(false)
    end
end

function QuestNewEntryNode:updateTime()
    if not self.activityData then
        self:closeUI()
        return
    end

    --活动结束时间
    local expireTime = self.activityData:getLeftTime()
    if expireTime <= 0 then
        self:closeUI()
        return
    end

    --活动剩余24小时，请求刷新数据
    if expireTime == self.activityData.p_questExtraPrize then
        self:onUpdateActivityStart()
    end

    self:updateIcon()
end

--初始化Task相关
function QuestNewEntryNode:initTaskView()
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
            local node_task = self:findChild("node_task")
            if node_task then
                node_task:addChild(cellNode)
                self.m_taskNodeList[#self.m_taskNodeList + 1] = cellNode
            end
        end
    end
end

--刷新任务
function QuestNewEntryNode:updateView()
    if self.activityData == nil then
        return
    end
    self.m_taskData = self.activityData:getEnterGameTaskInfo()
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

    local bar_var = self:findChild("bar_var")
    local m_lb_bar = self:findChild("m_lb_bar")
    if bar_var then
        bar_var:setPercent(rateVar)
    end
    if m_lb_bar then
        m_lb_bar:setString(rateVar .. "%")
    end
end

--创建task node
function QuestNewEntryNode:createTaskNode(data)
    if data == nil then
        return nil
    end
    local propNode = util_createFindView(QUESTNEW_CODE_PATH.QuestNewTaskProgress, data)
    return propNode
end

--显示任务完成界面
function QuestNewEntryNode:showTaskDoneView()
    if not self.m_IsQuestLogin then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
        return
    end
    self:updateView()
    --判断当前阶段是否完成  需要弹出完成一个任务弹窗  需要弹窗全部任务完成弹窗
    local willShowOneTaskTip , willShowAllTaskTip = G_GetMgr(ACTIVITY_REF.QuestNew):isCurrentStageTaskTipState()
    if willShowOneTaskTip or willShowAllTaskTip then
        -- csc 将这个弹出改到 machineControl 中去实现
        G_GetMgr(ACTIVITY_REF.QuestNew):setIsShowTaskDoneTip(true,willShowOneTaskTip and 1 or 2)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
    end
end


--收缩/展示 (收起按钮)
function QuestNewEntryNode:retractLayer()
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

function QuestNewEntryNode:clickPackUp()
    self:resetTaskStatus()
    self.m_packupState = 1
    self:runCsbAction(
        "over",
        false,
        function()
            self.m_packupAniEnd = true
            self.m_packupState = 2
            self:runCsbAction("idle", true)
            self.m_isShowIcon = true
            self:updateIcon()
        end,
        60
    )
    self:updateEnrtyNode(2, false)
end

function QuestNewEntryNode:clickPutDown()
    if self._bForbidUnflod then
        return
    end
    
    self.m_isResetTaskStatus = nil
    self.m_packupState = 1
    self.m_isShowIcon = false
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

function QuestNewEntryNode:onUpdateActivityStart()
    --请求更新难度数据
    gLobalSendDataManager:getNetWorkFeature():sendActivityConfig()
end

function QuestNewEntryNode:onUpdateActivityEnd()
    gLobalNoticManager:postNotification(ViewEventType.UPDATE_SLIDEANDHALL_FINISH)
end

function QuestNewEntryNode:onEnter()
    self:initView()
    self:initSaleView()
    --注册通知
    self:registerHandler()
    if not self.m_IsQuestLogin then
        return
    end

    ---- 测试quest结算面板
    --if DEBUG == 2 then
    --    G_GetMgr(ACTIVITY_REF.QuestNew):showTaskDoneView()
    --end
end

function QuestNewEntryNode:registerHandler()
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
                    local questActivity = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
                    if questActivity then
                        questActivity:parseDataFromSpinResult(spinData)
                        if self.m_icon_sale then
                            self.m_icon_sale:refreshLeftSpins()
                        end
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
            if params.name == ACTIVITY_REF.QuestNew then
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
            if params.name == "QuestNewSkip" then
                local skip_sale
                if self.activityData then
                    skip_sale = self.activityData:getSkipSaleDate()
                end
                if skip_sale and skip_sale:getIsActive() then
                    self:showSaleNode("skipSaleView")
                else
                    self:showSaleNode("BoostPromot")
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH
    )
end

function QuestNewEntryNode:touchBtnBet()
    if self.m_packupState == 0 then
        if self.cur_sale == "promotSaleView" then
            -- 展开状态
            G_GetMgr(ACTIVITY_REF.QuestNewSale):showMainLayer()
        elseif self.cur_sale == "skipSaleView" then
            G_GetMgr(ACTIVITY_REF.QuestNew):showSkipSaleView()
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TOUCH_SALE_NODE, self.cur_sale)
        end
    else
        if not self.m_IsQuestLogin then
            if self.activityData ~= nil then
                G_GetMgr(ACTIVITY_REF.QuestNew):setEnterGameFromQuest(true)
                G_GetMgr(ACTIVITY_REF.QuestNew):setEnterQuestFromGame(true)
            end
            --gLobalSendDataManager:getLogQuestNewActivity():sendQuestNewEntrySite("gameToQuestNewIcon")
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        else
            self:retractLayer()
        end
    end
end

function QuestNewEntryNode:clickFunc(sender)
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
function QuestNewEntryNode:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true

    gLobalNoticManager:removeAllObservers(self)
    self:setVisible(false)

    gLobalActivityManager:removeActivityEntryNode(ACTIVITY_REF.QuestNew)
end

-- 返回entry 大小
function QuestNewEntryNode:getPanelSize()
    -- 暂时这么写 后期修改成csb panel 直接读取
    local size = self:findChild("Node_PanelSize"):getContentSize()
    local size_launch = self:findChild("Node_PanelSize_launch"):getContentSize()
    return {widht = size.width, height = size.height, launchHeight = size_launch.height, scale = self.m_fScale}
end

function QuestNewEntryNode:updateEnrtyNode(status, init)
    if status == 2 and init == true then
        -- 什么都不做
        self.m_bOpenProgress = false
    elseif status == 2 and init == false then -- 合上
        self.m_bOpenProgress = false
        self:setNodeScale(1)
        gLobalActivityManager:resetEntryNodeInfo(ACTIVITY_REF.QuestNew)
    elseif status == 0 or init then -- 展开
        self.m_bOpenProgress = true
        self:setNodeScale(self.m_fScale)
        gLobalActivityManager:showEntryNodeInfo(ACTIVITY_REF.QuestNew)
    end
end

function QuestNewEntryNode:getEntryNodeOpenState()
    -- 获取当前进度条是否展开
    return self.m_bOpenProgress
end

function QuestNewEntryNode:setNodeScale(scale)
    self.m_csbNode:setScale(scale)
end

-- 监测 有小红点或者活动进度满了
function QuestNewEntryNode:checkHadRedOrProgMax()
    local bHadRed = false
    local bProgMax = false
    return {bHadRed, bProgMax}
end
-- 禁止 该入口 支持可展开状态
function QuestNewEntryNode:forbidEntryUnflodState(_bForbidUnflod)
    self._bForbidUnflod = _bForbidUnflod
end

return QuestNewEntryNode
