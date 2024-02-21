local NetworkLog = require "network.NetworkLog"
local LogCoinPusher = class("LogCoinPusher", NetworkLog)
-- FIX IOS 139
function LogCoinPusher:ctor()
    NetworkLog.ctor(self)
end

function LogCoinPusher:sendCoinPusherPopupLog(type, page_name, entry_type)
    if not type or not page_name or not entry_type then
        return
    end

    local _CoinPusherData = G_GetMgr(ACTIVITY_REF.CoinPusher):getRunningData()

    if _CoinPusherData == nil or _CoinPusherData:isRunning() == false then
        return
    end

    local curTime = globalData.userRunData.p_serverTime / 1000
    local endTime = _CoinPusherData:getExpireAt()

    local log_data = {}
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}

    log_data.name = "CoinPusher" .. self:formatActivityTime(_CoinPusherData.p_start)
    log_data.day = math.ceil((curTime - util_getymd_time(_CoinPusherData.p_start)) / 86400) -- 天数向上取整
    log_data.s = _CoinPusherData:getRound()
    log_data.rd = _CoinPusherData:getStage()
    log_data.pn = page_name
    log_data.et = entry_type
    log_data.en = entryData.entryName
    log_data.eo = entryData.entryOpen
    log_data.tp = type

    gL_logData:syncEventData("PusherPopup")
    gL_logData.p_data = log_data
    self:sendLogData()
end

function LogCoinPusher:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end

return LogCoinPusher
