--
--island
--2017年8月16日
--NotificationManager.lua
--

---
--事件派发器，作用如同CCNotificationCenter
local NotificationManager = class("NotificationManager")
--NotificationManager = NotificationManager or {}

local EventObserver = class("EventObserver")

NotificationManager._instance = nil
-- local _observers = nil
local CALL_TYPE_FUNCTION = 1
local CALL_TYPE_FUNCTION_1 = 2

function NotificationManager:ctor()
    -- _observers = {}
    self.observerMap = {}
end

-----------------------
--添加监听
--一：回调函数形式
--  1.观察者funtable监听方法行如：
--  funtable={}
--      function funtable:test(param)
--  end
--  2.注册观察者funtable及回调方法funtalbe.test和监听事件MSG_XXX
--      NotificationManager.addObserver(funtable, funtable.test, MSG_XXX)
--  3.被观察者中，派发相应事件MSG_XXX
--      NotificationManager.postNotification(MSG_XXX, "param")
--
--
--二：另一形式回调函数用法：
--function funtable:init()
--  function test2(observer, param)
--      print("test2 obj=", param)
--  end
--  notificationCenter:getInstance():addObserver(self, test2, "msg_test1")
--  notificationCenter:getInstance():postNotification("msg_test1","another param")
--end
--@param self NotificationManager self
--@param target table 观察者
--@param selector function 回调函数
--@param name string 事件名称
--@param isSwallow 是否阻挡后续事件传递
function NotificationManager:addObserver(target, selector, name, isSwallow)
    if not selector then
        return
    end

    if not name or name == "" then
        return
    end

    if (self:_observerExisted(target, name)) then
        return
    end

    isSwallow = isSwallow or false

    local observer = EventObserver:create(target, selector, name, isSwallow)

    -- table.insert(_observers, observer)
    local observers = self.observerMap[name]
    if observers then
        table.insert(observers, #observers + 1, observer)
    else
        self.observerMap[name] = {observer}
    end
end

function NotificationManager:removeObserver(target, name)
    local observers = self.observerMap[name]
    if observers then
        for i = 1, #observers do
            local observer = observers[i]
            if (observer ~= nil) then
                if (observer:getName() == name and observer:getTarget() == target) then
                    observer:clear()
                    table.remove(observers, i)
                    return
                end
            end
        end
    end
end

function NotificationManager:removeAllObservers(target)
    -- local removes = {}
    -- for i = 1, #_observers do
    --     local selObserver = _observers[i]
    --     if (selObserver:getTarget() == target) then
    --         selObserver:clear()
    --         removes[#removes + 1] = i
    --     end
    -- end
    -- --    print_class("observers", _observers)
    -- for i = #removes, 1, -1 do
    --     table.remove(_observers, removes[i])
    -- end

    -- --    print_class("observers", _observers)
    -- local len = #removes
    -- removes = nil
    -- return len
    if not target then
        return
    end

    -- local observers = self.observerMap[target._name]
    for k, observers in pairs(self.observerMap) do
        local removFlag = false
        if observers then
            for i = #observers, 1, -1 do
                local selObserver = observers[i]
                if (selObserver:getTarget() == target) then
                    selObserver:clear()
                    table.remove(observers, i)
                end
            end
        end
        if observers == nil or #observers == 0 then
            self.observerMap[k] = nil
        end
    end
end

---
--派发事件
--@param self NotificationManager self
--@param name string 事件ID
--@param object anytype 回调时传入的参数
function NotificationManager:postNotification(name, object)
    local observers = self.observerMap[name]
    if observers then
        local postServers = {}
        --发送时创建新table,方式推送过程中删除引起索引变化
        for i = 1, #observers do
            postServers[i]=observers[i]
        end
        for i = 1, #postServers do
            local observer = postServers[i]
            if observer ~= nil and observer._selector~=nil then
                if observer._callType == CALL_TYPE_FUNCTION and self:checkTargetExit(observer._target) then
                    observer._selector(observer._target, object)
                elseif observer._callType == CALL_TYPE_FUNCTION_1 then
                    observer._selector(object)
                end

                if observer._isSwallow == true then
                    return
                end
            end
        end
    end
end

function NotificationManager:_observerExisted(target, name)
    local observers = self.observerMap[name]
    if observers then
        for i = 1, #observers do
            local observer = observers[i]
            if (observer and observer:getName() == name and observer:getTarget() == target) then
                return true
            end
        end
    end
    return false
end

-- 抛消息时检查下 target是否存在
function NotificationManager:checkTargetExit(_target)
    if not _target then
        return false
    end
    
    if tolua.type(_target) == "table" then
        -- 纯lua对象, 都是些manager 单例 注册的
        return true
    end
    
    local bExit = not tolua.isnull(_target)
    if not bExit then
        self:removeAllObservers(_target)
    end

    return bExit
end

function NotificationManager:getInstance()
    if (NotificationManager._instance == nil) then
        NotificationManager._instance = NotificationManager.new()
    end
    return NotificationManager._instance
end

EventObserver._target = nil
EventObserver._selector = nil
EventObserver._name = nil
EventObserver._callType = nil
EventObserver._isSwallow = nil
--EventObserver._object=nil

function EventObserver:create(target, selector, name, isSwallow)
    return EventObserver.new(target, selector, name, isSwallow)
end

function EventObserver:ctor(target, selector, name, isSwallow)
    self._callType = CALL_TYPE_FUNCTION
    self._isSwallow = isSwallow

    if (target ~= nil and (type(selector) == "string")) then
        self._selector = target[selector]
    elseif (target ~= nil and (type(selector) == "function")) then
        self._selector = selector
    else
        self._callType = CALL_TYPE_FUNCTION_1
    end

    self._target = target

    self._name = name
    -- self._object = obj
end

function EventObserver:clear()
    self._target = nil
    self._selector = nil
    self._name = nil
    self._isSwallow = nil
end

function EventObserver:performSelector(obj)
    if self._callType == CALL_TYPE_FUNCTION then
        self._selector(self._target, obj)
    elseif self._callType == CALL_TYPE_FUNCTION_1 then
        self._selector(obj)
    end

    -- if (self._target and (type(self._selector) == "string")) then
    --     self._target[self._selector](self._target, obj)
    -- elseif (self._target and (type(self._selector) == "function")) then
    --     self._selector(self._target, obj)
    -- else
    --     self._selector(obj)
    -- end
end

function EventObserver:getName()
    return self._name
end

function EventObserver:getIsSwallow()
    return self._isSwallow
end

function EventObserver:getTarget()
    return self._target
end

function EventObserver:getSelector()
    return self._selector
end

--function EventObserver:getObject()
--    return self._object
--end

return NotificationManager
