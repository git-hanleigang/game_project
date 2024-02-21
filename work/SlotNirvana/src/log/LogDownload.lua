--[[
    @desc: 
    author:JohnnyFred
    time:2021-08-16 15:12:34
]]
local NetworkLog = require "network.NetworkLog"
local LogDownload = class("LogDownload", NetworkLog)

function LogDownload:ctor()
    LogDownload.super.ctor(self)
    self.downloadInfoMap = {}
end

function LogDownload:sendDownloadLog(eventType,downStatus,downType,zipName,zipSize)
    local downloadInfoMap = self.downloadInfoMap
    local curTime = xcyy.SlotsUtil:getMilliSeconds()
    local platform = device.platform
    local id = nil
    if platform == "ios" then
        id = (globalPlatformManager ~= nil and globalPlatformManager.getIDFV ~= nil) and globalPlatformManager:getIDFV() or "ID"
    else
        id = (globalPlatformManager ~= nil and globalPlatformManager.getAndroidID ~= nil) and globalPlatformManager:getAndroidID() or "ID"
    end
    local info = downloadInfoMap[zipName] or 
    {
        ssid = tostring(id) .. "_" .. "download_" .. curTime,
        zipName = zipName,
        curTime = curTime,
        downType = downType,
        zipSize = zipSize
    }
    local isFinish = eventType == "Finish"
    if isFinish then
        info.cost = curTime - info.curTime
    end
    downloadInfoMap[zipName] = info
    gL_logData:syncUserData()
    gL_logData:syncEventData("DynamicUpdate")
    gL_logData.p_data = 
    {
        type = eventType,
        ssid = info.ssid,
        status = downStatus,
        downType = downType,
        name = zipName,
        zipSize = zipSize,
        cost = info.cost
    }
    self:sendLogData()
    if isFinish then
        downloadInfoMap[zipName] = nil
    end
end

function LogDownload:getDownloadLogInfoByURL(url)
    if self.downloadInfoMap ~= nil then
        for k,v in pairs(self.downloadInfoMap) do
            local findIndex = string.find(url,v.zipName)
            if findIndex ~= nil and findIndex > 0 then
                return v
            end
        end
    end
    return nil
end
return LogDownload
