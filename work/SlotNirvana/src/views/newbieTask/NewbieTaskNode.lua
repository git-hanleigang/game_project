local NewbieTaskNode = class("NewbieTaskNode", util_require("base.BaseView"))
function NewbieTaskNode:initUI(data)
    self:createCsbNode("GuideNewUser/NewTaskGuideNode.csb")
    self.m_baseNode = self:findChild("node_base")
    self.m_baseNode:setPosition(-250, 0)
    local touch = self:findChild("touch")
    self:addClick(touch)
    touch:setSwallowTouches(false)
    self:initProgress()
    touch:setSwallowTouches(false)
    self.m_bubble = util_createView("views.newbieTask.GuidePopNode")
    self:addChild(self.m_bubble)
    self.m_bubble:showIdle(1)
    self.m_bubble:setVisible(false)
    globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.noobTaskFinish1, self)
    globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.noobTaskFinish2, self)
    globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.noobTaskFinish3, self)
    self:initView()
    schedule(
        self,
        function()
            if self.m_waitChangeNext then
                return
            end
            if self.m_isPauseAct then
                return
            end
            if self.m_intravelPool == 0 then
                return
            end
            if self.m_currentPool ~= self.m_targetPool then
                self.m_currentPool = self.m_currentPool + self.m_intravelPool
                if self.m_currentPool >= self.m_targetPool then
                    self.m_currentPool = self.m_targetPool
                    self.m_intravelPool = 0
                    self:checkTaskHalf()
                end
                self:updateBar(self.m_currentPool)
            end
            self:checkNexttask()
        end,
        0.02
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, data)
            if self.showFirstGuide then
                self:showFirstGuide()
            end
        end,
        ViewEventType.NOTIFY_CHANGE_NEWTASK_ZORDER
    )
end

function NewbieTaskNode:initProgress()
    -- 创建进度条
    local img = util_createSprite("GuideNewUser/ui/vectoring_jindu.png")
    if not img then
        release_print("initProgress = GuideNewUser/ui/vectoring_jindu.png")
        return
    end
    local sp_bar = self:findChild("sp_bar")
    self.m_bar_pool = cc.ProgressTimer:create(img)
    self.m_bar_pool:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    self.m_bar_pool:setPercentage(0)
    self.m_bar_pool:setRotation(180)
    self.m_bar_pool:setPosition(sp_bar:getPosition())
    sp_bar:getParent():addChild(self.m_bar_pool, 1)
    sp_bar:setVisible(false)
end

--初始化
function NewbieTaskNode:initView()
    self.m_data = globalNewbieTaskManager:getCurrentTaskData()
    if not self.m_data then
        self:removeFromParent()
        return
    end

    self:initCashMan()

    self.m_coinsEffect = self:findChild("Particle_1")
    self.m_lb_coins = self:findChild("m_lb_coins")
    local node_tips = self:findChild("node_tips")
    self.m_taskTips = util_createView("views.newbieTask.GuideNewTaskTitle")
    node_tips:addChild(self.m_taskTips)
    local Panel_2 = self.m_taskTips:findChild("Panel_2")
    if Panel_2 then
        Panel_2:setSwallowTouches(false)
    end
    self.m_lastData = self.m_data
    self:updateUI()
    if self.m_data.p_targetType == NewbieTaskType.spin_count then
        self:runCsbAction("idle")
    elseif self.m_data.p_targetType == NewbieTaskType.reach_level then
        self:runCsbAction("idle2")
    end
end

function NewbieTaskNode:initCashMan()
    self.m_nodeNpc = self:findChild("node_spine")
    self.m_spineNpc = util_spineCreate("GuideNewUser/Other/xiaoqiche", false, true, 1)
    self.m_nodeNpc:addChild(self.m_spineNpc)
    util_spinePlay(self.m_spineNpc, "idle", true)
end

--下一个任务
function NewbieTaskNode:updateNext()
    self.m_lastData = self.m_data
    self.m_data = globalNewbieTaskManager:getCurrentTaskData()
    if not self.m_data then
        self:showOver()
        return
    end
    --改变任务数据
    local changeAnimTime = self:changeTask()
    --是否延时刷新
    if changeAnimTime and changeAnimTime > 0 then
        performWithDelay(
            self,
            function()
                self:updateUI()
            end,
            changeAnimTime
        )
    else
        self:updateUI()
    end
