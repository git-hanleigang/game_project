-- Created by jfwang on 2019-05-05.
-- 动态下载控制器
--
-- ios fix
local BaseDLControl = require("common.BaseDLControl")
local DynamicDLControl = class("DynamicDLControl", BaseDLControl)
DynamicDLControl.instance = nil
DynamicDLControl.dataList = {}
function DynamicDLControl:getInstance()
    if not DynamicDLControl.instance then
        DynamicDLControl.instance = DynamicDLControl:create()
        DynamicDLControl.instance:initData()
    end

    return DynamicDLControl.instance
end

function DynamicDLControl:purge()
    self:clearData()
end

function DynamicDLControl:initDynamicConfig()
    self:checkLocalDynamicDir()
end

--请求服务器，获取需要下载内容
function DynamicDLControl:getServerConfig()
    local data = globalData.GameConfig:getActivityNeedDownload()
    if data and #data > 1 then
        data = table_unique(data, true)
    end
    return data
end

--根据版本下载
function DynamicDLControl:changeNameByVersion122(strName)
    local v122 = {
        "Activity_Quest_loading",
        "Activity_QuestFreeBuff",
        "Activity_QuestLink",
        "Activity_Quest",
        "Promotion_Quest",
        "Activity_DeluexeClub",
        "Activity_EveryCardMission"
    }

    local changeName = strName
    for i = 1, #v122 do
        if v122[i] == strName then
            changeName = strName .. "_v122"
            break
        end
    end
    return changeName
end

--[[
    @desc: 
    author:{author}
    time:2021-09-26 20:05:09
    --@dlPos: 下载入口
	--@vType: 资源队列
    @return:
]]
function DynamicDLControl:startDownload(dlPos, vType)
    self.m_downloadQueue:clear()
    self.curPer = 0
    self.m_luaNameString = "DynamicDLControl"
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

    DynamicDLControl.super.startDownload(self)
end

