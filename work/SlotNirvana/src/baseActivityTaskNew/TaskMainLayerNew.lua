--[[
    新版任务主界面
]]
-- ios fix
local TaskMainLayerNew = class("TaskMainLayerNew", BaseLayer)
local ActivityTaskManager = util_require("manager.ActivityTaskNewManager"):getInstance()

function TaskMainLayerNew:initUI(_param)
    self:initData(_param)
    TaskMainLayerNew.super.initUI(self)
end
--初始化数据
function TaskMainLayerNew:initData(_param)
    self.m_taskDataObj = ActivityTaskManager:getTaskDataByActivityName(self:getActivityName())
    self.m_curTaskData = ActivityTaskManager:getCurrentTaskByActivityName(self:getActivityName())
    self.m_lastTaskData = ActivityTaskManager:getLastTaskByActivityName(self:getActivityName())
    self.m_aniTaskList = ActivityTaskManager:getAniTaskList(self:getActivityName())
    self.m_param = _param
    self.m_isAnimationTime = false --是否正在动画中
    self.m_isCompleted = false --是否完成
end

--初始化节点
function TaskMainLayerNew:initCsbNodes()
    self.m_node_mid = self:findChild("node_mid")
    assert(self.m_node_mid, "node_mid节点为空")
    self.m_node_mission = self:findChild("node_mission")
    assert(self.m_node_mission, "node_mission节点为空")
    self.m_node_completed = self:findChild("node_completed")
    assert(self.m_node_completed, "node_completed节点为空")
    self.m_node_completed:setVisible(false)
    self.m_spineNode = self:findChild("node_spine")
    self.m_nodeProgress = self:findChild("node_progress")
    assert(self.m_nodeProgress, "进度节点为空")
    self.m_btnInfo = self:findChild("btn_info")
    assert(self.m_btnInfo, "帮助按钮为空")
    self.m_btnClose = self:findChild("btn_close")
    assert(self.m_btnInfo, "关闭按钮为空")
    self.m_lbTime = self:findChild("lb_time")
    assert(self.m_lbTime, "倒计时为空") --任务倒计时
    -- 任务节点
    self.m_node_normal1 = self:findChild("node_normal1")
    assert(self.m_node_normal1, "普通任务节点为空")
    self.m_node_normal2 = self:findChild("node_normal2")
    assert(self.m_node_normal2, "普通任务节点为空")

    self.m_label_round = self:findChild("lb_round")
end

--加载界面
function TaskMainLayerNew:initView()
    if self.m_taskDataObj then
        self:initSpine()
        self:initProgress()
        self:showDownTimer()
        self:initTask()
        self:checkTaskComplete()
    end
    self:setLayerExtendData()
    if self.m_param and self.m_param._bEntance then
        self.m_btnInfo:setVisible(false)
        self.m_btnClose:setVisible(false)
    end
end

function TaskMainLayerNew:initProgress()
    local _proCsbName = self:getProgressCsbName()
    local _rewardCsbName = self:getRewardCsbName()
    local _activityName = self:getActivityName()
    local _rewardNodeSpineName = self:getRewardNodeSpineName()
    local _flowerOpenSound = self:getFlowerOpenSound()
    local _rewardWidth = self:getRewardWidth()
    local _rewardBubbleWidth = self:getRewardBubbleWidth()
    local params = {
        proCsbName = _proCsbName,
        rewardCsbName = _rewardCsbName,
        activityName = _activityName,
        rewardNodeSpineName = _rewardNodeSpineName,
        flowerOpenSound = _flowerOpenSound,
        rewardWidth = _rewardWidth,
        rewardBubbleWidth = _rewardBubbleWidth
    }
    local progress = util_createView("baseActivityTaskNew.TaskProgressNew", params)
    if progress then
        self.m_nodeProgress:addChild(progress)
        self.m_progress = progress
    end
end

--初始化spine
function TaskMainLayerNew:initSpine()
    local spineName = self:getSpineName()
    if spineName then
        self.m_spine = util_spineCreate(spineName, false, true, 1)
        self.m_spineNode:addChild(self.m_spine)
        util_spinePlay(self.m_spine, "idle", true)
    end
end