end
--更新任务数据暂停刷进度
function NewbieTaskNode:updateUI()
    self.m_isPauseAct = nil
    self.m_currentPool = self.m_data:getPercent()
    self.m_targetPool = self.m_data:getPercent()
    self.m_intravelPool = 0
    self:updateBar(self.m_currentPool)
    if self.m_taskTips then
        self.m_taskTips:updateTitle(self.m_data.p_description[1], self.m_data.p_rewardCoins)
    end
    self:updateCoins()
end
function NewbieTaskNode:updateCoins()
    -- if self.m_lb_coins and self.m_data.p_rewardCoins then
    --     local coinsOri = math.ceil(self.m_data.p_rewardCoins/1000000)
    --     local coinsM = self.m_data.p_rewardCoins/1000000
    --     if coinsM<1 then
    --         local coinsK = self.m_data.p_rewardCoins/1000
    --         local strCoins = string.format("%0.1fKCOINS",coinsK)
    --         self.m_lb_coins:setString(strCoins)
    --     else
    --         local strCoins = string.format("%0.1fM COINS",coinsM)
    --         self.m_lb_coins:setString(strCoins)
    --     end
    -- end
    if self.m_lb_coins and self.m_data.p_rewardCoins then
        local strCoins =  string.format("%.1fM COINS", (self.m_data.p_rewardCoins / 1000000))
        self.m_lb_coins:setString(strCoins)
    end
end
--设置速度
function NewbieTaskNode:setTargetValue(data)
    self.m_targetPool = data
    self.m_intravelPool = 0.5

    self:checkReachLevelCompleted()
end
--切换任务动画
function NewbieTaskNode:changeTask()
    if not self.m_lastData or not self.m_data then
        return
    end
    local changeAnimTime = 0
    local animName = nil
    if self.m_lastData.p_targetType == NewbieTaskType.spin_count and self.m_data.p_targetType == NewbieTaskType.reach_level then
        animName = "switch1"
    elseif self.m_lastData.p_targetType == NewbieTaskType.reach_level and self.m_data.p_targetType == NewbieTaskType.spin_count then
        animName = "switch2"
    elseif self.m_lastData.p_targetType == NewbieTaskType.reach_level and self.m_data.p_targetType == NewbieTaskType.reach_level then
        animName = "switch3"
        --关卡切换关卡特殊处理
        local m_lb_next = self:findChild("m_lb_next")
        if m_lb_next then
            m_lb_next:setString(self.m_data.p_targetValue)
        end
        changeAnimTime = 0.3
    end
    if animName then
        self:runCsbAction(
            animName,
            false,
            function()
                if self.m_taskTips then
                    self.m_taskTips:autoPop(true)
                end
            end,
            60
        )
        if self.m_coinsEffect then
            performWithDelay(
                self,
                function()
                    self.m_coinsEffect:resetSystem()
                end,
                0.25
            )
        end
    end
end

function NewbieTaskNode:updateBar(pool)
    if self.m_isPauseAct then
        return
    end
    if self.m_bar_pool then
        self.m_bar_pool:setPercentage(pool)
    end
    if self.m_data.p_targetType == NewbieTaskType.spin_count then
        local m_lb_count = self:findChild("m_lb_count")
        if m_lb_count then
            m_lb_count:setString(self.m_data.m_currentValue .. "/" .. self.m_data.p_targetValue)
        end
    elseif self.m_data.p_targetType == NewbieTaskType.reach_level then
        local m_lb_num = self:findChild("m_lb_num")
        if m_lb_num then
            m_lb_num:setString(self.m_data.p_targetValue)
        end
    end
end

function NewbieTaskNode:playEffect()
end

function NewbieTaskNode:checkNexttask()
    local taskData = globalNewbieTaskManager:getCurrentTaskData()
    if taskData and taskData:checkUnclaimed() then
        if self.m_currentPool >= 100 then
            self:updateNextTask()
        end
    end
