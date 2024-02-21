-- Created by jfwang on 2019-05-05.
-- 下载逻辑处理
-- ios fix
local LuaList = require("common.LuaList")
local BaseDLControl = class("BaseDLControl")

--解压映射表{[url] = {key = "",url = "",md5 = "",percent = 1}}
function BaseDLControl:ctor()
    self.unzipMap = nil
end

function BaseDLControl:pushUnzipInfo(url, info)
    self.unzipMap[url] = info
end

function BaseDLControl:getUnzipInfo(url)
    return url ~= nil and self.unzipMap[url] or nil
end

--进入游戏开启下载队列，直到队列为空
function BaseDLControl:initData()
    self.m_downLoadInfo = nil
    self.m_downloadQueue = LuaList.new()
    self.m_downloadComplete = {}
    self.unzipMap = {}
    self.m_downLoadCount = 0

    -- 总下载字节数
    self.m_totalDlBytes = 0
    -- 当前已下载字节数
    self.m_curDlBytes = 0
    --注册事件
    self:registerDownLoadHandler()

    self.m_luaNameString = ""
end

function BaseDLControl:clearData()
    gLobalNoticManager:removeAllObservers(self)

    self.m_downloadComplete = nil
    self.m_downloadQueue = nil
    self.m_downLoadInfo = nil
    self.m_downLoadCount = 0
    -- 总下载字节数
    self.m_totalDlBytes = 0
    -- 当前已下载字节数
    self.m_curDlBytes = 0
    self.m_luaNameString = ""
end

function BaseDLControl:initQueue(vType)
end

--开始后台下载 vType 下载位置 0：loading时 1：后台下载 2：主动点击下载
function BaseDLControl:startDownload(vType)
    -- self:initQueue(vType)

    self.m_downLoadCount = self.m_downloadQueue:getListCount()
    local downloadQueueClone = clone(self.m_downloadQueue)
    local downloadComplete = self.m_downloadComplete
    if downloadComplete ~= nil then
        while not downloadQueueClone:empty() do
            local info = downloadQueueClone:pop()
            if info ~= nil then
                downloadComplete[info.key] = info
            end
        end
    end
    -- 初始化要下载的总字节数
    self:initDlBytes()
    self:onDownload()
end

-- 初始化下载字节数
function BaseDLControl:initDlBytes()
    self.m_curDlBytes = 0
    self.m_totalDlBytes = 0
    local _list, _start, _end = self.m_downloadQueue:getList()
    for index = _start, _end do
        local _info = _list[index]
        if _info then
            self.m_totalDlBytes = self.m_totalDlBytes + (_info.size or 0)
        end
    end
end

-- 处理已下载的字节
function BaseDLControl:disposeDlBytes(url)
    local _size = 0
    local _info = self:getUnzipInfo(url)
    if _info then
        _size = _info.size or 0
    end

    self.m_curDlBytes = self.m_curDlBytes + _size
end

--后台下载逻辑
function BaseDLControl:onDownload()
    if self.m_downloadQueue:empty() then
        return
    end

    local info = self.m_downloadQueue:pop()
    if info ~= nil then
        self:checkDownLoad(info)
    end
end

function BaseDLControl:checkDownLoad(info)
    local key = info.key
    local md5 = info.md5
    local _size = info.size
    local ret = self:isDownLoad(key, md5)
    if ret ~= 2 then
        -- 开始开始下载
        local data = globalData.GameConfig:checkABTestData(key)
        local url = nil
        local downInfo = nil
        if data then
            --如果存在abtest 修改下载地址
            url = string.format("%s%s_%s.zip", DYNAMIC_DOWNLOAD_URL, key, data.groupKey)
            downInfo = {key = key, url = url, md5 = data.md5, percent = 0.01, size = _size, dl = ret}
        else
            url = string.format("%s%s.zip", DYNAMIC_DOWNLOAD_URL, key)
            downInfo = {key = key, url = url, md5 = md5, percent = 0.01, size = _size, dl = ret}
        end

        local downLoadDelegate = self:beginDownLoad(url, key)
        downInfo.delegate = downLoadDelegate
        -- end
        self.m_downLoadInfo = downInfo
        --记录开始时间
        downInfo.startTime = xcyy.SlotsUtil:getMilliSeconds()
        self:pushUnzipInfo(url, downInfo)

        --打印下载资源
        if self.m_downLoadInfo and self.m_downLoadInfo.key then
            if data and data.groupKey then
                release_print("checkDownLoad name = " .. self.m_downLoadInfo.key .. " group = " .. data.groupKey)
            else
                release_print("checkDownLoad name = " .. self.m_downLoadInfo.key)
            end
        end
    else
        self:onDownload()
    end
