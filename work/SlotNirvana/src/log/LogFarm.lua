-- 农场打点

local NetworkLog = require "network.NetworkLog"
local LogFarm = class("LogFarm", NetworkLog)

function LogFarm:ctor()
    NetworkLog.ctor(self)
end

function LogFarm:sendGuideLog(guideType, guideName, guideStatus, guideTrigger, guideId)
    -- 发送数据
    if guideType and guideName then
        local gameData = G_GetMgr(G_REF.Farm):getRunningData()
        if not gameData then
            return
        end

        local log_data = {}
        log_data.guideType = guideType
        log_data.guideStatus = guideStatus
        log_data.guideTrigger = guideTrigger
        log_data.guideId = guideId
        log_data.guideName = guideName
        log_data.status = 0
        gL_logData:syncEventData("FarmGuide")
        gL_logData.p_data = log_data
        self:sendLogData()
    end
end

function LogFarm:sendPageLog(pageName, pageOpenType)
    assert(pageName, " !! pageName is nil !! ")
    assert(pageOpenType, " !! pageOpenType is nil !! ")
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    local enterType = entryData.entryType
    local entryName = entryData.entryName
    local entryOpen = entryData.entryOpen

    -- 发送数据
    if enterType and entryName and entryOpen then
        local gameData = G_GetMgr(G_REF.Farm):getRunningData()
        if not gameData then
            return
        end

        local log_data = {}
        local info = gameData:getInfo()
        log_data.tp = pageOpenType
        log_data.name = "Farm"
        log_data.lv = info.p_level
        log_data.pn = pageName
        log_data.et = enterType
        log_data.en = entryName
        log_data.eo = entryOpen
        gL_logData:syncEventData("FarmPage")
        gL_logData.p_data = log_data
        self:sendLogData()
    end
end

return LogFarm
