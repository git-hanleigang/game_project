--
-- 大富翁活动打点
-- Author:{author}
-- Date: 2019-06-24 21:40:00
--
local NetworkLog = require "network.NetworkLog"
local LogRichManActivity = class("LogRichManActivity", NetworkLog)

function LogRichManActivity:ctor()
    NetworkLog.ctor(self)
end

function LogRichManActivity:sendRichManPopupLog(type, page_name, entry_type)
    if not type or not page_name or not entry_type then
        return
    end

    local log_data = {}
    log_data.tp = type
    log_data.pn = page_name
    log_data.et = entry_type
    local _richManData = G_GetMgr(ACTIVITY_REF.RichMan):getRunningData()
    if _richManData == nil or _richManData:isRunning() == false then
        return
    end
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    log_data.en = entryData.entryName
    log_data.eo = entryData.entryOpen

    log_data.name = "RichMan" .. self:formatActivityTime(_richManData.p_start)
    local curTime = globalData.userRunData.p_serverTime / 1000
    local endTime = _richManData:getExpireAt()
    log_data.day = math.ceil((curTime - util_getymd_time(_richManData.p_start)) / 86400) -- 天数向上取整
    log_data.s = _richManData.sequence
    log_data.rd = _richManData.energy.rewardId
    gL_logData:syncEventData("RichmanPopup")
    gL_logData.p_data = log_data
    -- globalPlatformManager:checkSendFireBaseLog(log_data) -- firebase日志没有加 咱不确定是否需要
    self:sendLogData()
end

function LogRichManActivity:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end

return LogRichManActivity
