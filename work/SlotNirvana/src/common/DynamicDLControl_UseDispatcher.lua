-- Created by jfwang on 2019-05-05.
-- 动态下载控制器
--
-- ios fix
local BaseDLControl = require("common.BaseDLControl")
local DynamicDLControl_UseDispatcher = class("DynamicDLControl_UseDispatcher", BaseDLControl)

function DynamicDLControl_UseDispatcher:initData()
    DynamicDLControl_UseDispatcher.super.initData(self)
    self.m_dispatcherdownloadComplete_Unzip = {}
end 

function DynamicDLControl_UseDispatcher:purge()
    self:clearData()
end

function DynamicDLControl_UseDispatcher:initDynamicConfig()
    self:checkLocalDynamicDir()
end

--请求服务器，获取需要下载内容
function DynamicDLControl_UseDispatcher:getServerConfig()
    local data = globalData.GameConfig:getActivityNeedDownload()
    if data and #data > 1 then
        data = table_unique(data, true)
    end
    return data
end


--[[
    @desc: 
    author:{author}
    time:2021-09-26 20:05:09
    --@dlPos: 下载入口
	--@vType: 资源队列
    @return:
]]
function DynamicDLControl_UseDispatcher:startDownload(dlPos, vType)
    self.m_downloadQueue:clear()
    self.curPer = 0

    local levelNodeQueue = {}

    if type(vType) == "table" then
        for i = 1, #vType do
            local _dyQueue = {}
            local _lvQueue = {}
            _dyQueue, _lvQueue = self:createDLQueue(dlPos, vType[i])
            for i = 1, #_dyQueue, 1 do
                self.m_downloadQueue:push(_dyQueue[i])
            end

            if #_lvQueue > 0 then
                table.insertto(levelNodeQueue, _lvQueue)
            end
        end
    elseif type(vType) == "number" then
        local _dyQueue = {}
        local _lvQueue = {}
        _dyQueue, _lvQueue = self:createDLQueue(dlPos, vType)
        for i = 1, #_dyQueue, 1 do
            self.m_downloadQueue:push(_dyQueue[i])
        end

        if #_lvQueue > 0 then
            table.insertto(levelNodeQueue, _lvQueue)
        end
    else
        return
    end

    if #levelNodeQueue > 0 then
        globalLevelNodeDLControl:startDownload(vType, levelNodeQueue)
    end

    DynamicDLControl_UseDispatcher.super.startDownload(self)
end


-- 生成下载队列
function DynamicDLControl_UseDispatcher:createDLQueue(dlPos, resType)
    local dlQueue = {}
    local levelQueue = {}
    local nType = tonumber(resType)
    dlQueue = clone(self.m_dyZips[tostring(resType)] or {})

    for i = #dlQueue, 1, -1 do
        local _info = dlQueue[i]
        local isIgnoreZips = (nType == 0) and globalData.GameConfig:checkNewPlayerIgnoreZip(_info.key)
        if self:isDownLoad(_info.key, _info.md5) == 2 or isIgnoreZips then
            table.remove(dlQueue, i)
        else
            if self:isLevelEnterNode(_info) and dlPos == 1 then
                table.remove(dlQueue, i)
                table.insert(levelQueue, 1, _info)
            end
        end
    end

    return dlQueue, levelQueue
end


--是否开始下载
function DynamicDLControl_UseDispatcher:IsAdvPercent()
    if self.m_downLoadCount == 0 then
        return false
    end

    return true
end

--下载总进度
function DynamicDLControl_UseDispatcher:getAdvPercent()
    local count = table.nums(self.unzipMap)
    if self.m_downLoadCount == 0 or count == 0 then
        return 100
    end
    local per = self:getCurUnzipCount() * 100 / count
    if per > self.curPer then
        self.curPer = per
    end
    return self.curPer
end

function DynamicDLControl_UseDispatcher:isWorking()
    return not not self.m_downLoadInfo 
end

function DynamicDLControl_UseDispatcher:getPercent()
    if self.m_downLoadInfo then
        return self.m_downLoadInfo.percent
    end
    return 0
end

