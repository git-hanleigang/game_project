local LevelDLControl = class("LevelDLControl")
-- ios fix
-- 主题下载列表
LevelDLControl.m_downLoadInfos = nil

function LevelDLControl:ctor()
    self.m_downLoadInfos = {}
    self:registerDownLoadHandler()
end
function LevelDLControl:purge()
    gLobalNoticManager:removeAllObservers(self)
    self.m_downLoadInfos = nil
end

--下载主题
function LevelDLControl:checkDownLoadLevel(info)
    local key = info.p_levelName
    local md5 = info.p_md5

    if key and key ~= "" then
        local machineDirPath = device.writablePath .. key .. "/"
        if cc.FileUtils:getInstance():isDirectoryExist(machineDirPath) then
            --如果存在删除文件夹
            cc.FileUtils:getInstance():removeDirectory(machineDirPath)
            cc.FileUtils:getInstance():purgeCachedEntries()
        -- util_sendToSplunkMsg("removeDir", "RemoveLevelCache:levelName=" .. key)
        end
    else
        md5 = tostring(md5)
        key = tostring(key)
        local strLog = "checkDownLoadLevel error  key == " .. key .. " md5 = " .. md5
        if strLog and gLobalSendDataManager and gLobalSendDataManager.getLogGameLoad and gLobalSendDataManager:getLogGameLoad().sendErrorDirectoryLog then
            gLobalSendDataManager:getLogGameLoad():sendErrorDirectoryLog("downloadInfo", strLog)
        end
        return
    end

    -- 开始开始下载
    local data = globalData.GameConfig:checkABTestData(key)
    local url = nil
    local downInfo = nil
    if data then
        --如果关卡存在abtest 修改下载地址
        url = string.format("%s%s_%s.zip", LEVELS_ZIP_URL, key, data.groupKey)
        downInfo = {key = key, url = url, md5 = data.md5, info = info, percent = 0.01}
    else
        url = string.format("%s%s.zip", LEVELS_ZIP_URL, key)
        downInfo = {key = key, url = url, md5 = md5, info = info, percent = 0.01}
    end

    if key then
        release_print("checkDownLoad Level name = " .. key)
    end

    if not self:isURLDownloading(url) then
        -- if self.isDownloadInThread ~= nil and self:isDownloadInThread(url) then
        --     downInfo.delegate = self:getDownloadDelegate(url)
        -- else
        local downLoadDelegate = self:beginDownLoad(url, key)
        downInfo.delegate = downLoadDelegate
        -- end
        table.insert(self.m_downLoadInfos, downInfo)
        self:setDownloadInfo(downInfo.info, "Resource")
    end
end

function LevelDLControl:isURLDownloading(url)
    local m_downLoadInfos = self.m_downLoadInfos
    --处于下载中的 防止重复下载
    for i = 1, #m_downLoadInfos do
        if url == m_downLoadInfos[i].url then
            return true
        end
    end
    return false
end

function LevelDLControl:checkDownLoadLevelCode(_info)
    local levelName = _info.p_levelName
    local key = levelName .. "_Code"
    local codemd5 = _info.p_codemd5
    local url = string.format("%s%s.zip", LEVELS_ZIP_URL, key)
    local downInfo = {key = key, url = url, md5 = codemd5, percent = 0.01}

    if not self:isURLDownloading(url) then
        -- if self.isDownloadInThread ~= nil and self:isDownloadInThread(url) then
        --     downInfo.delegate = self:getDownloadDelegate(url)
        -- else
        local downLoadDelegate = self:beginDownLoad(url, key)
        downInfo.delegate = downLoadDelegate
        -- end
        table.insert(self.m_downLoadInfos, downInfo)
        self:setDownloadInfo(_info, "Code")
    end
end
--设置下载信息
function LevelDLControl:setDownloadInfo(downInfo, downType)
    if not downInfo then
        return
    end
    local levelName = downInfo.p_levelName or "nil"
    if downType == "Code" then
        levelName = levelName .. "_Code"
    end
    local size = downInfo.p_bytesSize or 1
    local zipName = levelName .. ".zip"
    local info = {
        size = size,
        downType = downType,
        name = zipName,
        game = downInfo.p_name
    }
    if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL then
        gLobalSendDataManager:getLogGameLevelDL():setDownloadInfo(levelName, info)
        gLobalSendDataManager:getLogGameLevelDL():sendStartDownloadLog(levelName, downInfo)
    end
end

--这里是测试下载代码
function LevelDLControl:testDownLoad(url)
    local index = 1
    local scheduler = cc.Director:getInstance():getScheduler()
    self.schedulerID =
        scheduler:scheduleScriptFunc(
        function()
            if index > 100 then
                scheduler:unscheduleScriptEntry(self.schedulerID)
                self.schedulerID = nil
                return
            end
            index = index + 1
            if index >= 100 then
                gLobalNoticManager:postNotification(GlobalEvent.GEvent_LoadedSuccess, url)
            else
                gLobalNoticManager:postNotification(GlobalEvent.GEvent_LoadedProcess, {url = url, loadPercent = index * 0.01})
            end
        end,
        0.1,
        false
    )
