--[[
]]
local LuaList = require("common.LuaList")
local TriggerFunctionQueue = class("TriggerFunctionQueue")

function TriggerFunctionQueue:ctor()
    self.m_triggerFuncList = LuaList.new()
    self.m_triggerFuncCount = -1
end

function TriggerFunctionQueue:isEmpty()
    if self.m_triggerFuncList:empty() then
        return true
    end
    return false
end

--执行一系列方法
-- funcdata = {func = 需要执行的方法,params = 参数}
--funcList = {funcdata1,funcdata2,funcdata3}
function TriggerFunctionQueue:checkTriggerList(funcList, overListFunc)
    self.m_triggerFuncCallBack = overListFunc
    if not funcList or #funcList == 0 then
        self:triggerFuncFinish()
        return false
    end
    self.m_triggerFuncList:clear()
    self.m_triggerFuncCount = 0
    for i = 1, #funcList do
        self.m_triggerFuncList:push(funcList[i])
    end
    return self:triggerFuncNext()
end
--执行下一个方法
function TriggerFunctionQueue:triggerFuncNext()
    --结束条件
    if self:isEmpty() then
        self:triggerFuncFinish()
        return false
    end
    local info = self.m_triggerFuncList:pop()
    if info then
        if info.func then
            --执行一个方法
            self.m_triggerFuncCount = self.m_triggerFuncCount + 1
            local function overFunc()
                self:triggerFuncNext()
            end
            info.func(info.params, overFunc)
            return true
        else
            return self:triggerFuncNext()
        end
    else
        return self:triggerFuncNext()
    end
end
--执行完成
function TriggerFunctionQueue:triggerFuncFinish()
    --清空参数
    self:triggerFuncClear()
    if self.m_triggerFuncCallBack then
        local overFunc = self.m_triggerFuncCallBack
        self.m_triggerFuncCallBack = nil
        overFunc()
    end
    self:onFinished()
end

-- 弹板结束消息 这里不能用做控制弹板 有弹板的话 还是要放到弹板列表里面去
-- 这里用作监听该消息的面板自身刷新
function TriggerFunctionQueue:onFinished()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUY_TIP_POPED_OVER)
end

--清空参数
function TriggerFunctionQueue:triggerFuncClear()
    self.m_triggerFuncList:clear()
    self.m_triggerFuncCount = -1
    gLobalViewManager:refreshTriggerQueueList()
end

return TriggerFunctionQueue