end

function NewbieTaskNode:checkFinishGuide()
    if self.m_data then
        if self.m_data.p_id == 1 then
            -- 引导打点：新手任务-2.任务完成
            if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.noobTaskFinish1) then
                gLobalSendDataManager:getLogGuide():sendGuideLog(2, 2)
            end
            globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskFinish1, true)
        elseif self.m_data.p_id == 2 then
            -- 引导打点：新手任务-2.任务完成
            if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.noobTaskFinish2) then
                gLobalSendDataManager:getLogGuide():sendGuideLog(2, 2)
            end
            globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskFinish2, true)
        elseif self.m_data.p_id == 3 then
            -- 引导打点：新手任务-2.任务完成
            if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.noobTaskFinish3) then
                gLobalSendDataManager:getLogGuide():sendGuideLog(2, 2)
            end
            globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskFinish3, true)
        end
    end
end

function NewbieTaskNode:updateNextTask()
    if self.m_waitLevelUpOver then
        self.m_waitChangeNext = true
    end
    if self.m_waitChangeNext then
        return
    end
    if self.m_isPauseAct then
        return
    end
    self.m_isPauseAct = true
    if self.checkFinishGuide then
        self:checkFinishGuide()
    end
    globalNewbieTaskManager:recvRewardCoins(
        function()
            if tolua.isnull(self) then
                return
            end

            -- 修改飞金币的动画展示
            self.m_taskTips:showTaskCompletedFlyCoins(self.m_data.p_rewardCoins)

            -- local sp_coins = self:findChild("sp_coins")
            -- local wordPos = sp_coins:getParent():convertToWorldSpace(cc.p(sp_coins:getPosition()))
            -- local endPos = globalData.flyCoinsEndPos
            -- local baseCoins = globalData.topUICoinCount
            -- local  rewardCoins = self.m_data.p_rewardCoins
            performWithDelay(self, handler(self, self.updateNext), 2)
            -- gLobalViewManager:pubPlayFlyCoin(wordPos,endPos,baseCoins,rewardCoins,function()
            -- end,false,nil,nil,nil,nil,true)
        end
    )
end

function NewbieTaskNode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, data)
        end,
        ViewEventType.NOTIFY_NEWBIE_TASK_TIPS
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.setTargetValue then
                self:setTargetValue(params)
            end
        end,
        ViewEventType.NOTIFY_NEWBIE_TASK_UPDATE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self)
            if self.playEffect then
                self:playEffect()
            end
        end,
        ViewEventType.NOTIFY_NEWBIE_TASK_REWARD
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.resetLocalZorder then
                self:resetLocalZorder()
            end
        end,
        ViewEventType.NOTIFY_GAMEEFFECT_OVER
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.resetLocalZorder then
                self:resetLocalZorder()
            end
        end,
        ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE
    )

    performWithDelay(self, handler(self, self.showEnter), 0.45)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.levelUpStatus then
                self:levelUpStatus(params)
            end
        end,
        ViewEventType.NOTIFY_UPLEVEL_STATUS
    )
end

function NewbieTaskNode:levelUpStatus(data)
    if not data or not data.type then
        return
    end
    if data.type == 1 then
        self.m_waitLevelUpOver = true
    else
        self.m_waitLevelUpOver = nil
        if self.m_waitChangeNext then
            self.m_waitChangeNext = nil
            self:updateNextTask()
        end
    end
end
--TODO-NEWGUIDE
function NewbieTaskNode:showFirstGuide()
    if not self.m_lastPos then
        self:showTips()
        self.m_lastPos = cc.p(self:getPosition())
        self.m_lastNode = self:getParent()
        self.m_lastZorder = self:getLocalZOrder()
        local wordPos = self.m_lastNode:convertToWorldSpace(self.m_lastPos)
        util_changeNodeParent(gLobalViewManager:getViewLayer(), self, ViewZorder.ZORDER_GUIDE + 1)
        self:setPosition(wordPos)
        self:setScale(math.min(self:getUIScalePro(), 1))
    end
