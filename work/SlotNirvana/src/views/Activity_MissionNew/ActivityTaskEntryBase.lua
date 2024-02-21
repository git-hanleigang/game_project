--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-15 11:08:29
]]
--[[
    新版任务入口按钮基类
]]
local ActivityTaskEntryBase = class("ActivityTaskEntryBase", util_require("base.BaseView"))
local ActivityTaskManager = util_require("manager.ActivityTaskNewManager")
local LuaList = require("common.LuaList")

function ActivityTaskEntryBase:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
        isAutoScale = false
    end

    if self.getCsbName ~= nil then
        self:createCsbNode(self:getCsbName(), isAutoScale)
        self:initNode()
        self:registerListener()
        self:initTaskProgress()
    end

    self.m_triggerFuncList = LuaList.new()
end

--初始化节点
function ActivityTaskEntryBase:initNode()
    self.m_lbProgressNum = self:findChild("lb_dec") --进度数字（名称固定）
    assert(self.m_lbProgressNum, "ActivityTaskEntryBase 必要的节点1")
    self.m_nodeProgress = self:findChild("prg") --进度条（名称固定）
    assert(self.m_nodeProgress, "ActivityTaskEntryBase 必要的节点2")
    self.m_lbnormal_desc1 = self:findChild("lb_normal_desc1") -- 气泡标题
    assert(self.m_lbnormal_desc1, "ActivityTaskEntryBase 必要的节点3")
    self.m_lbFlowerNum = self:findChild("lb_flower_num") -- 气泡任务积分数
    assert(self.m_lbFlowerNum, "ActivityTaskEntryBase 必要的节点4")
    self.m_lbnormal_desc2 = self:findChild("lb_normal_desc2") -- 气泡标题
    assert(self.m_lbnormal_desc2, "ActivityTaskEntryBase 必要的节点5")
    self.m_lbnormal_desc3 = self:findChild("lb_normal_desc3") -- 气泡标题
    assert(self.m_lbnormal_desc3, "ActivityTaskEntryBase 必要的节点6")
end

--初始化任务进度显示
function ActivityTaskEntryBase:initTaskProgress()
    local activityName = self:getActivityName()
    if activityName then
        local taskDataObj = ActivityTaskManager:getInstance():getTaskDataByActivityName(activityName)
        if taskDataObj then
            local progress, maxPoints, minPoints = ActivityTaskManager:getInstance():getEntryProgress(activityName)
            self.m_params = maxPoints
            self.m_process = taskDataObj:getCurrentPoints()
            self.m_minPoint = minPoints
            self.m_nodeProgress:setPercent(progress)

            if taskDataObj:getCompleted() then
                self.m_lbProgressNum:setString("COMPLETED")
                self.m_nodeProgress:setPercent(100)
            else
                self.m_lbProgressNum:setString(progress .. "%")
            end
            util_scaleCoinLabGameLayerFromBgWidth(self.m_lbProgressNum, 112)
        end
    end
end