end

-- 主题是否下载 0未下载 1已下载未更新 2已下载已更新
function LevelDLControl:isDownLoadLevel(_info)
    local key = _info.p_levelName
    local md5 = _info.p_md5
    if CC_IS_READ_DOWNLOAD_PATH == false then -- 不走下载直接打到了包里
        return 2
    end

    --如果关卡存在abtest使用 abtest中的md5值计算
    local data = globalData.GameConfig:checkABTestData(key)
    if data then
        md5 = data.md5
    end

    local oldMd5 = self:getVersion(key)
    if oldMd5 and oldMd5 == md5 then
        local machineDirPath = device.writablePath .. key .. "/"
        if not cc.FileUtils:getInstance():isDirectoryExist(machineDirPath) then
            --文件夹找不到已经被删除重置md5
            self:setVersion(key, "")
            return 0
        end
        return 2
    elseif oldMd5 and oldMd5 ~= md5 then
        local machineDirPath = device.writablePath .. key .. "/"
        if not cc.FileUtils:getInstance():isDirectoryExist(machineDirPath) then
            --文件夹找不到已经被删除重置md5
            -- self:setVersion(key, "")
            return 0
        end
        return 1
    else
        return 0
    end
end

--检测关联的代码是否下载好
function LevelDLControl:isDownLoadLevelCode(_info)
    local levelName = _info.p_levelName
    local key = levelName .. "_Code"
    local codemd5 = _info.p_codemd5
    if CC_IS_READ_DOWNLOAD_PATH == false then -- 不走下载直接打到了包里
        return 2
    end
    local oldMd5 = self:getVersion(key)
    if oldMd5 and oldMd5 == codemd5 then
        local machineDirPath = device.writablePath .. "GameLevelCode/" .. levelName
        if not cc.FileUtils:getInstance():isDirectoryExist(machineDirPath) then
            --文件夹找不到已经被删除重置md5
            self:setVersion(key, "")
            return 0
        end
        return 2
    elseif oldMd5 and oldMd5 ~= codemd5 then
        local machineDirPath = device.writablePath .. "GameLevelCode/" .. levelName
        if not cc.FileUtils:getInstance():isDirectoryExist(machineDirPath) then
            --文件夹找不到已经被删除重置md5
            self:setVersion(key, "")
            return 0
        end
        return 1
    else
        return 0
    end
end

-- Free
function LevelDLControl:isUpdateFreeOpenLevel(key, md5)
    if CC_IS_READ_DOWNLOAD_PATH == false then -- 不走下载直接打到了包里
        return false
    end

    --如果关卡存在abtest使用 abtest中的md5值计算
    local data = globalData.GameConfig:checkABTestData(key)
    if data then
        md5 = data.md5
    end

    local oldMd5 = self:getVersion(key)
    if not oldMd5 or oldMd5 == "" then
        -- 不存在MD5；说明是第一次进入关卡
        local FreeOpenMd5 = util_getRequireFile("data/FreeOpenMd5")
        if (FreeOpenMd5 and FreeOpenMd5.list and FreeOpenMd5.list[key]) then
            if globalData.userRunData.levelNum < 2 then
                -- 是新手号；第一次不更新直接进入
                oldMd5 = ""
                return false
            else
                -- 删过整包的老号
                oldMd5 = FreeOpenMd5.list[key]
            end
        end
    end

    if oldMd5 ~= md5 then
        return true
    end

    return false
end

function LevelDLControl:getLevelPercent(key)
    for i = 1, #self.m_downLoadInfos do
        if key == self.m_downLoadInfos[i].key then
            return self.m_downLoadInfos[i].percent
        end
    end
    return nil
end

-- 获取下载url
function LevelDLControl:getLevelDownloadUrl(_key, _bCode)
    local data = globalData.GameConfig:checkABTestData(_key)
    local key = _key
    if _bCode then
        key = _key .. "_Code"
    end
    local url = nil
    local downInfo = nil
    if data and not _bCode then
        --如果关卡存在abtest 修改下载地址
        url = string.format("%s%s_%s.zip", LEVELS_ZIP_URL, key, data.groupKey)
    else
        url = string.format("%s%s.zip", LEVELS_ZIP_URL, key)
    end

    return url
end

