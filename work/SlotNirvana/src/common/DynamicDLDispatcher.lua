-- Created by jfwang on 2019-05-05.
-- 动态下载控制器
--
-- ios fix
local LuaList = require("common.LuaList")
local BaseDLControl = require("common.BaseDLControl")
local DynamicDLControl_UseDispatcher = require("common.DynamicDLControl_UseDispatcher")
local DynamicDLDispatcher = class("DynamicDLDispatcher")
DynamicDLDispatcher.instance = nil
DynamicDLDispatcher.dataList = {}
function DynamicDLDispatcher:getInstance()
    if not DynamicDLDispatcher.instance then
        DynamicDLDispatcher.instance = DynamicDLDispatcher:create()
        DynamicDLDispatcher.instance:initData()
    end

    return DynamicDLDispatcher.instance
end

function DynamicDLDispatcher:getOpenExtraDownloadLineNum()
    local verInfo = globalData.GameConfig:getVerInfo()

    local useNum = verInfo["useDynamicDispatherNum"] or 0

    return useNum
end

function DynamicDLDispatcher:initData()
    --下载控制器数组
    self.m_dynamicDLVec = {}

    self.m_downloadComplete = {}
    self.unzipMap = {}
    self.m_downloadQueue = LuaList.new()
    self.m_downLoadInfo = nil
    self.m_downLoadCount = 0
    -- 总下载字节数
    self.m_totalDlBytes = 0
    -- 当前已下载字节数
    self.m_curDlBytes = 0
    self.m_checkUseExtraLine = false
end


function DynamicDLDispatcher:purge()
    if self.m_dynamicDLVec then
        for i,oneDL in ipairs(self.m_dynamicDLVec) do
            oneDL:clearData()
        end
    end
    self.m_dynamicDLVec = nil
    self.m_downloadComplete = nil
    self.unzipMap = nil
    self.m_downloadQueue = nil
    self.m_downLoadInfo = nil
    self.m_downLoadCount = 0
    self.m_totalDlBytes = 0
    self.m_curDlBytes = 0
    self.m_checkUseExtraLine = false
end

function DynamicDLDispatcher:initDynamicConfig()
    self:checkLocalDynamicDir()
end

--请求服务器，获取需要下载内容
function DynamicDLDispatcher:getServerConfig()
    local data = globalData.GameConfig:getActivityNeedDownload()
    if data and #data > 1 then
        data = table_unique(data, true)
    end
    return data
end

function DynamicDLDispatcher:checkUseExtraLine()
    if self.m_checkUseExtraLine then
        return
    end
    self.m_checkUseExtraLine = true
    local extraDownloadLineNum = self:getOpenExtraDownloadLineNum()
    if extraDownloadLineNum > 0 then
        for i = 1, extraDownloadLineNum do
            local oneDLControl = DynamicDLControl_UseDispatcher:create()
            oneDLControl:initData()
            oneDLControl:setDispatcherDownloadFunc(function ()
                self:onDownload()
            end)
            oneDLControl:setCompleteUnZipCheck(function ()
                self:completeUnZipCheck()
            end)
    
            table.insert(self.m_dynamicDLVec,oneDLControl)
        end
    end
end

--[[
    @desc: 
    author:{author}
    time:2021-09-26 20:05:09
    --@dlPos: 下载入口
	--@vType: 资源队列
    @return:
]]
function DynamicDLDispatcher:startDownload(dlPos, vType)
    self:checkUseExtraLine()
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

   self:startDispatcherDownload()
end


function DynamicDLDispatcher:startDispatcherDownload()
   
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
function DynamicDLDispatcher:initDlBytes()
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

-- 需要下载的资源总数
function DynamicDLDispatcher:getDLCount()
    return self.m_downLoadCount
end

--当前解压的数量
function DynamicDLDispatcher:getCurUnzipCount()
    local  count = 0
    for i,oneDL in ipairs(self.m_dynamicDLVec) do
        count = count + oneDL:getCurUnzipCount()
    end
    return count
end

function DynamicDLDispatcher:getALLDlPercent()
    local totalCount = self:getDLCount()
    local curCount = self:getCurUnzipCount()
    return curCount/totalCount + self:getPercent()/totalCount
end

function DynamicDLDispatcher:getPercent()
    local  per = 0
    for i,oneDL in ipairs(self.m_dynamicDLVec) do
        per = per + oneDL:getPercent()
    end
    return per
end

-- 获得下载进度
function DynamicDLDispatcher:getDLProgress()
    local _dlBytes = 0
    for i,oneDL in ipairs(self.m_dynamicDLVec) do
        _dlBytes = _dlBytes + oneDL:getALlDLBytes()
    end

    if self.m_totalDlBytes > 0 then
        return self:getDlTxt(_dlBytes) .. "/" .. self:getDlTxt(self.m_totalDlBytes)
    else
        return ""
    end
