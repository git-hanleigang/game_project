-- Minz活动打点

local NetworkLog = require "network.NetworkLog"
local LogMinz = class("LogMinz", NetworkLog)

function LogMinz:ctor()
    NetworkLog.ctor(self)
end

function LogMinz:sendPageLog(_count)
    -- 发送数据
    local gameData = G_GetMgr(ACTIVITY_REF.Minz):getRunningData()
    if not gameData then
        return
    end

    local count = _count or 1
    local choose = count > 1 and "more" or "alone"
    local num = gameData:getAlicePriceByNum(count)

    local log_data = {}
    log_data.tp = "Open"
    log_data.name = "Minz" .. self:formatActivityTime(gameData.p_start)
    local curTime = globalData.userRunData.p_serverTime / 1000
    log_data.day = math.ceil((curTime - util_getymd_time(gameData.p_start)) / 86400) -- 天数向上取整
    log_data.n = num
    log_data.ch = choose
    gL_logData:syncEventData("MinzOpen")
    gL_logData.p_data = log_data
    self:sendLogData()
end

function LogMinz:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end

return LogMinz
