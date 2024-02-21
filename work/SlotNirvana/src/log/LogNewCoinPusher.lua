--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-07-29 19:43:26
]]
local NetworkLog = require "network.NetworkLog"
local LogNewCoinPusher = class("LogNewCoinPusher", NetworkLog)
-- FIX IOS 139
function LogNewCoinPusher:ctor()
    NetworkLog.ctor(self)
end

function LogNewCoinPusher:sendCoinPusherPopupLog(type, page_name, entry_type)
    if not type or not page_name or not entry_type then
        return
    end

    local _CoinPusherData = G_GetMgr(ACTIVITY_REF.NewCoinPusher):getRunningData()

    if _CoinPusherData == nil or _CoinPusherData:isRunning() == false then
        return
    end

    local curTime = globalData.userRunData.p_serverTime / 1000
    local endTime = _CoinPusherData:getExpireAt()

    local log_data = {}
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}

    log_data.name = "NewCoinPusher" .. self:formatActivityTime(_CoinPusherData.p_start)
    log_data.day = math.ceil((curTime - util_getymd_time(_CoinPusherData.p_start)) / 86400) -- 天数向上取整
    log_data.s = _CoinPusherData:getRound()
    log_data.rd = _CoinPusherData:getStage()
    log_data.pn = page_name
    log_data.et = entry_type
    log_data.en = entryData.entryName
    log_data.eo = entryData.entryOpen
    log_data.tp = type

    gL_logData:syncEventData("NewPusherPopup")
    gL_logData.p_data = log_data
    self:sendLogData()
end

function LogNewCoinPusher:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end

return LogNewCoinPusher
