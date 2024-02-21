--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-05 11:28:23
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-05 11:30:43
FilePath: /SlotNirvana/src/common/SideKicksDLControl.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local BaseDLControl = require("common.BaseDLControl")
local SideKicksDLControl = class("SideKicksDLControl", BaseDLControl)
function SideKicksDLControl:getInstance()
    if self._instance == nil then
        self._instance = SideKicksDLControl:create()
        self._instance:initData()
    end
    return self._instance
end

function SideKicksDLControl:purge()
    self:clearData()
end

function SideKicksDLControl:downloadSeasonRes(_dlZips)
    if not CC_DYNAMIC_DOWNLOAD then
        return
    end

    if not _dlZips or #_dlZips <= 0 then
        return
    end

    for _, info in pairs(_dlZips) do
        self.m_downloadQueue:push(info)
    end
    self:startDownload()
end

-------------------- 打点 --------------------
function SideKicksDLControl:checkDownLoad(info)
    SideKicksDLControl.super.checkDownLoad(self, info)

    local key = info.key
    local md5 = info.md5
    local ret = self:isDownLoad(key, md5)
    if ret == 2 then
        -- 已经下载过了
        return
    end

    local dynamicData = nil
    if globalData.GameConfig.dynamicData then
        dynamicData = {Dynamic = globalData.GameConfig.dynamicData}
    end
    if dynamicData ~= nil and dynamicData.Dynamic ~= nil then
        for k, v in pairs(dynamicData.Dynamic) do
            if v.zipName == info.key then
                self:sendDownloadLog("Start", nil, v.reset ~= nil and "Pre" or "Normal", info.key, info.size)
                break
            end
        end
    end
end

function SideKicksDLControl:notifyDownLoad(url, downType, data)
    SideKicksDLControl.super.notifyDownLoad(self, url, downType, data)
    if downType == DownLoadType.DOWN_UNCOMPRESSED then
        local logInfo = self:getDownloadLogInfoByURL(url)
        if logInfo ~= nil then
            self:sendDownloadLog("Finish", "Success", logInfo.downType, logInfo.zipName, logInfo.zipSize)
        end
    elseif downType == DownLoadType.DOWN_ERROR then
        local logInfo = self:getDownloadLogInfoByURL(url)
        if logInfo ~= nil then
            self:sendDownloadLog("Finish", "Fail", logInfo.downType, logInfo.zipName, logInfo.zipSize)
        end
    end
end

function SideKicksDLControl:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            logDownLoad:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
        end
    end
end

function SideKicksDLControl:getDownloadLogInfoByURL(url)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            return logDownLoad:getDownloadLogInfoByURL(url)
        end
    end
    return nil
end
-------------------- 打点 --------------------

return SideKicksDLControl
