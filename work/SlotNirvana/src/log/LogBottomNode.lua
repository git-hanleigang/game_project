--
-- blast活动打点
-- Author:{author}
-- Date: 2019-06-24 21:40:00
--
local NetworkLog = require "network.NetworkLog"
local LogBottomNode = class("LogBottomNode", NetworkLog)

function LogBottomNode:ctor()
    NetworkLog.ctor(self)
end

function LogBottomNode:sendFunctionClickLog(info)
    if not next(info) then
        return
    end

    local str = ""
    for key, value in pairs(info) do
        str = str .. key .. " : " .. value .. ";"
    end
    printInfo("FunctionClickLog = " .. str)

    local log_data = {}
    log_data.tp = "Click"
    log_data.stp = info.siteType
    log_data.et = info.clickName
    log_data.site = info.site

    gL_logData:syncEventData("FunctionClick")
    gL_logData.p_data = log_data
    -- globalPlatformManager:checkSendFireBaseLog(log_data) -- firebase日志没有加 咱不确定是否需要
    self:sendLogData()
end

-- function LogBottomNode:formatActivityTime(activityTime)
--     if not activityTime then
--         return ""
--     end
--     local year = string.sub(activityTime, 1, 4)
--     local month = string.sub(activityTime, 6, 7)
--     local day = string.sub(activityTime, 9, 10)
--     return year .. month .. day
-- end

return LogBottomNode
