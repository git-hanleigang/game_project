--[[
    任务主界面
]]
-- ios fix
local ShopItem = require "data.baseDatas.ShopItem"
local TaskMainLayer = class("TaskMainLayer", BaseLayer)
local ActivityTaskManager = util_require("manager.ActivityTaskManager"):getInstance()

function TaskMainLayer:initUI(_param)
    if _param and _param.overFunc then
        self.overFunc = _param.overFunc
    end
    self:initData(_param)
    -- if self.m_taskDataObj == nil or not self.m_taskDataObj:isRunning() then
    --     self:refreshTaskData()
    -- end
    TaskMainLayer.super.initUI(self)
    self.m_isCompleted = false --是否是领取完成后回到本界面
end
--初始化数据
function TaskMainLayer:initData(_param)
    self.m_taskDataObj = ActivityTaskManager:getCurrentTaskByActivityName(self:getActivityName())
    if self.m_taskDataObj == nil or not self.m_taskDataObj:isRunning() then
        self.m_isRefresh = true
    end
    self.m_nextTaskData = ActivityTaskManager:getNextTaskByNameAndTask(self:getActivityName(), self.m_taskDataObj) --下个任务数据
    self.m_isNextTask = false --是否有下一个任务开始时间的提示

    self.m_param = _param
end
--初始化节点
function TaskMainLayer:initNode()
    self.m_root = self:findChild("root")
    assert(self.m_root, "root节点为空")
    self.m_titleNode = self:findChild("node_title")
    assert(self.m_titleNode, "标题节点为空")
    self.m_lbDescribe = self:findChild("lb_dec")
    assert(self.m_lbDescribe, "任务描述为空")
    self.m_nodeProgress = self:findChild("node_progress")
    assert(self.m_nodeProgress, "进度节点为空")
    self.m_lbProgressNum = self:findChild("lb_prg")
    assert(self.m_lbProgressNum, "进度描述为空")
    self.m_progress = self:findChild("prg_main")
    assert(self.m_progress, "进度条为空")
    self.m_nodeTime = self:findChild("node_time")
    assert(self.m_nodeTime, "倒计时节点为空") --用于显示下个任务的预告时，隐藏当前任务倒计时
    self.m_lbLeftTime = self:findChild("lb_time")
    assert(self.m_lbLeftTime, "任务倒计时为空")
    self.m_btnCollect = self:findChild("btn_collect")
    assert(self.m_btnCollect, "领取按钮为空")
    self.m_btnPlay = self:findChild("btn_play")
    assert(self.m_btnPlay, "play按钮为空")
    self.m_addBubbleNode = self:findChild("node_qipao") --用于添加气泡的节点
    assert(self.m_addBubbleNode, "用于添加气泡的节点为空")
    self.m_nextTask = self:findChild("node_complete1") --用于显示下个任务的预告，没有下个任务则不显示
    assert(self.m_nextTask, "预告为空")
    self.m_lb_nextTask = self:findChild("lb_next_time") --用于显示下个任务的倒计时
    assert(self.m_lb_nextTask, "下个任务的倒计时为空")

    self:setNodeVisible()
end
--设置某些节点的初始显示
function TaskMainLayer:setNodeVisible()
    local taskImg_1 = self:findChild("sp_m1") --阶段1任务的描述图标
    local taskImg_2 = self:findChild("sp_m2") --阶段2任务的描述图标
    local taskImg_3 = self:findChild("sp_m3") --阶段3任务的描述图标
    local taskReward_1 = self:findChild("node_mr1") --阶段1任务的奖励图标
    local taskReward_2 = self:findChild("node_mr2") --阶段2任务的奖励图标
    local taskReward_3 = self:findChild("node_mr3") --阶段3任务的奖励图标

    self.m_nextTask:setVisible(false)
    taskImg_1:setVisible(false)
    taskImg_2:setVisible(false)
    taskImg_3:setVisible(false)
    taskReward_1:setVisible(false)
    taskReward_2:setVisible(false)
    taskReward_3:setVisible(false)
