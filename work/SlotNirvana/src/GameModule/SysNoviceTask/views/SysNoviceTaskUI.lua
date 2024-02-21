--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-06 14:16:34
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-06 14:16:50
FilePath: /SlotNirvana/src/GameModule/SysNoviceTask/views/SysNoviceTaskUI.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SysNoviceTaskUI = class("SysNoviceTaskUI", BaseView)
local SysNoviceTaskConfig = util_require("GameModule.SysNoviceTask.config.SysNoviceTaskConfig")

function SysNoviceTaskUI:initDatas()
    SysNoviceTaskUI.super.initDatas(self)

    self._data = clone(G_GetMgr(G_REF.SysNoviceTask):getRunningData())
    self._recordLv = globalData.userRunData.levelNum or 1
end

function SysNoviceTaskUI:getCsbName()
   return "GuideNewUser/NewTaskGuideNode.csb"
end

function SysNoviceTaskUI:initCsbNodes()
    SysNoviceTaskUI.super.initCsbNodes(self)

    self.m_baseNode = self:findChild("node_base")
    self.m_baseNode:setPosition(-250, 0)

    local touch = self:findChild("touch")
    touch:setSwallowTouches(false)
    self:addClick(touch)

    self.m_coinsEffect = self:findChild("Particle_1")
    self.m_lb_coins = self:findChild("m_lb_coins")
end

function SysNoviceTaskUI:initUI()
    SysNoviceTaskUI.super.initUI(self)

    -- 进度条
    self:initProgUI()
    -- 气泡
    self:initBubbleUI()
    -- 任务 描述
    self:initTaskDescUI()
    -- 任务 奖励金币
    self:updateCoinsUI()
    -- 任务 数值
    self:updateProgValueUI()
    -- 
    self:playIdleAct()
end

-- 创建进度条
function SysNoviceTaskUI:initProgUI()
    local img = util_createSprite("GuideNewUser/ui/vectoring_jindu.png")
    if not img then
        release_print("initProgress = GuideNewUser/ui/vectoring_jindu.png")
        return
    end
    local sp_bar = self:findChild("sp_bar")
    sp_bar:setVisible(false)
    self.m_bar_pool = cc.ProgressTimer:create(img)
    self.m_bar_pool:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    self.m_bar_pool:setRotation(180)
    self.m_bar_pool:setPosition(sp_bar:getPosition())
    sp_bar:getParent():addChild(self.m_bar_pool, 1)
    
    self:updateProgUI()
end
function SysNoviceTaskUI:updateProgUI()
    if not self.m_bar_pool then
        return
    end

    local percent = self._data:getPercent()
    self.m_bar_pool:setPercentage(percent)
end

-- 气泡
function SysNoviceTaskUI:initBubbleUI()
    self.m_bubble = util_createView("views.newbieTask.GuidePopNode")
    self:addChild(self.m_bubble)
    self.m_bubble:showIdle(1)
    self.m_bubble:setVisible(false)
end

-- npc
function SysNoviceTaskUI:initSpineUI()
    if self.m_spineNpc then
        return
    end

    self.m_nodeNpc = self:findChild("node_spine")
    self.m_spineNpc = util_spineCreate("GuideNewUser/Other/xiaoqiche", false, true, 1)
    self.m_nodeNpc:addChild(self.m_spineNpc)
    util_spinePlay(self.m_spineNpc, "idle", true)
end

-- 任务详情
function SysNoviceTaskUI:initTaskDescUI()
    local node_tips = self:findChild("node_tips")
    self.m_taskTips = util_createView("views.newbieTask.GuideNewTaskTitle")
    node_tips:addChild(self.m_taskTips)
    self:updateTaskDescUI()
end
function SysNoviceTaskUI:updateTaskDescUI()
    local desc = self._data:getTaskDesc()
    local coins = self._data:getTaskRewardCoins()
    self.m_taskTips:updateTitle(desc, coins)
end

-- 任务 奖励金币
function SysNoviceTaskUI:updateCoinsUI()
    local coins = self._data:getTaskRewardCoins()
    local str = string.format("%.fM COINS", (coins / 1000000))
    self.m_lb_coins:setString(str)
end

-- 任务 数值
function SysNoviceTaskUI:updateProgValueUI()
    local type = self._data:getTaskType()
    local cur = self._data:getTaskCurV()
    local total = self._data:getTaskLimitV()
    if type == SysNoviceTaskConfig.TASK_TYPE.SPIN then
        local lbProg = self:findChild("m_lb_count")
        lbProg:setString(cur .. "/" .. total)
    elseif type == SysNoviceTaskConfig.TASK_TYPE.REACH_LEVEL then
        local lbLv = self:findChild("m_lb_num")
        if self._data:isShowQuestOpenAct() then
            lbLv = self:findChild("m_lb_quest_lv")
        end
        lbLv:setString(total)
    end
end

