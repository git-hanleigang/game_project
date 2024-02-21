--
-- blast活动打点
-- Author:{author}
-- Date: 2019-06-24 21:40:00
--
local NetworkLog = require "network.NetworkLog"
local LogBlast = class("LogBlast", NetworkLog)

function LogBlast:ctor()
    NetworkLog.ctor(self)
end

function LogBlast:sendBlastPopupLog(type, page_name, entry_type, flag)
    if not type or not page_name or not entry_type then
        return
    end

    local log_data = {}
    log_data.tp = type
    log_data.pn = page_name
    log_data.et = entry_type
    local _blastData = G_GetMgr(ACTIVITY_REF.Blast):getRunningData()
    if _blastData == nil then
        return
    end
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    log_data.en = entryData.entryName
    log_data.eo = entryData.entryOpen

    log_data.name = "Blast" .. self:formatActivityTime(_blastData.p_start)
    local curTime = globalData.userRunData.p_serverTime / 1000
    local endTime = _blastData:getExpireAt()
    log_data.day = math.ceil((curTime - util_getymd_time(_blastData.p_start)) / 86400) -- 天数向上取整
    log_data.s = _blastData.round
    log_data.rd = _blastData.stage
    local p = "BlastPopup"
    if flag then
        p = "NUBlastPopup"
    end
    gL_logData:syncEventData(p)
    gL_logData.p_data = log_data
    -- globalPlatformManager:checkSendFireBaseLog(log_data) -- firebase日志没有加 咱不确定是否需要
    self:sendLogData()
end

function LogBlast:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end

return LogBlast