end

function DynamicDLDispatcher:getDlTxt(bytes)
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


--后台下载逻辑
function DynamicDLDispatcher:onDownload()
    if self.m_downloadQueue:empty() then
        -- local startTime = xcyy.SlotsUtil:getMilliSeconds()
        -- print("结束下载时间是:---------------DynamicDLControl------------------"..startTime)
        self.m_printTime = false
        return
    end
    if not self.m_printTime then
        self.m_printTime = true
        -- local startTime = xcyy.SlotsUtil:getMilliSeconds()
        -- print("开始下载时间是:--------------DynamicDLControl-------------------"..startTime)
    end
    for i,oneDL in ipairs(self.m_dynamicDLVec) do
        if not oneDL:isWorking() then
            local info = self.m_downloadQueue:pop()
            if info ~= nil then
                oneDL:checkDownLoad(info)
            end
        end
    end
end


function DynamicDLDispatcher:completeUnZipCheck()
    if self.m_hasDoCompleteUnZipCheck then
        return
    end
    if self:getCurUnzipCount() > 0 and self:getCurUnzipCount() == self:getDLCount() then
        self.m_hasDoCompleteUnZipCheck = true
        gLobalNoticManager:postNotification(GlobalEvent.GEvent_UncompressSuccess, "DynamicZip")
    end
end

-- 初始化下载字节数
function DynamicDLDispatcher:initDlBytes()
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

-----------------------------------------------------下载配置相关----------------------------------------------------------

-- 生成下载队列
function DynamicDLDispatcher:createDLQueue(dlPos, resType)
    local dlQueue = {}
    local levelQueue = {}
    local nType = tonumber(resType)
    dlQueue = clone(self.m_dyZips[tostring(resType)] or {})
    
    -- 新手期要下的资源
    local dlNovice = G_GetMgr(G_REF.UserNovice):getDlZips(resType)
    for j = #dlNovice, 1, -1 do
        local _info = dlNovice[j]
        table.insert(dlQueue, 1, _info)
    end

    -- 扩圈功能要下载的资源(放到最前边， 新用户第一次进游戏就需要)
    local dlNewUserExpand = G_GetMgr(G_REF.NewUserExpand):getDlZips(resType)
    for idx = #dlNewUserExpand, 1, -1 do
        local _info = dlNewUserExpand[idx]
        table.insert(dlQueue, 1, _info)
    end

    -- 宠物伙伴系统 资源
    local dlSideKicksNameList = G_GetMgr(G_REF.Sidekicks):getUserNeedDLZips(dlPos, resType)
    local dlSideKicks = G_GetMgr(G_REF.Sidekicks):getDlZips(dlSideKicksNameList)
    for idx = #dlSideKicks, 1, -1 do
        local _info = dlSideKicks[idx]
        table.insert(dlQueue, 1, _info)
    end

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

-- 初始化动态下载列表
function DynamicDLDispatcher:initDynamicZipTable()
    -- 资源配置表
    self.m_dyZips = {}
    -- 索引配置表
    self.m_dyIdxs = {}

    --获取服务器下载配置
    local serverConfig = self:getServerConfig()

    local datas = globalData.GameConfig.dynamicData or {}
    for k, v in pairs(datas) do
        local data = v
        if data then
            local _zipName = data["zipName"]
            local _md5 = data["md5"]
            -- 判断是否需要下载
            local ret = self:isDownLoad(_zipName, _md5)
            if ret ~= 2 then
                local _type = data["type"]
                if not self.m_dyZips[tostring(_type)] then
                    self.m_dyZips[tostring(_type)] = {}
                end

                local isIn = table_indexof(serverConfig, _zipName)
                if isIn or tonumber(data["open"]) == 1 then
                    local tb = {
                        key = _zipName,
                        md5 = _md5,
                        type = _type,
                        zOrder = data["zOrder"],
                        size = data["size"] or 123
                    }
                    table.insert(self.m_dyZips[tostring(_type)], tb)
                end
            end
        end
    end

    self:updateDyZipSort(nil)
end

