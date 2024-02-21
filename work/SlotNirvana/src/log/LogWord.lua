-- 集字活动打点

local NetworkLog = require "network.NetworkLog"
local LogWord = class("LogWord", NetworkLog)

function LogWord:ctor()
    NetworkLog.ctor(self)
end

function LogWord:sendPageLog(pageName, pageOpenType, entryType)
    assert(pageName, " !! pageName is nil !! ")
    assert(pageOpenType, " !! pageOpenType is nil !! ")
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    local enterType = entryData.entryType
    local entryName = entryData.entryName
    local entryOpen = entryData.entryOpen

    -- 发送数据
    if enterType and entryName and entryOpen then
        local gameData = G_GetMgr(ACTIVITY_REF.Word):getRunningData()
        if not gameData then
            return
        end

        local log_data = {}
        log_data.tp = pageOpenType
        log_data.name = "Word" .. self:formatActivityTime(gameData.p_start)
        local curTime = globalData.userRunData.p_serverTime / 1000
        local endTime = gameData:getExpireAt()
        log_data.day = math.ceil((curTime - util_getymd_time(gameData.p_start)) / 86400) -- 天数向上取整
        log_data.s = tonumber(gameData:getSequence()) -- 活动轮数
        log_data.rd = gameData:getCurrent() -- 第几关
        log_data.pn = pageName
        log_data.et = enterType
        log_data.en = entryName
        log_data.eo = entryOpen
        gL_logData:syncEventData("WordPopup")
        gL_logData.p_data = log_data
        self:sendLogData()
    end
end

function LogWord:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end

return LogWord