--初始化下载队列 vType 下载位置 0：loading时 1：后台下载 2：主动点击下载
function DynamicDLControl:initQueue(vType)
    self.m_downloadQueue:clear()
    self.curPer = 0
    local needData = {}
    --获取服务器下载配置
    local serverConfig = self:getServerConfig()

    local datas = globalData.GameConfig.dynamicData or {}
    for k, v in pairs(datas) do
        local data = v
        if data then
            local _zipName = data["zipName"]
            local _type = data["type"]
            local isNewPlayer = globalData.GameConfig:isNewPlayer()
            local isIgnoreZip = globalData.GameConfig:checkNewPlayerIgnoreZip(_zipName)
            local isTrue = (not isIgnoreZip) or (not isNewPlayer)
            if isTrue and tonumber(_type) == vType then
                local isIn = table_indexof(serverConfig, _zipName)
                if isIn or tonumber(data["open"]) == 1 then
                    local tb = {
                        key = _zipName,
                        md5 = data["md5"],
                        type = _type,
                        zOrder = data["zOrder"],
                        size = data["size"] or 123
                    }
                    needData[#needData + 1] = tb
                end
            end
        end
    end

    local abList = globalData.GameConfig:getABTestDynameicList(vType)
    if abList and #abList > 0 then
        for i = 1, #abList do
            local data = abList[i]
            local d = {key = data.name, md5 = data.md5, type = vType, zOrder = i, size = data.size}
            local isSameData = nil
            for j = 1, #needData do
                if needData[j].key == data.name then
                    isSameData = true
                    needData[j] = d
                    break
                end
            end
            if not isSameData then
                needData[#needData + 1] = d
            end
        end
    end
    if needData and #needData > 0 then
        -- 根据不同的点位金
        self.dataList[#self.dataList + 1] = needData

        local len = #needData
        if len > 1 then
            --按照窗口优先级排序
            table.sort(
                needData,
                function(a, b)
                    return tonumber(a.zOrder) < tonumber(b.zOrder)
                end
            )
        end

        --关卡入口拿出来单独做队列
        local levelNodeList = {}
        --排序之后加入下载队列
        for i = 1, len do
            local pushData = needData[i]
            -- if not CC_CAN_ENTER_CARD_COLLECTION then
            --     --如果没有开启集卡系统 不下载集卡系统内部资源
            --     if pushData.key == "CardsRes201903" then
            --         pushData = nil
            --     end
            -- end
            if pushData ~= nil then
                if vType == 1 and self:isLevelEnterNode(pushData) then
                    --关卡入口
                    levelNodeList[#levelNodeList + 1] = pushData
                else
                    -- 判断是否需要下载
                    local ret = self:isDownLoad(pushData.key, pushData.md5)
                    if ret ~= 2 then
                        self.m_downloadQueue:push(pushData)
                    end
                end
            end
        end
        --关卡入口队列开始下载
        if vType == 1 then
            globalLevelNodeDLControl:startDownload(vType, levelNodeList)
        end
    end
end

-- 生成下载队列
function DynamicDLControl:createDLQueue(dlPos, resType)
    local dlQueue = {}
    local levelQueue = {}
    local nType = tonumber(resType)
    dlQueue = clone(self.m_dyZips[tostring(resType)] or {})

    -- 新手期要下的资源
    local userNoviceMgr = G_GetMgr(G_REF.UserNovice)
    if userNoviceMgr then
        local dlNovice = userNoviceMgr:getDlZips(resType)
        for j = #dlNovice, 1, -1 do
            local _info = dlNovice[j]
            table.insert(dlQueue, 1, _info)
        end
    end

    -- 扩圈功能要下载的资源(放到最前边， 新用户第一次进游戏就需要)
    local expandMgr = G_GetMgr(G_REF.NewUserExpand)
    if expandMgr then
        local dlNewUserExpand = expandMgr:getDlZips(resType)
        for idx = #dlNewUserExpand, 1, -1 do
            local _info = dlNewUserExpand[idx]
            table.insert(dlQueue, 1, _info)
        end
    end

    for i = #dlQueue, 1, -1 do
        local _info = dlQueue[i]
        local isIgnoreZips = (nType == 0) and globalData.GameConfig:checkNewPlayerIgnoreZip(_info.key)
        if self:isDownLoad(_info.key, _info.md5) == 2 or isIgnoreZips then
            table.remove(dlQueue, i)
        else

            -- -- 集卡
            -- if string.find(_info.key, "CardsRes") then
            --     for k, v in pairs(CardResConfig.CardResDynamicKey) do
            --         if v.isDynamic == false then
            --             table.remove(dlQueue, i)
            --         end
            --     end
            -- end
            
            -- -- cardnewuser todo 下载这里走徐袁的新手期统一下载逻辑
            -- -- 非新手期用户，不下载新手期集卡
            -- if tonumber(globalData.cardAlbumId) == "302301" and string.find(_info.key, "CardsRes"..CardNoviceCfg.ALBUMID) then
            --     table.remove(dlQueue, i)
            -- end
            

            if self:isLevelEnterNode(_info) and dlPos == 1 then
                table.remove(dlQueue, i)
                table.insert(levelQueue, 1, _info)
            end
        end
    end
    -- dump(dlQueue, "--- dlQueue ---", 3)
    return dlQueue, levelQueue
end

-- 初始化动态下载列表
function DynamicDLControl:initDynamicZipTable()
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
function DynamicDLControl:updateDyZipSort(newQuestLevelIconList)
    local gameConfig = globalData.GameConfig
    -- local curTime = socket.gettime()
    local lvIconDLOrder = gameConfig:getLevelIconDLOrder(newQuestLevelIconList)

    local lobbyDLOrder, lobbyMaxOrder = gameConfig:getLobbyDLOrder()
    -- 排序
    for _key, _value in pairs(self.m_dyZips) do
        local len = #_value
        if len > 1 then
            if newQuestLevelIconList ~= nil and gameConfig.resortLevelZOrder ~= nil and gameConfig.resortLobbyZOrder ~= nil then
                for index, info in ipairs(_value) do
                    local zipName = info.key
                    -- gameConfig:resortLevelZOrder(newQuestLevelIconList, zipName, info)
                    -- gameConfig:resortLobbyZOrder(zipName, info)
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

            -- addCostRecord("updateDyZipSort--newQuest--" .. _key, socket.gettime() - curTime)

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
function DynamicDLControl:getDynamicInfo(key, vType)
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
function DynamicDLControl:initABTestDynamicZipTable(newQuestLevelIconList)
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
function DynamicDLControl:addABTestToDyZipTable(info)
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
function DynamicDLControl:checkLocalDynamicDir()
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
function DynamicDLControl:isLevelEnterNode(info)
    if not info or not info.key then
        return false
    end
    if string.find(info.key, "^Level_") ~= nil then
        -- local LevelName = "GameScreen" .. string.sub(info.key, 7)
        -- if globalData.slotRunData.p_machineDatas and #globalData.slotRunData.p_machineDatas > 0 then
        --     for index = 1, #globalData.slotRunData.p_machineDatas do
        --         local data = globalData.slotRunData.p_machineDatas[index]
        --         if data.p_levelName == LevelName then
        --             data.zOrder = index
        --             return true
        --         end
        --     end
        -- end
        -- local data = globalData.slotRunData:getLevelInfoByName(info.key)
        -- if data then
        --     -- data.zOrder = index
        --     return true
        -- end
        return true
    end
    return false
end

--是否开始下载
function DynamicDLControl:IsAdvPercent()
    if self.m_downLoadCount == 0 then
        return false
    end

    return true
end

--下载总进度
function DynamicDLControl:getAdvPercent()
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
function DynamicDLControl:initDynamicConfigAddSearchPath()
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

--检测关联下载检测
-- function DynamicDLControl:checkDownloadingRelevancy(key)
--     if not key or key == "" then
--         return false
--     end
--     if self:checkDownloading(key) or self:checkDownloading(key .. "_loading") or self:checkDownloading(key .. "_Loading") or self:checkDownloading(key .. "_Code") or self:checkDownloading(key .. "Code") then
--         return true
--     end
--     return false
-- end

--获取优先级最低的下载
function DynamicDLControl:getDownloadingRelevancyName(key)
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
function DynamicDLControl:checkDownloading(key)
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
function DynamicDLControl:checkDownloaded(key)
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

--判断当前需要下载的key 是否能开启
function DynamicDLControl:getKeyOpenStatus(key)
    -- 存储的是多个下载点位的信息 所以要遍历一下
    local open = false
    for i = 1, table.nums(self.dataList) do
        local typeTable = self.dataList[i]
        for j = 1, table.nums(typeTable) do
            local info = typeTable[j]
            if key == info.key then
                open = true
                break
            end
        end
    end

    return open
end

function DynamicDLControl:checkOnDownload()
    if self:getCurUnzipCount() > 0 and self:getCurUnzipCount() == self:getDLCount() then
        gLobalNoticManager:postNotification(GlobalEvent.GEvent_UncompressSuccess, "DynamicZip")
    end

    DynamicDLControl.super.checkOnDownload(self)
end

function DynamicDLControl:checkDownLoad(info)
    DynamicDLControl.super.checkDownLoad(self, info)
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

function DynamicDLControl:notifyDownLoad(url, downType, data)
    DynamicDLControl.super.notifyDownLoad(self, url, downType, data)
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

function DynamicDLControl:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            logDownLoad:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
        end
    end
end

function DynamicDLControl:getDownloadLogInfoByURL(url)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            return logDownLoad:getDownloadLogInfoByURL(url)
        end
    end
    return nil
end

function DynamicDLControl:isDispatcherDLControl()
    return false
end

return DynamicDLControl