-- idle 动画
function SysNoviceTaskUI:playIdleAct()
    local type = self._data:getTaskType()
    local csbName
    if type == SysNoviceTaskConfig.TASK_TYPE.SPIN then
        csbName = "idle"
    elseif type == SysNoviceTaskConfig.TASK_TYPE.REACH_LEVEL then
        csbName = "idle2"
        if self._data:isShowQuestOpenAct() then
            csbName = "idle3"
        end
    end

    self:runCsbAction(csbName)
end
-- tip显示动画
function SysNoviceTaskUI:playShowTipsAct(_bAuto)
    self.m_taskTips:autoPop(_bAuto)
end
-- 任务出现动画
function SysNoviceTaskUI:playShowAct()
    self.m_baseNode:setPosition(-250, 0)
    local moveTo = cc.EaseBackOut:create(cc.MoveTo:create(0.58, cc.p(20, 0)))
    local showTipsAct = cc.CallFunc:create(function()
        self:playShowTipsAct(true)
        self:checkCollectTask()
    end)
    self.m_baseNode:runAction(cc.Sequence:create(moveTo, showTipsAct))
end
-- 任务结束动画
function SysNoviceTaskUI:playOverAct()
    gLobalNoticManager:removeAllObservers(self) --新手任务结束 注销事件
    if tolua.isnull(self.m_baseNode) then
        return
    end
    self.m_baseNode:setPosition(20, 0)
    local moveTo = cc.EaseBackIn:create(cc.MoveTo:create(0.58, cc.p(-250, 0)))
    local removeSelf = cc.RemoveSelf:create()
    self.m_baseNode:runAction(cc.Sequence:create(moveTo, removeSelf))
end
-- 所有任务未结束播放切换动画
function SysNoviceTaskUI:playSwitchTaskAct(_preTaskType, _curTaskType, _cb)
    if not _preTaskType or not _curTaskType then
        _cb()
        return
    end

    local actName = nil
    local delayTime = 0.1
    if _preTaskType == SysNoviceTaskConfig.TASK_TYPE.SPIN and _curTaskType == SysNoviceTaskConfig.TASK_TYPE.REACH_LEVEL then
        -- spin 任务 切换到 升级 任务
        actName = "switch1"
        if self._data:isShowQuestOpenAct() then
            actName = "switch5"
        end
    elseif _preTaskType == SysNoviceTaskConfig.TASK_TYPE.REACH_LEVEL and _curTaskType == SysNoviceTaskConfig.TASK_TYPE.SPIN then
        -- 升级 任务 切换到 spin 任务
        actName = "switch2"
    elseif _preTaskType == SysNoviceTaskConfig.TASK_TYPE.REACH_LEVEL and _curTaskType == SysNoviceTaskConfig.TASK_TYPE.REACH_LEVEL then
        -- 升级 任务 切换到 升级 任务
        actName = "switch3"
        --关卡切换关卡特殊处理
        local m_lb_next = self:findChild("m_lb_next")
        if self._data:isShowQuestOpenAct() then
            actName = "switch4"
            m_lb_next = self:findChild("m_lb_quest_lv")
        end
        if m_lb_next then
            m_lb_next:setString(self._data:getTaskLimitV())
        end
        delayTime = 0.3
    end

    if actName then
        self:runCsbAction(actName, false, function()
            self:playShowTipsAct(true)
        end, 60)

        performWithDelay(self,function()
            self.m_coinsEffect:resetSystem()
        end, 0.25)
    end

    performWithDelay(self, _cb, delayTime)
end

-- 检测用户当前任务进度是否过半
function SysNoviceTaskUI:checkTaskHalf()
    local taskType = self._data:getTaskType()
    local curLv = globalData.userRunData.levelNum or 1

    if taskType == SysNoviceTaskConfig.TASK_TYPE.SPIN then
        local cur = self._data:getTaskCurV()
        local total = self._data:getTaskLimitV()
        if cur == math.floor(total*0.5) then
            self.m_taskTips:showTaskHalfAction()
        end
    elseif taskType == SysNoviceTaskConfig.TASK_TYPE.REACH_LEVEL and curLv > self._recordLv then
        -- csc 2021-11-04 新手期 5.0 当用户4级的时候要提示任务过半，只显示一次
        -- if globalData.userRunData.levelNum == 4 then
        --     self.m_taskTips:showTaskHalfAction()
        -- end
    end

    self._recordLv = globalData.userRunData.levelNum or 1
end

-- 检查 当前任务是否可以领奖
function SysNoviceTaskUI:checkCollectTask()
    local bCanCol = self._data:checkCanCollect()
    if bCanCol then
        G_GetMgr(G_REF.SysNoviceTask):sendCollectTaskReq()
    end
end

-- 切换到下一个任务
function SysNoviceTaskUI:updateNextTask()
    local newData = G_GetMgr(G_REF.SysNoviceTask):getRunningData()
    if not newData then
        self:playOverAct()
        return
    end

    -- 所有任务未结束播放切换动画
    local preTaskType = self._data:getTaskType()
    local curTaskType = newData:getTaskType()
    self._data = clone(newData)

    local resetUI = function()
        self:updateProgValueUI()
        self:updateProgUI()
        self:updateTaskDescUI()
        self:updateCoinsUI()
        self:checkCollectTask()
    end
    self:playSwitchTaskAct(preTaskType, curTaskType, resetUI)
    self:sendNextTaskLog()
