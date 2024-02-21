--------------------------------
-- @module scheduler

--[[--

全局计时器、计划任务

«该模块在框架初始化时不会自动载入» 

加载方式: local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

]]
local scheduler = {}
local schedulerHandles = {}

local sharedScheduler = cc.Director:getInstance():getScheduler()

-- start --

--------------------------------
-- 计划一个全局帧事件回调，并返回该计划的句柄。
-- @function [parent=#scheduler] scheduleUpdateGlobal
-- @param function 回调函数
-- @return mixed#mixed ret (return value: mixed)  schedule句柄

--[[--

计划一个全局帧事件回调，并返回该计划的句柄。

全局帧事件在任何场景中都会执行，因此可以在整个应用程序范围内实现较为精确的全局计时器。

该函数返回的句柄用作 scheduler.unscheduleGlobal() 的参数，可以取消指定的计划。 

]]
-- end --

function scheduler.scheduleUpdateGlobal(listener, intervar)
    local _handleId = sharedScheduler:scheduleScriptFunc(listener, intervar or 0, false)
    -- schedulerHandles["" .. _handleId] = _handleId
    return _handleId
end

-- start --

--------------------------------
-- 计划一个以指定时间间隔执行的全局事件回调，并返回该计划的句柄。
-- @function [parent=#scheduler] scheduleGlobal
-- @param function listener 回调函数
-- @param number interval 间隔时间
-- @return mixed#mixed ret (return value: mixed)  schedule句柄

--[[--

计划一个以指定时间间隔执行的全局事件回调，并返回该计划的句柄。 

~~~ lua

local function onInterval(dt)
end
 
-- 每 0.5 秒执行一次 onInterval()
local handle = scheduler.scheduleGlobal(onInterval, 0.5) 

~~~

]]
-- end --

function scheduler.scheduleGlobal(listener, interval)
    local _handleId = sharedScheduler:scheduleScriptFunc(listener, interval, false)
    -- schedulerHandles["" .. _handleId] = _handleId
    return _handleId
end

-- start --

--------------------------------
-- 取消一个全局计划
-- @function [parent=#scheduler] unscheduleGlobal
-- @param mixed schedule句柄

--[[--

取消一个全局计划 

scheduler.unscheduleGlobal() 的参数就是 scheduler.scheduleUpdateGlobal() 和 scheduler.scheduleGlobal() 的返回值。

]]
-- end --

function scheduler.unscheduleGlobal(handle)
    sharedScheduler:unscheduleScriptEntry(handle)
    -- schedulerHandles["" .. handle] = nil
end

function scheduler.unscheduleGlobalAll()
    -- for key, value in pairs(schedulerHandles) do
    --     if value then
    --         sharedScheduler:unscheduleScriptEntry(value)
    --         schedulerHandles["" .. key] = nil
    --     end
    -- end

    schedulerHandles = {}
end

-- start --

--------------------------------
local performDelayRunIds = {} -- 全局倒计时一次执行的scheduler id， 是一个map数据结构

-- 计划一个全局延时回调，并返回该计划的句柄。
-- @function [parent=#scheduler] performWithDelayGlobal
-- @param function listener 回调函数
-- @param number time 延迟时间
-- @param targetName 触发目标的名字，用来做统一移除
-- @return mixed#mixed ret (return value: mixed)  schedule句柄

--[[--

计划一个全局延时回调，并返回该计划的句柄。

scheduler.performWithDelayGlobal() 会在等待指定时间后执行一次回调函数，然后自动取消该计划。

]]
function scheduler.performWithDelayGlobal(listener, time, targetName)
    local handle = nil
    handle =
        sharedScheduler:scheduleScriptFunc(
        function()
            scheduler.unscheduleGlobal(handle)

            if targetName ~= nil then
                performDelayRunIds[targetName .. handle] = nil
            else
                performDelayRunIds[handle] = nil
            end
            listener()
        end,
        time,
        false
    )
    if targetName ~= nil then
        performDelayRunIds[targetName .. handle] = handle
    else
        performDelayRunIds[handle] = handle
    end

    return handle
end
--[[
    @desc: 根据targetName 移除掉所有的schedule name
    author:{author}
    time:2018-07-10 18:23:36
    --@targetName: 
    @return:
]]
function scheduler.unschedulesByTargetName(targetName)
    if targetName == nil then
        return
    end
    for i, v in pairs(performDelayRunIds) do
        if tolua.type(i) == "string" then
            if string.find(i, targetName) ~= nil then
                scheduler.unscheduleGlobal(v)
                performDelayRunIds[i] = nil
            end
        end
    end
end

return scheduler
