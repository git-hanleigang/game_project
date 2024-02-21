
--[[--
    已弃用
]]
local NetworkLog = require "network.NetworkLog"
local LogGameDL = class("LogGameDL",NetworkLog)
function LogGameDL:ctor()
    NetworkLog.ctor(self)
end
function LogGameDL:sendLogMessage( ... )
    local args = {...}
    -- 在这里组织你感兴趣的数据
    NetworkLog.sendLogData(self)
end
-- 外部调用接口 start ----------------------------------------------------------
function LogGameDL:resetListByName(levelName)
end
function LogGameDL:setParams(levelName, params)
end
--下载相关log
function LogGameDL:sendDownLoadLog(levelName, actionType, status)
end
-- 外部调用接口 end   ----------------------------------------------------------
return LogGameDL