end

function SysNoviceTaskUI:sendNextTaskLog()
    local info = {
        guideId = NOVICEGUIDE_ORDER.noobTaskStart1.id,
        isForce = NOVICEGUIDE_ORDER.noobTaskStart1.force,
        isRepeat = NOVICEGUIDE_ORDER.noobTaskStart1.repetition,
        taskId = self._data:getTaskIdx() 
    }
    gLobalSendDataManager:getLogGuide():setGuideParams(2, info)
    gLobalSendDataManager:getLogGuide():sendGuideLog(2, 1)
end

function SysNoviceTaskUI:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        self:playShowTipsAct(true)
    end
end

function SysNoviceTaskUI:onEnter()
    SysNoviceTaskUI.super.onEnter(self)

    self:registerListener()
end

function SysNoviceTaskUI:onEnterFinish()
    SysNoviceTaskUI.super.onEnterFinish(self)

    if self._bEnterFinish then
        return
    end
    self._bEnterFinish = true
    self:playShowAct()
end

-- spin 任务进度更新
function SysNoviceTaskUI:onUpdateTaskProgEvt()
    local newData = G_GetMgr(G_REF.SysNoviceTask):getRunningData()
    if not newData then
        self:playOverAct()
        return
    end
    
    self._data = clone(newData)
    self:updateProgValueUI()
    self:updateProgUI()

    -- 检测用户当前任务进度是否过半
    self:checkTaskHalf()
    -- 检查当前任务是否完成
    self:checkCollectTask()
end

-- 任务完成 领取成功
function SysNoviceTaskUI:onRecieveColSuccessEvt()
    local coins = self._data:getTaskRewardCoins()
    local delayTime = 0
    if coins > 0 then
        delayTime = 2
        self.m_taskTips:showTaskCompletedFlyCoins(coins)
    end

    performWithDelay(self, function()
        if tolua.isnull(self) then
            return
        end

        -- 当前任务领取完 如果是 要解锁quest 播放动画
        if self._data:isShowQuestOpenAct() then
            local nodeQuestFlyEf = self:findChild("node_quest_ef")
            local flyEf = G_GetMgr(ACTIVITY_REF.Quest):createQuestOpenFlyEf()
            if flyEf then
                nodeQuestFlyEf:addChild(flyEf)
                local cb = function()
                    flyEf:removeSelf()
                    local view = G_GetMgr(ACTIVITY_REF.Quest):showOpenLayer()
                    if view then
                        view:setOverFunc(util_node_handler(self, self.updateNextTask))
                    else
                        self:updateNextTask()
                    end
                end
                flyEf:playFlyAct(cb)
                return
            end
            self:updateNextTask()
            return
        end

        self:updateNextTask()

    end, delayTime)
    
end

-- 显示引导 提高层级
function SysNoviceTaskUI:onDealGuideEvt()
    if not self.m_lastPos then
        self:showGuideBubbleaAct()
        self.m_lastPos = cc.p(self:getPosition())
        self.m_lastNode = self:getParent()
        self.m_lastZorder = self:getLocalZOrder()
        local wordPos = self.m_lastNode:convertToWorldSpace(self.m_lastPos)
        util_changeNodeParent(gLobalViewManager:getViewLayer(), self, ViewZorder.ZORDER_GUIDE + 1)
        self:setPosition(wordPos)
    end
end
function SysNoviceTaskUI:onResetLocalZorderEvt()
    if self.m_lastPos then
        util_changeNodeParent(self.m_lastNode, self, self.m_lastZorder)
        self:setPosition(self.m_lastPos)
        self.m_lastPos = nil
    end
end
function SysNoviceTaskUI:showGuideBubbleaAct(data)
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
                    self:playShowTipsAct(true)
                end,
                0.5
            )
        end,
        delayTime
    )
end

-- 注册事件
function SysNoviceTaskUI:registerListener()
    gLobalNoticManager:addObserver(self, "onUpdateTaskProgEvt", SysNoviceTaskConfig.EVENT_NAME.NOTICE_SYS_NOVICE_TASK_UPDATE) -- spin 任务进度更新
    gLobalNoticManager:addObserver(self, "onRecieveColSuccessEvt", SysNoviceTaskConfig.EVENT_NAME.COLLECT_SYS_NOVICE_TASK_SUCCESS) -- 任务完成 领取成功
    gLobalNoticManager:addObserver(self, "onDealGuideEvt", ViewEventType.NOTIFY_CHANGE_NEWTASK_ZORDER) -- 引导
    gLobalNoticManager:addObserver(self, "onResetLocalZorderEvt", ViewEventType.NOTIFY_GAMEEFFECT_OVER) -- 引导
    gLobalNoticManager:addObserver(self, "onResetLocalZorderEvt", ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE) -- 引导
end


return SysNoviceTaskUI