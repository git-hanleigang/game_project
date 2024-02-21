--[[--
    关卡下载Log打点
]]
local NetworkLog = require "network.NetworkLog"
local LogGameLevelDL = class("LogGameLevelDL", NetworkLog)
function LogGameLevelDL:ctor()
    NetworkLog.ctor(self)
    self.m_infoList = {} -- 正在下载的关卡的字典
end

function LogGameLevelDL:sendLogMessage(...)
    local args = {...}
    -- 在这里组织你感兴趣的数据
    NetworkLog.sendLogData(self)
end
--初始化
function LogGameLevelDL:initDownloadLog(key, levelInfo)
    local info = {}
    local areaOrder = 0
    if levelInfo.p_firstOrder then
        areaOrder = levelInfo.p_firstOrder
    end
    info.order = levelInfo.p_showOrder
    info.areaOrder = areaOrder
    info.gameTag = self:getGameTag(levelInfo)
    self:setDownloadInfo(key, info)
end
--创建本次下载唯一标识
function LogGameLevelDL:createLoadSessionId(key)
    if not key then
        return
    end
    local platform = device.platform
    local id = nil
    if platform == "ios" then
        id = globalPlatformManager:getIDFV() or "ID"
    else
        id = globalPlatformManager:getAndroidID() or "ID"
    end
    local randomTag = xcyy.SlotsUtil:getMilliSeconds()
    local ssid = tostring(id) .. "_" .. "LogGameLevelDL_" .. key .. randomTag
    local levelNameCode = key .. "_Code"
    self:setDownloadInfo(key, {ssid = ssid})
    self:setDownloadInfo(levelNameCode, {ssid = ssid})
end
-- 外部调用接口 start ----------------------------------------------------------
--发送开始下载log
function LogGameLevelDL:sendStartDownloadLog(key, levelInfo)
    if not levelInfo then
        return
    end
    local nowt = os.time()
    self:initDownloadLog(key, levelInfo)
    local info = {}
    info.actionType = "Start"
    info.startTime = nowt
    info.start = util_chaneTimeFormat(nowt)
    info.status = 1
    self:setDownloadInfo(key, info)
    self:sendDownLoadLog(key)
end
--发送完成log
function LogGameLevelDL:sendFinishDownloadLog(key, status)
    local nowt = os.time()
    local info = self:getDownloadInfo(key)
    if not info then
        return
    end
    info.actionType = "Finish"
    info.overTime = nowt
    if not info.startTime then
        info.startTime = nowt
    end
    info.cost = info.overTime - info.startTime
    info["end"] = util_chaneTimeFormat(nowt)
    info.status = status
    self:sendDownLoadLog(key)
    self:clearDownloadInfo(key)
end
--需要的外部数据
--[[
        type = {normal,Hight,Quest}
        siteType = {RecommendedArea,RegularArea}
]]
--设置属性
function LogGameLevelDL:setDownloadInfo(levelName, info)
    if not self.m_infoList[levelName] then
        self.m_infoList[levelName] = {}
    end
    if info then
        for key, value in pairs(info) do
            self.m_infoList[levelName][key] = value
        end
    end
end
-- 外部调用接口 end   ----------------------------------------------------------
--下载相关log
function LogGameLevelDL:sendDownLoadLog(levelName)
    local messageData = self:copyDownloadInfo(levelName)
    gL_logData:syncUserData()
    gL_logData:syncEventData("GameDownload")
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.GameDownload)
    end
    gL_logData.p_data = messageData
    self:sendLogData()
    if DEBUG == 2 then
        local strData = cjson.encode(messageData)
        print("-----------------------LogGameLevelDL = " .. strData)
        release_print("-----------------------LogGameLevelDL = " .. strData)
    end
end
--刷新标签
function LogGameLevelDL:getGameTag(levelInfo)
    local str = ""
    if levelInfo.p_link then
        str = "Link|"
    end
    if levelInfo.p_Log then
        str = str .. levelInfo.p_Log
    end

    return str
end
--获取
function LogGameLevelDL:getDownloadInfo(levelName)
    return self.m_infoList[levelName]
end
--拷贝
function LogGameLevelDL:copyDownloadInfo(levelName)
    if self.m_infoList[levelName] then
        return clone(self.m_infoList[levelName])
    end
end
--清空
function LogGameLevelDL:clearDownloadInfo(levelName)
    self.m_infoList[levelName] = nil
end
return LogGameLevelDL