end
--加载界面
function TaskMainLayer:initView()
    self:initNode()
    if self.m_taskDataObj then
        self:updateTitle()
        self:updateTaskReward()
        self:updateProgress()
        self:setButtonState()
        self:addBubble()
        self:checkLeftTimer()
    end
    self:setLayerExtendData()
    self:addClickSound({"btn_x"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end
--更新标题
function TaskMainLayer:updateTitle()
    self.m_titleNode:removeAllChildren()

    local titleIndex = self.m_taskDataObj:getPhase()
    local title = util_createView("baseActivityTask.TaskTitle", self:getTitleCsbName(), titleIndex)
    assert(title, "任务标题出错")
    self.m_titleNode:addChild(title)
    local taskImg = self:findChild("sp_m" .. titleIndex)
    if taskImg then
        taskImg:setVisible(true)
    end
end
--更新任务奖励
function TaskMainLayer:updateTaskReward()
    local rewardItems = {}
    local taskDataList = ActivityTaskManager:getTaskListByActivityName(self:getActivityName())
    for i, v in ipairs(taskDataList) do
        local rewardItem = v:getDisplayItemData()
        for k, item in ipairs(rewardItem) do
            rewardItems[#rewardItems + 1] = item
        end
    end
    local count = #rewardItems
    if count > 0 then
        for i, v in ipairs(rewardItems) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            local info = gLobalItemManager:createLocalItemData(tempData.p_icon, tempData.p_num, tempData)
            info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
            local itemNode = gLobalItemManager:createRewardNode(info, ITEM_SIZE_TYPE.REWARD)
            if itemNode then
                local node = self:findChild("node_" .. i)
                if node then
                    node:removeAllChildren()
                    node:addChild(itemNode)
                end
            else
                printError("TaskMainLayer 道具创建失败")
            end
        end
    end
end
--更新任务进度
function TaskMainLayer:updateProgress()
    if self.m_taskDataObj then
        local paramsList = self.m_taskDataObj:getParams()
        local processList = self.m_taskDataObj:getProcess()
        local paramsNum = paramsList[1]
        local processNum = processList[1]
        -- self.m_nodeProgress:setVisible(true)
        -- self.m_lbDescribe:setVisible(true)
        self:showCurTask()
        self.m_progress:setPercent(tonumber(processNum) / tonumber(paramsNum) * 100)
        if self.m_taskDataObj:getCompleted() then
            self.m_lbProgressNum:setString("COMPLETED")
            if self.m_taskDataObj:getReward() then
                self:updateNextTask()
            end
        else
            self.m_nodeTime:setVisible(true)
            self.m_lbProgressNum:setString(util_formatCoins(processNum, 3, nil, true) .. "/" .. util_formatCoins(paramsNum, 3, nil, true))
        end

        self:updateProgressReward()
        self:updateTaskDescribe(paramsNum)
    end
end

--显示当前任务相关
function TaskMainLayer:showCurTask()
    self.m_nodeProgress:setVisible(true)
    self.m_lbDescribe:setVisible(true)
end

--下个任务开启时间提示
function TaskMainLayer:updateNextTask()
    if self.m_nextTaskData then
        self.m_nextTask:setVisible(true)
        self.m_isNextTask = true

        self.m_nodeProgress:setVisible(false)
        self.m_lbDescribe:setVisible(false)
        self.m_nodeTime:setVisible(false)
    end
end
--更新进度奖励
function TaskMainLayer:updateProgressReward()
    if self.m_taskDataObj then
        --通用道具
        local rewardItems = self.m_taskDataObj:getItemData()
        local nodeName = "node_mr" .. self.m_taskDataObj:getPhase()
        local coinSG = self:findChild(nodeName .. "_ef_sao")
        if coinSG then
            coinSG:setVisible(false)
        end
        local count = #rewardItems
        if rewardItems and count > 0 then
            self:findChild(nodeName):setVisible(true)
            for i, v in ipairs(rewardItems) do
                local rewardNode = self:findChild(nodeName .. "_" .. i + 1)
                if rewardNode then
                    local tempData = ShopItem:create()
                    tempData:parseData(v)
                    local info = gLobalItemManager:createLocalItemData(tempData.p_icon, tempData.p_num, tempData)
                    info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
                    local itemNode = gLobalItemManager:createRewardNode(info, ITEM_SIZE_TYPE.REWARD)
                    if itemNode then
                        rewardNode:addChild(itemNode)
                        itemNode:setIconTouchEnabled(false)
                    end
                end
            end
        end
        --金币道具
        local coin = self.m_taskDataObj:getCoins()
        local flag = false
        if iskindof(coin,"LongNumber") then
            if coin and toLongNumber(coin) > toLongNumber(0) and count > 0 then
                flag = true
            end
        else
            if coin and coin > 0 and count > 0 then
                flag = true
            end
        end
        if flag then
            local rewardNode = self:findChild(nodeName .. "_" .. 1)
            if rewardNode then
                local info = gLobalItemManager:createLocalItemData("Coins", coin)
                info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
                local itemNode = gLobalItemManager:createRewardNode(info, ITEM_SIZE_TYPE.REWARD)
                rewardNode:addChild(itemNode)
            end
            if coinSG then
                coinSG:setVisible(true)
            end
        end
    end
end
--更新任务描述
function TaskMainLayer:updateTaskDescribe(_paramsNum)
    if self.m_taskDataObj then
        local describe = self.m_taskDataObj:getContent()
        local strNum = util_formatCoins(_paramsNum, 3)
        self.m_lbDescribe:setString(string.format(describe, strNum))
    end
end
--设置按钮状态
function TaskMainLayer:setButtonState()
    if self.m_taskDataObj then
        if self.m_taskDataObj:getCompleted() and not self.m_taskDataObj:getReward() then
            self.m_btnCollect:setVisible(true)
            self.m_btnPlay:setVisible(false)
        else
            self.m_btnPlay:setVisible(true)
            self.m_btnCollect:setVisible(false)
        end
    end
end
--添加气泡
function TaskMainLayer:addBubble()
    self.m_addBubbleNode:removeAllChildren()
    self.m_bubble = nil
    self.m_bubble = util_createView("baseActivityTask.TaskBubble", self:getBubbleCsbName(), self:getActivityName(), self.getItemScale())
    assert(self.m_bubble, "奖励气泡出错")
    self.m_addBubbleNode:addChild(self.m_bubble)
end
--气泡动画
function TaskMainLayer:runBubbleAmin()
    if self.m_bubble then
        if self.m_bubble:getBubbleState() then
            self.m_bubble:runShowAmin()
        else
            self.m_bubble:runHideAmin()
        end
    end
end

--剩下时间
function TaskMainLayer:checkLeftTimer()
    self:stopLeftTimerAction()
    local function updateTime()
        if self.m_taskDataObj and self.m_taskDataObj:isRunning() then
            if self.m_isNextTask then
                local startTime = self.m_nextTaskData:getStart()
                local strStartTime, isOver = util_daysdemaining(startTime / 1000, true)
                self.m_lb_nextTask:setString(string.format("%s", strStartTime))
                if isOver then
                    gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
                    self:stopLeftTimerAction()
                    self:closeUI(
                        function()
                            self:closeOtherUI()
                            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                        end
                    )
                end
                return
            end
            local expireAt = self.m_taskDataObj:getExpireAt()
            local strLeftTime = util_daysdemaining(expireAt, true)
            self.m_lbLeftTime:setString(string.format("%s", strLeftTime))
        else
            if not self.m_isRefresh then
                gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
                self:stopLeftTimerAction()
                self:closeUI(
                    function()
                        self:closeOtherUI()
                        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                        if self.m_isCompleted or (self.m_param and self.m_param.isCompleted) then
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_VIEW_CLOSE)
                        end
                    end
                )
            end
        end
    end
    updateTime()
    self.m_leftTimeAction = util_schedule(self, updateTime, 1)
end
function TaskMainLayer:stopLeftTimerAction()
    if self.m_leftTimeAction ~= nil then
        self:stopAction(self.m_leftTimeAction)
        self.m_leftTimeAction = nil
    end
end

function TaskMainLayer:onClickMask()
    self:onClickCollect()
end

function TaskMainLayer:onClickCollect()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if self.m_isTouchCompleted then
        return
    end
    if self.m_taskDataObj and self.m_taskDataObj:getCompleted() and not self.m_taskDataObj:getReward() and not self.m_bubble:getActionTimeState() then
        self.m_isTouchCompleted = true
        self:openRewardViewAmin()
    end
end

function TaskMainLayer:clickFunc(_sender)
    local senderName = _sender:getName()
    if senderName == "btn_x" then
        if self.m_isTouchCompleted then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            return
        end
        if self.m_taskDataObj:getCompleted() and not self.m_taskDataObj:getReward() and not self.m_bubble:getActionTimeState() then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self.m_isTouchCompleted = true
            self:openRewardViewAmin()
        elseif not self.m_bubble:getActionTimeState() then
            gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
            self:closeUI(
                function()
                    if self.m_isCompleted or (self.m_param and self.m_param.isCompleted and self.m_isRefresh) then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_VIEW_CLOSE)
                    else
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_VIEW_CLOSE_NORMAL)
                    end
                end
            )
        end
    elseif senderName == "btn_play" then
        gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
        self:closeUI(
            function()
                if self.m_isCompleted or (self.m_param and self.m_param.isCompleted and self.m_isRefresh) then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_VIEW_CLOSE)
                else
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_VIEW_CLOSE_NORMAL)
                end
            end
        )
    elseif senderName == "btn_collect" then
        self:onClickCollect()
    elseif senderName == "btn_info" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_isNextTask then
            return
        end
        self:runBubbleAmin()
    end