function DynamicDLControl_UseDispatcher:setDispatcherDownloadFunc(func)
    self.m_dispatcherDownloadFunc = func
end


function DynamicDLControl_UseDispatcher:doDispatcherDownload()
    if  self.m_dispatcherDownloadFunc then
        self.m_dispatcherDownloadFunc()
    end
end

function DynamicDLControl_UseDispatcher:onDownload()
    self:doDispatcherDownload()
end

function DynamicDLControl_UseDispatcher:checkOnDownload()
    DynamicDLControl_UseDispatcher.super.checkOnDownload(self)
end

function DynamicDLControl_UseDispatcher:checkDownLoad(info)
    DynamicDLControl_UseDispatcher.super.checkDownLoad(self, info)
    if info ~= nil then
        local dynamicData = nil
        if globalData.GameConfig.dynamicData then
            dynamicData = {Dynamic = globalData.GameConfig.dynamicData}
        -- else
        --     dynamicData = util_checkJsonDecode(GD_DynamicName)
        end
        if dynamicData ~= nil and dynamicData.Dynamic ~= nil then
            for k, v in pairs(dynamicData.Dynamic) do
                if info.type == "1" and v.zipName == info.key then
                    self:sendDownloadLog("Start", nil, v.reset ~= nil and "Pre" or "Normal", info.key, info.size)
                    break
                end
            end
        end
    end
end

--解压完成
function DynamicDLControl_UseDispatcher:completeUnZip(url)
    local downLoadInfo = self:getUnzipInfo(url)
    if downLoadInfo ~= nil then
        self.m_dispatcherdownloadComplete_Unzip[downLoadInfo.key] = 1
        local showMsg = string.format("UNCOMPRESS %s SUCCESS", downLoadInfo.key)
        print(showMsg)
        release_print(showMsg)

        self:setVersion(downLoadInfo.key, downLoadInfo.md5)
        self:pushPercent(downLoadInfo.key, 2)
        --发送某块下载成功消息，谁需要谁接收
        gLobalNoticManager:postNotification(downLoadInfo.key)
        --设置下载完成打点日志
        if gLobalSendDataManager:getLogGameLoad().setDownLoadInfo then
            gLobalSendDataManager:getLogGameLoad():setDownLoadInfo(downLoadInfo)
        end
    end
    self:checkOnDownload()
    self:doCompleteUnZipCheck()
end


function DynamicDLControl_UseDispatcher:setCompleteUnZipCheck(checkFun)
    self.m_completeUnZipCheckFun = checkFun
end

function DynamicDLControl_UseDispatcher:doCompleteUnZipCheck()
    if self.m_completeUnZipCheckFun then
        self.m_completeUnZipCheckFun()
    end
end