--初始化任务
function TaskMainLayerNew:initTask()
    self.m_taskCellList = {}
    for i = 1, #self.m_lastTaskData do
        local _missionCsb = self:getMissionCsbName()
        local _activityName = self:getActivityName()
        local _data = self.m_lastTaskData[i]
        local _inx = i
        local _missionRefreshSound = self:getMissionRefreshSound()
        local params = {
            missionCsb = _missionCsb,
            activityName = _activityName,
            data = _data,
            inx = _inx,
            missionRefreshSound = _missionRefreshSound
        }
        local taskCell = util_createView("baseActivityTaskNew.TaskMissionNew", params)

        local node = self["m_node_normal" .. i]
        if node then
            node:addChild(taskCell)
        end
        table.insert(self.m_taskCellList, taskCell)
    end
    local currentStage = self.m_taskDataObj:getCurrentStage()
    self.m_label_round:setString(currentStage)
end

--显示倒计时
function TaskMainLayerNew:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function TaskMainLayerNew:updateLeftTime()
    if self.m_taskDataObj then
        local strLeftTime, isOver = util_daysdemaining(self.m_taskDataObj:getExpireAt(), true)
        if isOver then
            self:stopTimerAction()
            self:closeUI(
                function()
                    self:closeOtherUI()
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end
            )
            return
        end
        self.m_lbTime:setString(strLeftTime)
    else
        self:stopTimerAction()
        self:closeUI(
            function()
                self:closeOtherUI()
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                if self.m_isCompleted then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_VIEW_CLOSE)
                end
            end
        )
    end
end

function TaskMainLayerNew:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function TaskMainLayerNew:clickFunc(_sender)
    if self.m_isAnimationTime then
        return
    end
    local senderName = _sender:getName()
    if senderName == "btn_close" then
        self:closeUI(
            function()
                if self.m_isCompleted then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_VIEW_CLOSE)
                else
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_VIEW_CLOSE_NORMAL)
                end
            end
        )
    elseif senderName == "btn_info" then
        self:openExplainView()
    end
end

--打开帮助界面
function TaskMainLayerNew:openExplainView()
    local explainLayer =
        util_createView("baseActivityTaskNew.TaskExplainLayerNew", self:getExplainCsbName(), self:getPageNum())
    if explainLayer ~= nil then
        gLobalViewManager:showUI(explainLayer, ViewZorder.ZORDER_UI)
    end
end

--打开过度界面
function TaskMainLayerNew:openBlackView()
    local info = self.m_taskDataObj:getStageRewardList()
    local stage = self.m_taskDataObj:getCurrentStage()
    local blackLayer =
        util_createView("baseActivityTaskNew.TaskBlackLayerNew", self:getBlackCsbName(), info, stage)
    if blackLayer ~= nil then
        local node = self:findChild("node_Black")
        if node then
            node:addChild(blackLayer)
        end
        --gLobalViewManager:showUI(blackLayer, ViewZorder.ZORDER_UI)
    end
end

-- 飞粒子
function TaskMainLayerNew:flyParticle(node)
    if not node then
        return
    end
    local targetPos = self.m_node_mid:convertToNodeSpace(self.m_progress:getTargetPos())
    if not targetPos then
        self.m_progress:increaseProgressAction()
        return
    end
    if self:getFlySound() then
        gLobalSoundManager:playSound(self:getFlySound())
    end
    local particle = util_createAnimation(self:getFlyCsbName())
    local posX, posY = node:getPosition()
    self.m_node_mid:addChild(particle)
    particle:setPosition(posX - 100, posY + 20)
    particle:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.8, targetPos),
            cc.DelayTime:create(0.2),
            cc.CallFunc:create(
                function()
                    particle:removeFromParent()
                    self.m_progress:increaseProgressAction()
                end
            )
        )
    )
    self.m_progress:setScrollTouch(false)
end

function TaskMainLayerNew:checkTaskComplete()
    if self.m_taskDataObj then
        local taskList = ActivityTaskManager:getAniTaskList(self:getActivityName())
        if #taskList > 0 then
            self.m_isAnimationTime = true

            performWithDelay(
                self,
                function()
                    if not tolua.isnull(self) then
                        for i = 1, #taskList do
                            local index = taskList[i].index
                            local func = function()
                                if not tolua.isnull(self) then
                                    self:flyParticle(self["m_node_normal" .. index])
                                end
                            end
                            self.m_taskCellList[index]:playProgressAction(func)
                        end
                    end
                end,
                0.3
            )
        else
            self:checkIsHasTaskReward()
            local isComplete = ActivityTaskManager:checkIsFinish()
            if isComplete then
                self.m_node_mission:setVisible(false)
                self.m_node_completed:setVisible(true)
            end
        end
    end
end

