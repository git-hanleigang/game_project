--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-08 19:48:52
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-08 19:48:59
FilePath: /SlotNirvana/src/common/ExpandSysDLControl.lua
Description: 扩圈系统 游戏内下载
--]]
local BaseDLControl = require("common.BaseDLControl")
local ExpandSysDLControl = class("ExpandSysDLControl", BaseDLControl)
function ExpandSysDLControl:getInstance()
    if self._instance == nil then
        self._instance = ExpandSysDLControl:create()
        self._instance:initData()
    end
    return self._instance
end

function ExpandSysDLControl:purge()
    self:clearData()
end

function ExpandSysDLControl:downloadExpandRes(_dlZips)
    if not CC_DYNAMIC_DOWNLOAD then
        return
    end

    if not _dlZips or #_dlZips <= 0 then
        return
    end

    if not self.m_downloadQueue:empty() then
        return
    end

    for _, info in pairs(_dlZips) do
        self.m_downloadQueue:push(info)
    end
    self:startDownload()
end

function ExpandSysDLControl:unZipCompleted(downLoadInfo)
    ExpandSysDLControl.super.unZipCompleted(self, downLoadInfo)
    if self.m_downloadQueue:empty() then
       G_GetMgr(G_REF.NewUserExpand):downloadOver()
    end
end

-------------------- 打点 --------------------
function ExpandSysDLControl:checkDownLoad(info)
    ExpandSysDLControl.super.checkDownLoad(self, info)

    if info ~= nil then
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
end

function ExpandSysDLControl:notifyDownLoad(url, downType, data)
    ExpandSysDLControl.super.notifyDownLoad(self, url, downType, data)
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

function ExpandSysDLControl:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            logDownLoad:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
        end
    end
end

function ExpandSysDLControl:getDownloadLogInfoByURL(url)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            return logDownLoad:getDownloadLogInfoByURL(url)
        end
    end
    return nil
end
-------------------- 打点 --------------------

return ExpandSysDLControl