end

--是否已经下载过
function BaseDLControl:isDownLoad(key, md5)
    --如果存在abtest使用 abtest中的md5值计算
    local data = globalData.GameConfig:checkABTestData(key)
    if data then
        md5 = data.md5
    end

    local oldMd5 = self:getVersion(key)
    if oldMd5 and oldMd5 == md5 then
        return 2
    elseif oldMd5 and oldMd5 ~= md5 then
        return 1
    else
        return 0
    end
end

-- 需要下载的资源总数
function BaseDLControl:getDLCount()
    return self.m_downLoadCount
end

--当前解压的数量
function BaseDLControl:getCurUnzipCount()
    return self.m_downloadComplete ~= nil and self:getDLCount() - table.nums(self.m_downloadComplete) or 0
end

function BaseDLControl:getPercentForKey(key)
    if not key then
        return 0
    end
    if self.m_downLoadInfo and self.m_downLoadInfo.key == key then
        return self.m_downLoadInfo.percent
    end
    return 0
end

function BaseDLControl:getPercent()
    if self.m_downLoadInfo then
        return self.m_downLoadInfo.percent
    end

    return 1
end

-- 获得下载进度
function BaseDLControl:getDLProgress()
    local _progress = 0
    local _info = self.m_downLoadInfo
    if _info then
        local _size = _info.size or 0
        local _percent = _info.percent
        _progress = math.floor(_size * _percent)
    end
    local _dlBytes = self.m_curDlBytes + _progress
    if self.m_totalDlBytes > 0 then
        return self:getDlTxt(_dlBytes) .. "/" .. self:getDlTxt(self.m_totalDlBytes)
    else
        return ""
    end
end

--刷新下载进度
function BaseDLControl:pushPercent(key, value)
    gLobalNoticManager:postNotification("DL_Percent" .. key, value)
    if value > 1 then
        -- release_print(" ----- self.kPercentBroadMsgMap[key] DL_Complete --- ", key, value)
        gLobalNoticManager:postNotification("DL_Complete" .. key, value)
    end
end

--更新下载进度
function BaseDLControl:notifyDownLoad(url, downType, data)
    local downLoadInfo = self:getUnzipInfo(url)
    if url ~= nil and downLoadInfo == nil then
        --url == nil 不需要解压屏蔽
        --downLoadInfo == nil 不是本类发起的跳过
        return
    end
    --解压失败尝试重新下载
    if downType == DownLoadType.DOWN_ERROR and data and data.errorEnum and data.errorEnum == DownErrorCode.UNCOMPRESS then
        self:unZipFailReDownLoad(url)
        return
    end
    if self.m_downLoadInfo == nil and downType ~= DownLoadType.DOWN_UNCOMPRESSED then
        self:onDownload()
        return
    end
    --不是本队列的下载消息
    if self.m_downLoadInfo ~= nil and self.m_downLoadInfo.url ~= url and downType ~= DownLoadType.DOWN_UNCOMPRESSED then
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
        self:onDownload()
    elseif downType == DownLoadType.DOWN_UNCOMPRESSED then
        -- 处理已下载字节
        self:disposeDlBytes(url)
        self:completeUnZip(url)
    end