--动画结束更新界面
function TaskMainLayerNew:updateView()
    local isReward = ActivityTaskManager:checkIsHasTaskReward(self:getActivityName())
    if isReward then
        self:checkIsHasTaskReward()
    else
        self:updateTask()
        self.m_isAnimationTime = false
    end
end

--检测是否有任务奖励可以领取
function TaskMainLayerNew:checkIsHasTaskReward()
    local isReward = ActivityTaskManager:checkIsHasTaskReward(self:getActivityName())
    if isReward then
        performWithDelay(
            self,
            function()
                if not tolua.isnull(self) then
                    self:openRewardView()
                end
            end,
            0.5
        )
    end
end

function TaskMainLayerNew:updateTask()
    if self.m_taskDataObj then
        local currentStage = self.m_taskDataObj:getCurrentStage()
        self.m_label_round:setString(currentStage)
        local isComplete = self.m_taskDataObj:getAllComplect()
        if isComplete then
            self.m_node_mission:setVisible(false)
            self.m_node_completed:setVisible(true)
        else
            local taskList = self.m_aniTaskList
            if #taskList > 0 then
                for i = 1, #taskList do
                    local taskInfo = taskList[i]
                    local index = taskInfo.index
                    self.m_taskCellList[index]:updateView(self.m_curTaskData[index])
                end
                self.m_aniTaskList = {}
            end
        end
    end
end

function TaskMainLayerNew:closeOtherUI()
    local closeExtendKeyList = self:getCloseExtendKeyList()
    if closeExtendKeyList ~= nil then
        for k, v in ipairs(closeExtendKeyList) do
            local ui = gLobalViewManager:getViewByExtendData(v)
            if ui ~= nil and ui.removeFromParent ~= nil then
                ui:removeFromParent()
            end
        end
    end
end

function TaskMainLayerNew:closeUI(_over)
    self.m_progress:hideParticles()
    TaskMainLayerNew.super.closeUI(self, _over)
end

--监听
function TaskMainLayerNew:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self.m_isCompleted = true
            if params and params == 1 then
                local isComplete = self.m_taskDataObj:getAllComplect()
                if not isComplete then
                    self:openBlackView()
                    self.m_progress:updateUI()
                end
            end
            self:updateTask(true)
            self.m_isAnimationTime = false

            -- cxc 2023年11月30日15:02:44  新版大活动所有任务领取完 监测弹（绑定邮箱）
            if self.m_taskDataObj:getAllComplect() then
                G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("NewActivityMission", self:getActivityName())
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_END
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateView()
            ActivityTaskManager:getInstance():clearAniTaskList()
        end,
        ViewEventType.NOTIFY_ACTIVITY_TASKNEW_ACTION_FINISH
    )
end

-------------------------------------------------------  子类必须重写 ------------------------------------------
function TaskMainLayerNew:getProgressCsbName()
    assert("必要的进度条资源名称")
end

function TaskMainLayerNew:getMissionCsbName()
    assert("必要的任务节点资源名称")
end

function TaskMainLayerNew:getRewardCsbName()
    assert("必要的奖励节点资源名称")
end

function TaskMainLayerNew:getFlyCsbName()
    assert("必要的飞行节点资源名称")
end

function TaskMainLayerNew:getExplainCsbName()
    assert("必要的帮助资源名称")
end

function TaskMainLayerNew:getActivityName()
    assert("必要的活动名称，用于获取相对应的活动任务")
end

function TaskMainLayerNew:getRewardNodeSpineName()
    assert("必要的spine名称，用于做动效")
end

------------------------------------------------------  子类非必须重写 ----------------------------------------
--打开奖励页,用于打开奖励页面,非大厅弹板必须要重写
function TaskMainLayerNew:openRewardView()
end
--连带关闭的界面
function TaskMainLayerNew:getCloseExtendKeyList()
end

function TaskMainLayerNew:setLayerExtendData()
end

function TaskMainLayerNew:getSpineName()
    return nil
end
-- 帮助界面page数量(默认1个)
function TaskMainLayerNew:getPageNum()
    return 1
end

-- 花苞开放音效
function TaskMainLayerNew:getFlowerOpenSound()
    return nil
end

-- 进度刷新音效
function TaskMainLayerNew:getMissionRefreshSound()
    return nil
end

-- 飞离子音效
function TaskMainLayerNew:getFlySound()
    return nil
end

-- 进度条上的奖励，气泡的长度
function TaskMainLayerNew:getRewardBubbleWidth()
    return 0
end

-- 进度条上的奖励，圆圈的长度
function TaskMainLayerNew:getRewardWidth()
    return 0
end

return TaskMainLayerNew
