local LuaList = require("common.LuaList")
local PopViewConfig = require("common.PopViewConfig")
local PopViewManager = class("PopViewManager")
PopViewManager.instance = nil
function PopViewManager:getInstance()
    if not PopViewManager.instance then
        PopViewManager.instance = PopViewManager:create()
        PopViewManager.instance:initData()
    end
    return PopViewManager.instance
end
--初始化
function PopViewManager:initData()
    --弹窗配置
    self.p_popViewConfig = nil
    --步骤配置
    self.p_stepConfig = {}
    --事件配置
    self.p_eventConfig = {}
    --步骤列表
    self.m_doStepList = LuaList.new()
    --事件列表
    self.m_doEventList = LuaList.new()
    --触发类型
    self.m_popType = nil
    --当前阶段类型
    self.m_doStepType = nil
    --结束回调
    self.m_popCallBack = nil
    --指定当前进行中的标识
    self.m_doEventTag = nil
    -- 是否检查过弹出弹板
    self.m_hadCheckPop = false
    --注册通知
    gLobalNoticManager:addObserver(self,function(self,params)
        if self.m_isPause then
            return
        end
        self:doNextStep()
    end,ViewEventType.POP_DONEXT_STEP)
    gLobalNoticManager:addObserver(self,function(self,params)
        if self.m_isPause then
            return
        end
        if params then
            self:checkNotifyDoNext(params)
        else
            self:doNextEvent()
        end
    end,ViewEventType.POP_DONEXT_EVENT)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:doPopOverFunc(params)
    end,ViewEventType.POP_DONEXT_OVER)
end
function PopViewManager:purge()
    gLobalNoticManager:removeAllObservers(self)
    self:doPopOverFunc(true)
end

--读取阶段和事件的配置
function PopViewManager:checkReadConfig()
    if not self.p_popViewConfig then
        --读取弹窗配置
        self.p_popViewConfig = PopViewConfig:create()
        self.p_stepConfig,self.p_eventConfig = self.p_popViewConfig:getConfig()
    end
end

--是否正在执行弹窗
function PopViewManager:isPopView()
    if self.m_popType then
        return true
    end
    return false
end
--是否暂停逻辑
function PopViewManager:setPause(flag)
    self.m_isPause = flag
end

--匹配触发类型
function PopViewManager:isTriggerType(triggerType)
    if self.m_popType and self.m_popType == triggerType then
        return true
    end
    return false
end
--匹配阶段类型
function PopViewManager:isStepType(setpType)
    if self.m_doStepType and self.m_doStepType == setpType then
        return true
    end
    return false
end
--匹配事件类型
function PopViewManager:isEventType(eventType)
    if self.m_doEventTag and self.m_doEventTag == eventType then
        return true
    end
    return false
end
--开始执行弹窗
function PopViewManager:showPopView(type,func)
    --未初始化
    if not self.p_popViewConfig then
        if func then
            func()
        end
        return
    end
    --设置信息开始执行弹窗
    self.m_popType = type
    self.m_popCallBack = func
    self:checkAddShowStep(self.m_popType)
    self.m_hadCheckPop = true
end


--根据触发类型读取配置的步骤信息
function PopViewManager:checkAddShowStep(triggerType)
    --清理阶段列表
    self:clearStep()
    --添加当前阶段步骤
    local stepInfoList = self:getStepInfoList(triggerType)
    if stepInfoList and #stepInfoList>0 then
        for i=1,#stepInfoList do
            local stepInfo = stepInfoList[i]
            if stepInfo then
                self:addStep(stepInfo)
            end
        end
    end
    --开始执行
    self:doNextStep()
end
--根据类型切换事件阶段
function PopViewManager:doStep(stepType)
    if not stepType then
        --结束执行回调
        return self:doPopOverFunc()
    end
    self:checkAddStepEvent(stepType)
end
--根据阶段读取事件信息
function PopViewManager:checkAddStepEvent(stepType)
    --清理事件列表
    self:clearEvent()
    local eventInfoList = self:getEventInfoList(stepType)
    if eventInfoList and #eventInfoList>0 then
        for i=1,#eventInfoList do
            local eventInfo = eventInfoList[i]
            if eventInfo then
                self:addEvent(eventInfo)
            end
        end
    end
    self:doNextEvent()
end

--根据阶段类型获取事件列表
function PopViewManager:getStepInfoList(triggerType)
    return self.p_stepConfig[triggerType]
end
--根据阶段类型获取事件列表
function PopViewManager:getEventInfoList(stepType)
    return self.p_eventConfig[stepType]
end
--添加阶段
function PopViewManager:addStep(stepType)
    self.m_doStepList:push(stepType)
end
--清空阶段数据
function PopViewManager:clearStep()
    self.m_doStepList:clear()
end
--添加当前阶段事件 func回调函数 
function PopViewManager:addEvent(func)
    self.m_doEventList:push(func)
end
--清空当前阶段事件
function PopViewManager:clearEvent()
    self.m_doEventList:clear()
end
--显示当前阶段的下一个事件
function PopViewManager:doNextEvent()
    self.m_doEventTag = nil
    if self.m_doEventList:empty() then
        --切换到下一个阶段
        return self:doNextStep()
    end
    local eventData = self.m_doEventList:pop()
    if eventData and #eventData>=1 then
        local eventFunc = eventData[1] -- 函数
        self.m_doEventTag = eventData[2] --事件标签
        --测试打印
        self:printTest()
        --执行当前事件
        local isExecute = eventFunc()
        if isExecute then
            return nil
        end
    end
    --没有数据执行下一个事件
    return self:doNextEvent() 
end
--检测是否是当前事件的回调函数
function PopViewManager:checkNotifyDoNext(tag)
    if self:isEventType(tag) then
        return self:doNextEvent()
    end
end
--切换到配置的下一个阶段
function PopViewManager:doNextStep()
    if self.m_doStepList:empty() then
        --所有阶段完成执行结束回调
        return self:doPopOverFunc()
    end
    self.m_doStepType = self.m_doStepList:pop()
    return self:doStep(self.m_doStepType)
end
--弹窗结束 isClearCallBack(是否清除回调 不执行)
function PopViewManager:doPopOverFunc(isClearCallBack)
    self:clearStep()
    self:clearEvent()
    self.m_isPause = nil
    self.m_popType = nil
    self.m_doStepType = nil
    self.m_doEventTag = nil
    --直接清理回调不执行
    if isClearCallBack then
        self.m_popCallBack = nil
    else
        if self.m_popCallBack then
            self.m_popCallBack()
            self.m_popCallBack = nil
        end
    end
end

-- 是否检查过弹出弹板
function PopViewManager:checkIsHadCheckPop()
    return self.m_hadCheckPop
end

--测试弹窗打印信息
function PopViewManager:printTest()
    -- if DEBUG == 2 then
    --     print("-------------------------------PopViewManager printTest START-------------------------------")
    --     print("printTest popType = "..self.m_popType)
    --     print("printTest doStepType = "..self.m_doStepType)
    --     if self.m_doEventTag then
    --         print("printTest doEventTag = "..self.m_doEventTag)
    --     end

        release_print("-------------------------------PopViewManager printTest START-------------------------------")
        release_print("printTest popType = "..self.m_popType)
        release_print("printTest doStepType = "..self.m_doStepType)
        if self.m_doEventTag then
            release_print("printTest doEventTag = "..self.m_doEventTag)
        end
    -- end
end

return PopViewManager