end
--打开奖励页的动画
function TaskMainLayer:openRewardViewAmin()
    self.m_bubble:forceHide()
    self:runCsbAction(
        "start3",
        false,
        function()
            self:openRewardView()
        end,
        60
    )
end
--领取结束更新界面
function TaskMainLayer:updateView()
    self:initData()
    if self.m_taskDataObj then
        self:setNodeVisible()
        self:updateTitle()
        self:updateTaskReward()
        self:updateProgress()
        self:setButtonState()
        self:addBubble()
        self:checkLeftTimer()
    end
end

function TaskMainLayer:closeOtherUI()
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
--监听
function TaskMainLayer:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateView()
            self.m_isCompleted = true
            self.m_isTouchCompleted = false

            -- cxc 2023年11月30日15:02:44  老版大活动任务领取完最后一个 监测弹（绑定邮箱）
            if not self.m_nextTaskData then
                G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("OldActivityMission", self:getActivityName())
            end

        end,
        ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_END
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateView()
            self.m_isRefresh = false
        end,
        ViewEventType.NOTIFY_ACTIVITY_TASK_UPDATE_DATA
    )
end

function TaskMainLayer:onEnter()
    TaskMainLayer.super.onEnter(self)
    if self.m_isRefresh then
        self:refreshTaskData()
        return
    end

    local isOpenBubble = ActivityTaskManager:getOpenBubbleFlag()
    if not isOpenBubble and not self.m_taskDataObj:getReward() then
        ActivityTaskManager:setOpenBubbleFlag(true)
        self:runBubbleAmin()
    end

    --金币道具
    local coin = self.m_taskDataObj:getCoins()
    if coin and coin > 0 then
        self:runCsbAction("idle1", true)
    end
