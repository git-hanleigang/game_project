--[[--
    装修活动打点
]]
local NetworkLog = require "network.NetworkLog"
local LogRedecorActivity = class("LogRedecorActivity", NetworkLog)

function LogRedecorActivity:sendRedecorPopupLog(_type, _pageName, _entryType)
    if not _type or not _pageName or not _entryType then
        return
    end

    local data = G_GetMgr(ACTIVITY_REF.Redecor):getRunningData()
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

    log_data.name = "Redecorate" .. self:formatActivityTime(data.p_start)
    local curTime = globalData.userRunData.p_serverTime / 1000
    log_data.day = math.ceil((curTime - util_getymd_time(data.p_start)) / 86400) -- 天数向上取整
    log_data.s = data.round
    log_data.rd = data.stage
    gL_logData:syncEventData("RedecoratePopup")
    gL_logData.p_data = log_data
    self:sendLogData()
end

function LogRedecorActivity:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end

return LogRedecorActivity
