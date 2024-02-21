--[[--
    宠物系统打点
]]
local NetworkLog = require "network.NetworkLog"
local LogSidekicks = class("LogSidekicks", NetworkLog)

function LogSidekicks:sendSidekicksPopupLog(_type, _pageName, _entryType)
    if not _type or not _pageName or not _entryType then
        return
    end

    local data = G_GetMgr(G_REF.Sidekicks):getRunningData()
    if not data then
        return
    end

    local log_data = {}
    log_data.tp = _type
    log_data.pn = _pageName
    log_data.et = _entryType
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    log_data.en = entryData.entryName
    log_data.eo = entryData.entryOpen
    local selectSeasonIdx = G_GetMgr(G_REF.Sidekicks):getSelectSeasonIdx()
    log_data.name = "Sidekicks_"..selectSeasonIdx .. self:formatActivityTime(data.p_start)
    local curTime = globalData.userRunData.p_serverTime / 1000
    log_data.day = math.ceil((curTime - util_getymd_time(data.p_start)) / 86400) -- 天数向上取整
    gL_logData:syncEventData("SidekicksPopup")
    gL_logData.p_data = log_data
    self:sendLogData()
end

function LogSidekicks:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end

return LogSidekicks