end
--解压失败尝试重新下载
function BaseDLControl:unZipFailReDownLoad(url)
    local downLoadInfo = self:getUnzipInfo(url)
    if downLoadInfo ~= nil then
        local showMsg = string.format("UNCOMPRESS ERROR key = %s ", downLoadInfo.key)
        print(showMsg)
        release_print(showMsg)
        if self.m_downloadQueue:empty() and self.m_reDownLoadFlag == nil then
            --下载队列为空也要延迟一秒重试
            scheduler.performWithDelayGlobal(
                function()
                    if downLoadInfo and downLoadInfo.key and self.checkDownLoad then
                        self:checkDownLoad(downLoadInfo)
                    end
                end,
                1,
                "UNCOMPRESS_ERROR"
            )
        else
            local data = {key = downLoadInfo.key, md5 = downLoadInfo.md5, size = downLoadInfo.size}
            self.m_downloadQueue:push(data)
            self:checkOnDownload()
        end
        --发送下载失败日志
        if gLobalSendDataManager:getLogGameLoad().sendLoadFailLog then
            gLobalSendDataManager:getLogGameLoad():sendLoadFailLog(downLoadInfo)
        end
    else
        local showMsg = "UNCOMPRESS ERROR url = nil"
        print(showMsg)
        release_print(showMsg)
    end
end
--获得版本号或者md5值
function BaseDLControl:getVersion(key)
    if not key then
        return
    end
    local md5 = ""
    if util_isSupportVersion("1.7.8", "ios") or util_isSupportVersion("1.8.6", "android") then
        md5 = gLobalDataManager:getVersion("dy_" .. key)
        -- if md5 == "" then
        --     md5 = gLobalDataManager:getStringByField("Dynamic_" .. key, "")
        --     if md5 ~= "" then
        --         -- release_print("--xy--find dynamic " .. key .. " res!!!")
        --         gLobalDataManager:setVersion("dy_" .. key, md5)
        --         gLobalDataManager:setStringByField("Dynamic_" .. key, "")
        --     end
        -- end
    else
        md5 = gLobalDataManager:getStringByField("Dynamic_" .. key, "")
    end
    if md5 ~= "" then
        return md5
    end
    return nil
end

--更新版本号或者md5值
function BaseDLControl:setVersion(key, md5)
    if not key then
        return
    end

    if util_isSupportVersion("1.7.8", "ios") or util_isSupportVersion("1.8.6", "android") then
        gLobalDataManager:setVersion("dy_" .. key, tostring(md5))
    else
        gLobalDataManager:setStringByField("Dynamic_" .. key, md5)
    end
end

--监听下载
function BaseDLControl:registerDownLoadHandler()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- 下载失败重置状态
            self:notifyDownLoad(params.url, DownLoadType.DOWN_ERROR, params)
        end,
        GlobalEvent.GEvent_LoadedError
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            --下载进度
            self:notifyDownLoad(params.url, DownLoadType.DOWN_PROCESS, params)
        end,
        GlobalEvent.GEvent_LoadedProcess
    )
    gLobalNoticManager:addObserver(
        self,
        function(target, url)
            --下载完成
            self:notifyDownLoad(url, DownLoadType.DOWN_SUCCESS)
        end,
        GlobalEvent.GEvent_LoadedSuccess
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, url)
            --解压完成
            self:notifyDownLoad(url, DownLoadType.DOWN_UNCOMPRESSED)
        end,
        GlobalEvent.GEvent_UncompressSuccess
    )
end

