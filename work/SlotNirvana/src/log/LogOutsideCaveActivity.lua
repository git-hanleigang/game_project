-- 集字活动打点

local NetworkLog = require "network.NetworkLog"
local LogOutsideCaveActivity = class("LogOutsideCaveActivity", NetworkLog)

function LogOutsideCaveActivity:ctor()
    NetworkLog.ctor(self)
end

function LogOutsideCaveActivity:sendPopUpLog(pageName, pageOpenType, entryType)
    assert(pageName, " !! pageName is nil !! ")
    assert(pageOpenType, " !! pageOpenType is nil !! ")
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    local enterType = entryData.entryType
    local entryName = entryData.entryName
    local entryOpen = entryData.entryOpen

    -- 发送数据
    if enterType and entryName and entryOpen then
        local gameData = G_GetMgr(ACTIVITY_REF.OutsideCave):getRunningData()
        if not gameData then
            return
        end

        local log_data = {}
        log_data.tp = pageOpenType
        log_data.name = "OutsideCave" .. self:formatActivityTime(gameData.p_start)
        local curTime = globalData.userRunData.p_serverTime / 1000
        local endTime = gameData:getExpireAt()
        log_data.day = math.ceil((curTime - util_getymd_time(gameData.p_start)) / 86400) -- 天数向上取整
        log_data.s = tonumber(gameData:getRound()) -- 活动轮数
        log_data.rd = gameData:getStage() -- 第几关
        log_data.pn = pageName
        log_data.et = enterType
        log_data.en = entryName
        log_data.eo = entryOpen
        gL_logData:syncEventData("OutsideCavePopup")
        gL_logData.p_data = log_data
        self:sendLogData()
    end
end

function LogOutsideCaveActivity:sendSpinLog(_spinType, _spinNum)
    -- 发送数据
    local gameData = G_GetMgr(ACTIVITY_REF.OutsideCave):getRunningData()
    if not gameData then
        return
    end

    local log_data = {}
    log_data.tp = pageOpenType
    log_data.name = "OutsideCave" .. self:formatActivityTime(gameData.p_start)
    local curTime = globalData.userRunData.p_serverTime / 1000
    local endTime = gameData:getExpireAt()
    -- 天数向上取整
    log_data.day = math.ceil((curTime - util_getymd_time(gameData.p_start)) / 86400) 
    -- 活动轮数
    log_data.s = tonumber(gameData:getRound())
    -- 第几关
    log_data.rd = gameData:getStage()
    -- 如果是auto，界面关闭时累计次数
    log_data.n = _spinNum 
    -- auto自动，alone手动spin
    log_data.psts = _spinType 
    gL_logData:syncEventData("OutsideCaveSpin")
    gL_logData.p_data = log_data
    self:sendLogData()
end

function LogOutsideCaveActivity:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end

return LogOutsideCaveActivity