--更新任务进度显示
function ActivityTaskEntryBase:updateTaskProgress()
    local activityName = self:getActivityName()
    if activityName then
        local isHasTaskReward = ActivityTaskManager:getInstance():checkIsHasTaskReward(activityName)
        if not isHasTaskReward then
            local completeTaskList = ActivityTaskManager:getInstance():getAniTaskList(activityName)
            if #completeTaskList > 0 then
                local funcList = {}
                for i = 1, #completeTaskList do
                    funcList[#funcList + 1] = {func = handler(self, self.executeAnimation), params = completeTaskList[i].data}
                    funcList[#funcList + 1] = {func = handler(self, self.executeAnimationNew), params = completeTaskList[i].newData}
                end
                ActivityTaskManager:getInstance():clearAniTaskList()
                --开始执行
                self:checkTriggerList(funcList)
            end
        else
            self:initTaskProgress()
        end
    end
end

function ActivityTaskEntryBase:clickFunc()
    self:openTaskView()
end

function ActivityTaskEntryBase:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateTaskProgress()
        end,
        ViewEventType.NOTIFY_ACTIVITY_TASK_UPDATE_DATA
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initTaskProgress()
        end,
        ViewEventType.NOTIFY_ACTIVITY_TASK_UPDATE_UI
    )
end

function ActivityTaskEntryBase:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

-- 动画执行
function ActivityTaskEntryBase:executeAnimation(params)
    local taskDataObj = ActivityTaskManager:getInstance():getTaskDataByActivityName(self:getActivityName())
    if not taskDataObj then
        return
    end
    -- self.m_lbBubbleDec:setString("" .. params.description)
    -- util_scaleCoinLabGameLayerFromBgWidth(self.m_lbBubbleDec, 112)
    self:setDesc("" .. params.description)
    self.m_lbFlowerNum:setString("" .. params.points)
    self:runCsbAction("show", false, function()
        self:runCsbAction("complete", false, function()
            self:increaseProgressAction(params)
        end, 60)
    end, 60)
end

function ActivityTaskEntryBase:executeAnimationNew(params)
    local taskDataObj = ActivityTaskManager:getInstance():getTaskDataByActivityName(self:getActivityName())
    if not taskDataObj then
        return
    end
    --self.m_lbBubbleDec:setString("" .. params.description)
    self:setDesc("" .. params.description)
    --util_scaleCoinLabGameLayerFromBgWidth(self.m_lbBubbleDec, 112)
    self.m_lbFlowerNum:setString("" .. params.points)
    self:runCsbAction("show2", false, function()
        self:runCsbAction("over2", false, function()
            self:triggerFuncNext()
        end, 60)
    end, 60)
end

-- 初始化描述
function ActivityTaskEntryBase:setDesc(des)
    local lineNum, lineStrVec = util_AutoLine(self.m_lbnormal_desc1, des, 120, true)
    for i = 1, 3 do
        local label = self["m_lbnormal_desc" .. i]
        if i <= lineNum then
            label:setString("" .. lineStrVec[i])
        else
            label:setString("")
        end
    end
    local indest = 0
    if lineNum == 2 then
        indest = -15
    end
    -- 根据行数调整位置
    if lineNum == 1 then
        local label = self.m_lbnormal_desc1
        label:setPositionY(0)
    elseif lineNum <= 3 then
        for i = 1, lineNum do
            local label = self["m_lbnormal_desc" .. i]
            if label then
                label:setPositionY(25-25*(i-1) + indest)
            end
        end
    end
end

function ActivityTaskEntryBase:increaseProgressAction(params)
    local taskDataObj = ActivityTaskManager:getInstance():getTaskDataByActivityName(self:getActivityName())
    local intervalTime = 1 / 60
    -- 根据不同情况可以设置不同的速度
    local sppeedTiem = 0.5
    local process = self.m_process + params.points
    if process > taskDataObj:getCurrentPoints() then
        process = taskDataObj:getCurrentPoints()
    end
    local speedVal = params.points
    speedVal = speedVal * intervalTime / sppeedTiem
    if self.m_sheduleHandle then
        self:stopAction(self.m_sheduleHandle)
        self.m_sheduleHandle = nil
    end
    self.m_sheduleHandle =
        schedule(
        self,
        function()
            local percent = math.floor((self.m_process - self.m_minPoint) / (self.m_params - self.m_minPoint) * 100)
            if self.m_process < process then
                local newProgressLen = math.min(self.m_process + speedVal, process)
                self.m_process = newProgressLen
                self.m_nodeProgress:setPercent(percent)
            else
                if self.m_sheduleHandle then
                    self:stopAction(self.m_sheduleHandle)
                    self.m_sheduleHandle = nil
                end
                self.m_process = process
                self.m_nodeProgress:setPercent(percent)
                self:runCsbAction("over", false, function()
                    self:triggerFuncNext()
                end, 60)
            end
            if taskDataObj:getCompleted() then
                self.m_lbProgressNum:setString("COMPLETED")
                self.m_nodeProgress:setPercent(100)
            else
                self.m_lbProgressNum:setString(percent .. "%")
            end
            util_scaleCoinLabGameLayerFromBgWidth(self.m_lbProgressNum, 112)
        end,
        intervalTime
    )
end

--执行一系列方法
function ActivityTaskEntryBase:checkTriggerList(funcList)
    if not funcList or #funcList == 0 then
        self:triggerFuncFinish()
        return false
    end
    self.m_triggerFuncList:clear()
    for i = 1, #funcList do
        self.m_triggerFuncList:push(funcList[i])
    end
    return self:triggerFuncNext()
end

--执行下一个方法
function ActivityTaskEntryBase:triggerFuncNext()
    --结束条件
    if self.m_triggerFuncList:empty() then
        self:triggerFuncFinish()
        return false
    end
    local info = self.m_triggerFuncList:pop()
    if info then
        if info.func then
            --执行一个方法
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
function ActivityTaskEntryBase:triggerFuncFinish()
    --清空参数
    self:triggerFuncClear()
end

--清空参数
function ActivityTaskEntryBase:triggerFuncClear()
    self.m_triggerFuncList:clear()
end

--------------------------  子类重写 ---------------------------
function ActivityTaskEntryBase:getCsbName()
    assert("ActivityTaskEntryBase:getCsbName 必须重写")
end

function ActivityTaskEntryBase:getActivityName()
    assert("ActivityTaskEntryBase:getActivityName 必须重写")
end

function ActivityTaskEntryBase:openTaskView()
    assert("ActivityTaskEntryBase:openTaskView 必须重写")
end

return ActivityTaskEntryBase