-- 更新排序
function DynamicDLDispatcher:updateDyZipSort(newQuestLevelIconList)
    local gameConfig = globalData.GameConfig
    local lvIconDLOrder = gameConfig:getLevelIconDLOrder(newQuestLevelIconList)

    local lobbyDLOrder, lobbyMaxOrder = gameConfig:getLobbyDLOrder()
    -- 排序
    for _key, _value in pairs(self.m_dyZips) do
        local len = #_value
        if len > 1 then
            if newQuestLevelIconList ~= nil and gameConfig.resortLevelZOrder ~= nil and gameConfig.resortLobbyZOrder ~= nil then
                for index, info in ipairs(_value) do
                    local zipName = info.key
                    local st, _ = string.find(zipName, "^Level_")
                    if st then
                        -- 是关卡入口
                        info.zOrder = tostring(lvIconDLOrder[zipName] or info.zOrder)
                    else
                        local _order = lobbyDLOrder[zipName]
                        if _order then
                            info.zOrder = tostring(_order)
                        else
                            info.zOrder = tostring(lobbyMaxOrder or info.zOrder)
                        end
                    end
                end
            end
            --按照窗口优先级排序
            table.sort(
                _value,
                function(a, b)
                    return tonumber(a.zOrder) < tonumber(b.zOrder)
                end
            )
        end

        self.m_dyIdxs[_key] = {}

        -- 刷新索引
        for i = 1, #_value do
            local _info = _value[i]
            if _info then
                self.m_dyIdxs[_key][_info.key] = i
            end
        end
    end
end

-- 查找Dynamic信息
function DynamicDLDispatcher:getDynamicInfo(key, vType)
    if not vType then
        for k, value in pairs(self.m_dyIdxs) do
            local _idx = value[key]
            if _idx then
                return self.m_dyZips[k][_idx]
            end
        end
    else
        vType = tostring(vType)
        local _list = self.m_dyIdxs[vType]
        if _list then
            local _idx = _list[key]
            if _idx then
                return self.m_dyZips[vType][_idx]
            end
        end
    end
    return nil
end

--  初始化ABTest动态资源信息
function DynamicDLDispatcher:initABTestDynamicZipTable(newQuestLevelIconList)
    for vType, value in pairs(self.m_dyZips) do
        local abList = globalData.GameConfig:getABTestDynameicList(vType)
        if abList and #abList > 0 then
            for i = 1, #abList do
                local data = abList[i]
                local info = {
                    key = data.name,
                    md5 = data.md5,
                    type = vType,
                    zOrder = i,
                    size = data.size
                }

                self:addABTestToDyZipTable(info)
            end
        end
    end
    -- 更新排序
    self:updateDyZipSort(newQuestLevelIconList)
end

-- 将ABTest动态数据添加到列表
function DynamicDLDispatcher:addABTestToDyZipTable(info)
    if not info then
        return
    end

    local vType = tostring(info.vType or "")
    if self.m_dyZips[vType] and self.m_dyIdxs[vType] then
        local _zipName = info.key
        local _idx = self.m_dyIdxs[vType][_zipName]
        if _idx then
            -- 动态数据存在，用ABTest覆盖
            self.m_dyZips[vType][_idx] = info
        else
            table.insert(self.m_dyZips[vType], info)
        end
    end
end

-- 检查本地Dynamic文件夹
function DynamicDLDispatcher:checkLocalDynamicDir()
    local datas = globalData.GameConfig.dynamicData or {}

    --基础目录不存在，就清除所有记录
    local machineDirPath = device.writablePath .. "Dynamic/"
    if not cc.FileUtils:getInstance():isDirectoryExist(machineDirPath) then
        for k, v in pairs(datas) do
            local data = v
            if data then
                local key = data["zipName"]
                self:setVersion(key, "")
            end
        end
    end
end

--是否为关卡入口
function DynamicDLDispatcher:isLevelEnterNode(info)
    if not info or not info.key then
        return false
    end
    if string.find(info.key, "^Level_") ~= nil then
        return true
    end
    return false
end

--是否开始下载
function DynamicDLDispatcher:IsAdvPercent()
    if self.m_downLoadCount == 0 then
        return false
    end

    return true
end

--下载总进度
function DynamicDLDispatcher:getAdvPercent()
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