function BaseDLControl:beginDownLoad(url, key)
    if not url then
        return
    end
    key = key or ""
    CC_DOWNLOAD_TYPE = CC_DOWNLOAD_TYPE or 2 --默认值
    local showMsg = string.format("-----------------beginDownLoad downLoadType = %d url = %s", CC_DOWNLOAD_TYPE, url)
    -- print(showMsg)
    release_print(showMsg)
    -- if CC_DOWNLOAD_TYPE == 1 then
    --     --cocos2dx版本
    --     return xcyy.SlotsUtil:beginDownLoadEX(url)
    -- elseif CC_DOWNLOAD_TYPE == 2 then
    --     --最老的下载版本-修改解压部分
    --     return xcyy.SlotsUtil:beginDownLoadNew(url)
    -- elseif CC_DOWNLOAD_TYPE == 3 then
    --     --多线程版本
    --     return xcyy.SlotsUtil:beginDownLoad(url)
    -- else
    --     --最老的下载版本
    --     return xcyy.SlotsUtil:beginDownLoadOld(url)
    -- end
    if not util_isSupportVersion("1.9.1", "android") and not util_isSupportVersion("1.9.4", "ios") then
        return xcyy.SlotsUtil:beginDownLoadNew(url)
    else
        return xcyy.SlotsUtil:beginDownLoadNew(url, key)
    end
end
--解压完成
function BaseDLControl:completeUnZip(url)
    local downLoadInfo = self:getUnzipInfo(url)
    if downLoadInfo ~= nil then
        if self.m_downloadComplete ~= nil and table.nums(self.m_downloadComplete) > 0 then
            self.m_downloadComplete[downLoadInfo.key] = nil
        end
        local showMsg = string.format("UNCOMPRESS %s SUCCESS, zip size %s", tostring(downLoadInfo.key), tostring(downLoadInfo.size))
        print(showMsg)
        release_print(showMsg)

        self:setVersion(downLoadInfo.key, downLoadInfo.md5)
        self:pushPercent(downLoadInfo.key, 2)
        self:unZipCompleted(downLoadInfo)
        --发送某块下载成功消息，谁需要谁接收
        gLobalNoticManager:postNotification(downLoadInfo.key)
        --设置下载完成打点日志
        self:setDownLoadInfoLog(downLoadInfo)
    end
    self:checkOnDownload()
end

function BaseDLControl:unZipCompleted(downLoadInfo)
    if self.m_downloadQueue:empty() or (downLoadInfo and tostring(downLoadInfo.dl) == "1") then
        -- 列表下载完成 或 有已下载的旧资源，刷新搜索路径缓存
        cc.FileUtils:getInstance():purgeCachedEntries()
        -- release_print("==== xy == purgeCachedEntries key=" .. downLoadInfo.key .. " dl=" .. downLoadInfo.dl)
    end
end

-- 下载成功log
function BaseDLControl:setDownLoadInfoLog(downLoadInfo)
    if gLobalSendDataManager:getLogGameLoad().setDownLoadInfo then
        gLobalSendDataManager:getLogGameLoad():setDownLoadInfo(downLoadInfo)
    end
end

--是否执行后续下载
function BaseDLControl:checkOnDownload()
    local showMsg = string.format("-----------------checkOnDownload downLoadType = %d", CC_DOWNLOAD_TYPE)
    print(showMsg)
    release_print(showMsg)
    if CC_DOWNLOAD_TYPE ~= 3 then
        self:onDownload()
    end
end

function BaseDLControl:getDlTxt(bytes)
    local kBytes = tonumber(bytes) / 1024
    local mBytes = kBytes / 1024
    if mBytes >= 1 then
        return string.format("%.1f", mBytes) .. "M"
    elseif kBytes >= 1 then
        return string.format("%.1f", kBytes) .. "K"
    else
        return string.format("%.1f", bytes) .. "B"
    end
end

function BaseDLControl:getDownloadDelegate(key)
    local platform = device.platform
    if platform == "ios" or platform == "mac" then
        return xcyy.XCDownloadManager:getDownloadInfo(key)
    elseif platform == "android" then
        return xcyy.XCDownloadManager:getDownloadInfo(key)
    end
    return nil
end

function BaseDLControl:isDownloadInThread(key)
    local platform = device.platform
    if platform == "ios" or platform == "mac" then
        return xcyy.XCDownloadManager:isDownloading(key)
    elseif platform == "android" then
        return xcyy.XCDownloadManager:isDownloading(key)
    end
    return false
end
return BaseDLControl