end
--TODO-NEWGUIDE
function NewbieTaskNode:resetLocalZorder()
    if self.m_lastPos then
        util_changeNodeParent(self.m_lastNode, self, self.m_lastZorder)
        self:setPosition(self.m_lastPos)
        self.m_lastPos = nil
    end
end

function NewbieTaskNode:showTips(data)
    local delayTime = 1
    self:pauseForIndex(0)
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("Sounds/guide_move_pop.mp3")
            self:runCsbAction("start")
            self.m_bubble:setVisible(true)
            util_setCascadeOpacityEnabledRescursion(self.m_bubble, true)
            self.m_bubble:setOpacity(0)
            self.m_bubble:runAction(cc.FadeTo:create(0.5, 255))
            self.m_bubble:setPosition(50, 170)
            performWithDelay(
                self,
                function()
                    self.m_bubble:runAction(cc.FadeTo:create(0.5, 0))
                end,
                3
            )
            performWithDelay(
                self,
                function()
                    self:clickTitle(true)
                end,
                0.5
            )
        end,
        delayTime
    )
end

function NewbieTaskNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function NewbieTaskNode:clickTitle(isAuto)
    if not self.m_taskTips then
        return
    end
    self.m_taskTips:autoPop(isAuto)
end

function NewbieTaskNode:clickFunc(sender)
    if self.m_click then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "touch" then
        self:clickTitle(true)
    end
end

function NewbieTaskNode:showEnter()
    if self.m_isEnter then
        return
    end
    self.m_isEnter = true
    self.m_baseNode:setPosition(-250, 0)
    self.m_baseNode:runAction(cc.EaseBackOut:create(cc.MoveTo:create(0.58, cc.p(20, 0))))
    performWithDelay(
        self,
        function()
            self:clickTitle(true)
            self:checkNexttask()
        end,
        0.58
    )
end

function NewbieTaskNode:showOver()
    if self.m_isClose then
        return
    end
    self.m_isClose = true
    self.m_baseNode:setPosition(20, 0)
    self.m_baseNode:runAction(cc.EaseBackIn:create(cc.MoveTo:create(0.58, cc.p(-250, 0))))
    performWithDelay(
        self,
        function()
            self:removeFromParent()
            if globalNoviceGuideManager:getNewBieTeskReachLevelFlag() then
                globalNoviceGuideManager:setNewBieTeskReachLevelFlag(false)
                -- 弹出新手quest 弹板
                gLobalViewManager:removeLoadingAnima()
                local view =
                    G_GetMgr(ACTIVITY_REF.Quest):showOpenLayer(
                    function()
                        --添加回调 为了触发回调里恢复轮盘
                    end
                )
                if not view then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
                    -- machineController 里 协程暂停了, 玩家没有quest开启弹板应该恢复协程
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                end
            end
        end,
        0.58
    )
end

-- csc 2021-11-04 新手期5.0 检测用户当前任务进度是否过半
function NewbieTaskNode:checkTaskHalf()
    if self.m_data.p_targetType == NewbieTaskType.spin_count then
        -- csc 2021-11-04 新手期 5.0 判断当前任务是否过半
        if tonumber(self.m_data.m_currentValue) == tonumber(self.m_data.p_targetValue / 2) then
            self.m_taskTips:showTaskHalfAction()
        end
    elseif self.m_data.p_targetType == NewbieTaskType.reach_level then
        -- csc 2021-11-04 新手期 5.0 当用户4级的时候要提示任务过半，只显示一次
        if globalData.userRunData.levelNum == 4 then
            local reachLevelHalfTips = gLobalDataManager:getBoolByField("newUserTask_ReachLevelHalfTips", false)
            if not reachLevelHalfTips then
                self.m_taskTips:showTaskHalfAction()
                gLobalDataManager:setBoolByField("newUserTask_ReachLevelHalfTips", true)
            end
        end
    end
end

function NewbieTaskNode:checkReachLevelCompleted()
    if self.m_data.p_targetType == NewbieTaskType.reach_level and self.m_targetPool == 100 then
        if not globalNoviceGuideManager:getNewBieTeskReachLevelFlag() then
            globalNoviceGuideManager:setNewBieTeskReachLevelFlag(true)
        end
    end
end
return NewbieTaskNode