--更新下载进度
function DynamicDLControl_UseDispatcher:notifyDownLoad(url, downType, data)
    local downLoadInfo = self:getUnzipInfo(url)
    if url ~= nil and downLoadInfo == nil then
        --url == nil 不需要解压屏蔽
        --downLoadInfo == nil 不是本类发起的跳过
        return
    end 
    if self.m_downLoadInfo == nil and downType ~= DownLoadType.DOWN_UNCOMPRESSED then
        self:doDispatcherDownload()
        return
    end
    --不是本队列的下载消息
    if self.m_downLoadInfo ~= nil and self.m_downLoadInfo.url ~= url and downType ~= DownLoadType.DOWN_UNCOMPRESSED then
        return
    end
    
    --解压失败尝试重新下载
    if downType == DownLoadType.DOWN_ERROR and data and data.errorEnum and data.errorEnum == DownErrorCode.UNCOMPRESS then
        self:unZipFailReDownLoad(url) --暂定解压失败 按照下载失败处理 会卡住当前线路
        return
    end

    if downType == DownLoadType.DOWN_ERROR then
        self:pushPercent(self.m_downLoadInfo.key, -1)

        if self.m_downLoadInfo.delegate ~= nil then
            self.m_downLoadInfo.delegate = nil
        else
            return
        end
        local showMsg = string.format("DOWN %s DOWN_ERROR", self.m_downLoadInfo.key)
        print(showMsg)
        release_print(showMsg)
        self.m_reDownLoadFlag = true
        -- 网络问题报错，5s后检查下载
        scheduler.performWithDelayGlobal(
            function()
                if self.m_downLoadInfo and self.m_downLoadInfo.key then
                    self:checkDownLoad(self.m_downLoadInfo)
                end
                self.m_reDownLoadFlag = nil
            end,
            5,
            "DOWN_ERROR"
        )
        --发送下载失败日志
        if gLobalSendDataManager:getLogGameLoad().sendLoadFailLog then
            gLobalSendDataManager:getLogGameLoad():sendLoadFailLog(self.m_downLoadInfo)
        end
        local logInfo = self:getDownloadLogInfoByURL(url)
        if logInfo ~= nil then
            self:sendDownloadLog("Finish", "Fail", logInfo.downType, logInfo.zipName, logInfo.zipSize)
        end
    elseif downType == DownLoadType.DOWN_PROCESS then
        if data and data.loadPercent then
            local curPercent = data.loadPercent
            curPercent = curPercent < 0.97 and curPercent or 0.97
            data.loadPercent = curPercent
            self.m_downLoadInfo.percent = data.loadPercent
            self:pushPercent(self.m_downLoadInfo.key, data.loadPercent)
        end
    elseif downType == DownLoadType.DOWN_SUCCESS then
        if self.m_downLoadInfo.delegate ~= nil then
            self.m_downLoadInfo.delegate = nil
        else
            return
        end

        local showMsg = string.format("DOWN %s SUCCESS", self.m_downLoadInfo.key)
        print(showMsg)
        release_print(showMsg)
        local downLoadInfo = self.m_downLoadInfo
        self.m_downLoadInfo = nil
        self:doDispatcherDownload()
    elseif downType == DownLoadType.DOWN_UNCOMPRESSED then
        -- 处理已下载字节
        self:disposeDlBytes(url)
        self.m_downLoadInfo = nil
        self:completeUnZip(url)
        local logInfo = self:getDownloadLogInfoByURL(url)
        if logInfo ~= nil then
            self:sendDownloadLog("Finish", "Success", logInfo.downType, logInfo.zipName, logInfo.zipSize)
        end
    end
end

function DynamicDLControl_UseDispatcher:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            logDownLoad:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
        end
    end
end

function DynamicDLControl_UseDispatcher:getDownloadLogInfoByURL(url)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            return logDownLoad:getDownloadLogInfoByURL(url)
        end
    end
    return nil
end


-- 获得下载进度
function DynamicDLControl_UseDispatcher:getALlDLBytes()
    local _progress = 0
    local _info = self.m_downLoadInfo
    if _info then
        local _size = _info.size or 0
        local _percent = _info.percent
        _progress = math.floor(_size * _percent)
    end
    local _dlBytes = self.m_curDlBytes + _progress
    return _dlBytes
end

--当前解压的数量
function DynamicDLControl_UseDispatcher:getCurUnzipCount()
    return table.nums(self.m_dispatcherdownloadComplete_Unzip)
end

--解压失败尝试重新下载
function DynamicDLControl_UseDispatcher:unZipFailReDownLoad(url)

    self:pushPercent(self.m_downLoadInfo.key, -1)
    if self.m_downLoadInfo.delegate ~= nil then
        self.m_downLoadInfo.delegate = nil
    else
        return
    end
    local showMsg = string.format("UNCOMPRESS ERROR key = %s ", self.m_downLoadInfo.key)
    print(showMsg)
    release_print(showMsg)
    self.m_reDownLoadFlag = true
    scheduler.performWithDelayGlobal(
        function()
            if self.m_downLoadInfo and self.m_downLoadInfo.key then
                self:checkDownLoad(self.m_downLoadInfo)
            end
            self.m_reDownLoadFlag = nil
        end,
        1,
        "UNCOMPRESS_ERROR"
    )
    --发送下载失败日志
    if gLobalSendDataManager:getLogGameLoad().sendLoadFailLog then
        gLobalSendDataManager:getLogGameLoad():sendLoadFailLog(self.m_downLoadInfo)
    end   
end

return DynamicDLControl_UseDispatcher