end

-- 当前活动的数据到期,重新请求数据
function TaskMainLayer:refreshTaskData()
    ActivityTaskManager:getInstance():refreshTaskData()
end
-------------------------------------------------------  子类必须重写 ------------------------------------------

-- function TaskMainLayer:getCsbName()
--     assert("必要的主界面资源名称")
-- end

function TaskMainLayer:getTitleCsbName()
    assert("必要的标题资源名称")
end

function TaskMainLayer:getBubbleCsbName()
    assert("必要的奖励气泡资源名称")
end

function TaskMainLayer:getActivityName()
    assert("必要的活动名称，用于获取相对应的活动任务")
end

------------------------------------------------------  子类非必须重写 ----------------------------------------
--打开奖励页,用于打开奖励页面,非大厅弹板必须要重写
function TaskMainLayer:openRewardView()
end
--打开活动主界面，大厅弹板必须要重写
function TaskMainLayer:openActivityMianUI()
end
--连带关闭的界面
function TaskMainLayer:getCloseExtendKeyList()
end
--气泡内道具的缩放值
function TaskMainLayer:getItemScale()
    return {0.9, 0.7, 0.6} -- {只有一个道具时缩放值，大于1个时缩放值}
end

function TaskMainLayer:setLayerExtendData()
end
return TaskMainLayer