--更新主题下载进度
function LevelDLControl:notifyDownLoad(url, downType, data)
    local infoIndex = nil
    for i = 1, #self.m_downLoadInfos do
        if url == self.m_downLoadInfos[i].url then
            infoIndex = i
            break
        end
    end
    if not infoIndex then
        return
    end

    local downInfo = self.m_downLoadInfos[infoIndex]
    local downloadDelegate = downInfo.delegate
    if downType == DownLoadType.DOWN_ERROR then
        if downloadDelegate ~= nil then
            downInfo.delegate = nil
        end
        table.remove(self.m_downLoadInfos, infoIndex)
        if data and data.errorEnum then
            gLobalNoticManager:postNotification("LevelDownLoadError_" .. downInfo.key, data.errorEnum)
        end
        self:pushPercent(downInfo.key, -1)
        if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL then
            gLobalSendDataManager:getLogGameLevelDL():sendFinishDownloadLog(downInfo.key, 0)
        end
    elseif downType == DownLoadType.DOWN_PROCESS then
        if data and data.loadPercent then
            downInfo.percent = data.loadPercent
            self:pushPercent(downInfo.key, data.loadPercent)
        end
    elseif downType == DownLoadType.DOWN_UNCOMPRESSED then
        if downInfo ~= nil and downInfo.delegate ~= nil then
            downInfo.delegate = nil
        end
        table.remove(self.m_downLoadInfos, infoIndex)
        self:setVersion(downInfo.key, downInfo.md5)
        self:pushPercent(downInfo.key, 2)
        if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL then
            gLobalSendDataManager:getLogGameLevelDL():sendFinishDownloadLog(downInfo.key, 1)
        end
    end
end

-- function LevelDLControl:setLogInfo(key,downType,open,pos,startTime,activityName)
--     self.m_log[key] = {downType=downType,open=open,pos=pos,startTime=startTime,activityName = activityName}
-- end

--获得版本号或者md5值
function LevelDLControl:getVersion(key)
    if not key then
        return
    end
    local md5 = ""
    if util_isSupportVersion("1.7.8", "ios") or util_isSupportVersion("1.8.6", "android") then
        md5 = gLobalDataManager:getVersion("lv_" .. key)
        -- if md5 == "" then
        --     md5 = gLobalDataManager:getStringByField("level_" .. key, "")
        --     if md5 ~= "" then
        --         -- release_print("--xy--find slots " .. key .. " res!!!")
        --         gLobalDataManager:setVersion("lv_" .. key, md5)
        --         gLobalDataManager:setStringByField("level_" .. key, "")
        --     end
        -- end
    else
        md5 = gLobalDataManager:getStringByField("level_" .. key, "")
    end
    if md5 ~= "" then
        return md5
    end
    return nil
end
--更新版本号或者md5值
function LevelDLControl:setVersion(key, md5)
    if not key then
        return
    end
    if util_isSupportVersion("1.7.8", "ios") or util_isSupportVersion("1.8.6", "android") then
        gLobalDataManager:setVersion("lv_" .. key, md5)
    else
        gLobalDataManager:setStringByField("level_" .. key, md5)
    end
end

-- 设置默认的md5
function LevelDLControl:setFreeMD5(key)
    local FreeOpenMd5 = util_getRequireFile("data/FreeOpenMd5")
    if FreeOpenMd5 and FreeOpenMd5.list then
        -- 是新手关卡；第一次不更新直接进入，但要写入MD5
        local _Md5 = FreeOpenMd5.list[key]
        if _Md5 and _Md5 ~= "" then
            self:setVersion(key, _Md5)
        end
    end
end

--刷新UI进度
function LevelDLControl:pushPercent(key, value)
    gLobalNoticManager:postNotification("LevelPercent_" .. key, value)
end

--监听主题下载
function LevelDLControl:registerDownLoadHandler()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 下载失败重置状态
            self:notifyDownLoad(params.url, DownLoadType.DOWN_ERROR, params)
        end,
        GlobalEvent.GEvent_LoadedError
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 通知下载jindu
            local curPercent = params.loadPercent
            curPercent = curPercent < 0.97 and curPercent or 0.97
            params.loadPercent = curPercent
            self:notifyDownLoad(params.url, DownLoadType.DOWN_PROCESS, params)
        end,
        GlobalEvent.GEvent_LoadedProcess
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, url)
            -- 通知machine 下载chenggogn
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

function LevelDLControl:beginDownLoad(url, key)
    local showMsg = string.format("-----------------beginDownLoad downLoadType = %d url = %s", CC_DOWNLOAD_TYPE, url)
    -- print(showMsg)
    release_print(showMsg)
    key = key or ""
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

--------------------- 删除 列表里 下载信息 ---------------------
function LevelDLControl:removeDownloadInfoByKey(_key)
    for i = 1, #self.m_downLoadInfos do
        if _key == self.m_downLoadInfos[i].key then
            table.remove(self.m_downLoadInfos, i)
            break
        end
    end
end

function LevelDLControl:removeDownloadInfoByUrl(_url)
    for i = 1, #self.m_downLoadInfos do
        if _url == self.m_downLoadInfos[i].url then
            table.remove(self.m_downLoadInfos, i)
            break
        end
    end
end
--------------------- 删除 列表里 下载信息 ---------------------

return LevelDLControl