--根据Dynamic配置，AddSearchPath
function DynamicDLDispatcher:initDynamicConfigAddSearchPath()
    if CC_DYNAMIC_DOWNLOAD == true then
        --luckySpin比较特殊，读取csv的等等
        cc.FileUtils:getInstance():addSearchPath(device.writablePath .. "Dynamic", true)
        cc.FileUtils:getInstance():addSearchPath(device.writablePath .. "Dynamic/LuckySpin", true)
        return
    end

    --非动态下载添加本地路径
    cc.FileUtils:getInstance():addSearchPath("Dynamic", true)

    local newSearchPaths = {}
    --加入搜索路径
    local abList = globalData.GameConfig:getABTestDynameicList()
    local newSearchPaths = {}
    if abList and #abList > 0 then
        for i = 1, #abList do
            local data = abList[i]
            newSearchPaths[#newSearchPaths + 1] = "ABTest/" .. data.groupKey .. "/Dynamic/" .. data.name
        end
    end

    local datas = globalData.GameConfig.dynamicData or {}
    for k, v in pairs(datas) do
        local data = v
        if data then
            local moduleName = "Dynamic/" .. data["zipName"]
            newSearchPaths[#newSearchPaths + 1] = moduleName
        end
    end

    if #newSearchPaths > 0 then
        local searchPaths = cc.FileUtils:getInstance():getSearchPaths()
        for i = 1, #searchPaths do
            local value = searchPaths[i]
            newSearchPaths[#newSearchPaths + 1] = value
        end
        cc.FileUtils:getInstance():setSearchPaths(newSearchPaths)
    end
end

function DynamicDLDispatcher:getDownloadLogInfoByURL(url)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            return logDownLoad:getDownloadLogInfoByURL(url)
        end
    end
    return nil
end

----------------------------------外部使用的接口-----------------------------------------

--检测关联下载检测
-- function DynamicDLDispatcher:checkDownloadingRelevancy(key)
--     if not key or key == "" then
--         return false
--     end
--     if self:checkDownloading(key) or self:checkDownloading(key .. "_loading") or self:checkDownloading(key .. "_Loading") or self:checkDownloading(key .. "_Code") or self:checkDownloading(key .. "Code") then
--         return true
--     end
--     return false
-- end

--获取优先级最低的下载
function DynamicDLDispatcher:getDownloadingRelevancyName(key)
    if not key or key == "" then
        return nil
    end
    if self:checkDownloading(key) then
        return key
    elseif self:checkDownloading(key .. "_Code") then
        return key .. "_Code"
    elseif self:checkDownloading(key .. "Code") then
        return key .. "Code"
    end
    return nil
end

--是否处于下载中或者准备下载
function DynamicDLDispatcher:checkDownloading(key)
    if not CC_DYNAMIC_DOWNLOAD then
        return false
    end

    --abtest
    local abList = globalData.GameConfig:getABTestDynameicList()
    if abList and #abList > 0 then
        for i = 1, #abList do
            local data = abList[i]
            if data.name == key then
                local ret = self:isDownLoad(key, data.md5)
                if ret ~= 2 then
                    return true
                end
            end
        end
    end

    local datas = globalData.GameConfig.dynamicData or {}
    local data = datas[key]
    if data then
        local ret = self:isDownLoad(key, data["md5"])
        if ret ~= 2 then
            return true
        end
    end

    return false
end

--是否已经下载
function DynamicDLDispatcher:checkDownloaded(key)
    if not CC_DYNAMIC_DOWNLOAD then
        return true
    end

    key = key or ""
    if key == "" then
        return false
    end

    --abtest
    local abList = globalData.GameConfig:getABTestDynameicList()
    if abList and #abList > 0 then
        for i = 1, #abList do
            local data = abList[i]
            if data.name == key then
                local ret = self:isDownLoad(key, data.md5)
                if ret == 2 then
                    return true
                end
            end
        end
    end

    local datas = globalData.GameConfig.dynamicData or {}
    local data = datas[key]
    if data then
        local ret = self:isDownLoad(key, data["md5"])
        if ret == 2 then
            return true
        end
    end

    return false
end

--是否已经下载过
function DynamicDLDispatcher:isDownLoad(key, md5)
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


--获得版本号或者md5值
function DynamicDLDispatcher:getVersion(key)
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
function DynamicDLDispatcher:setVersion(key, md5)
    if not key then
        return
    end

    if util_isSupportVersion("1.7.8", "ios") or util_isSupportVersion("1.8.6", "android") then
        gLobalDataManager:setVersion("dy_" .. key, tostring(md5))
    else
        gLobalDataManager:setStringByField("Dynamic_" .. key, md5)
    end
end

-------------------------------------------------内部使用的接口-----------------------------------------------------
function DynamicDLDispatcher:checkOnDownload()
    if self:getCurUnzipCount() > 0 and self:getCurUnzipCount() == self:getDLCount() then
        gLobalNoticManager:postNotification(GlobalEvent.GEvent_UncompressSuccess, "DynamicZip")
    end

    DynamicDLDispatcher.super.checkOnDownload(self)
end

function DynamicDLDispatcher:checkDownLoad(info)
    DynamicDLDispatcher.super.checkDownLoad(self, info)
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

--------------------------------------------------打点相关-----------------------------------------------------------
function DynamicDLDispatcher:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            logDownLoad:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
        end
    end
end

function  DynamicDLDispatcher:isDispatcherDLControl()
    return true
end


function DynamicDLDispatcher:getPercentForKey(key)
    local  per = 0
    for i,oneDL in ipairs(self.m_dynamicDLVec) do
        per = per + oneDL:getPercentForKey(key)
    end
    return per
end

function DynamicDLDispatcher:getUnzipInfo(url)
    if  url == nil then
        return nil
    else
        local  info = nil
        for i,oneDL in ipairs(self.m_dynamicDLVec) do
            info = oneDL:getUnzipInfo(url)
            if info then
                break
            end
        end
        return info
    end
end

return DynamicDLDispatcher
