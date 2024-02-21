--
-- 集卡iconcardtexture路径资源下载
-- 动态下载控制器
--
-- ios fix
local BaseDLControl = require("common.BaseDLControl")
local CardsDLControl = class("CardsDLControl", BaseDLControl)
CardsDLControl.instance = nil
CardsDLControl.m_initQueue = nil
function CardsDLControl:getInstance()
    if not CardsDLControl.instance then
        CardsDLControl.instance = CardsDLControl:create()
        CardsDLControl.instance:initData()
    end

    return CardsDLControl.instance
end

function CardsDLControl:purge()
    self:clearData()
end

--开始后台下载重写
function CardsDLControl:startDownload(year, season, group)
    if not CC_DYNAMIC_DOWNLOAD then
        return
    end
    if not CC_CAN_ENTER_CARD_COLLECTION then
        return
    end
    self.m_downLoadCount = self.m_downloadQueue:getListCount()
    self:addQueue(year, season, group)
    --当前没有下载中的列表
    if self.m_downLoadCount == 0 or self.m_downLoadCount == self:getCurUnzipCount() then
        --开启新的下载
        self.m_downLoadCount = self.m_downloadQueue:getListCount()
        self:onDownload()
    end
end
--重写
function CardsDLControl:checkDownLoad(info)
    if info ~= nil then
        local key = info.key
        local md5 = info.md5
        local url = string.format("%s%s.zip", DYNAMIC_DOWNLOAD_URL .. "/Cards/", key)
        local ret = self:isDownLoad(key, md5)
        if ret ~= 2 then
            -- 开始开始下载
            local downInfo = {key = key, url = url, md5 = md5, percent = 0.01, dl = ret}
            local downLoadDelegate = self:beginDownLoad(url, key)
            downInfo.delegate = downLoadDelegate
            self.m_downLoadInfo = downInfo
            self:pushUnzipInfo(url, downInfo)
            -- 日志
            self:sendDownloadLog("Start", nil, "Normal", info.key, info.size)
            -- 打印下载资源
            if self.m_downLoadInfo and self.m_downLoadInfo.key then
                if data and data.groupKey then
                    release_print("checkDownLoad name = " .. self.m_downLoadInfo.key .. " group = " .. data.groupKey)
                else
                    release_print("checkDownLoad name = " .. self.m_downLoadInfo.key)
                end
            end
        else
            -- self:notifyDownLoad(url, DownLoadType.DOWN_UNCOMPRESSED)
            local logInfo = self:getDownloadLogInfoByURL(url)
            if logInfo ~= nil then
                self:sendDownloadLog("Finish", "Success", logInfo.downType, logInfo.zipName, logInfo.zipSize)
            end
            self:onDownload()
        end
    end  
end

--添加新的下载队列
function CardsDLControl:addQueue(year, season, group)
    if not year or not season then
        return
    end
    year = "y" .. year
    season = "s" .. season
    if group and group ~= "base" then
        group = "group" .. group
    end
    local needData = {}
    --获取后台下载配置，放入队列
    local contents = cc.FileUtils:getInstance():getStringFromFile(GD_DynamicCards)
    local content = cjson.decode(contents)
    if not content or not content[year] or not content[year][season] then
        return
    end

    local datas = content[year][season]
    for i = 1, #datas do
        local data = datas[i]
        if data then
            --下载指定的组
            if group then
                if data["zipName"] == year .. "_" .. season .. "_" .. group then
                    local d = {key = data["zipName"], md5 = data["md5"]}
                    needData[#needData + 1] = d
                end
            else
                --没有组信息按赛季下载
                local d = {key = data["zipName"], md5 = data["md5"]}
                needData[#needData + 1] = d
            end
        end
    end

    if needData and #needData > 0 then
        local len = #needData
        if len > 1 then
            --按照窗口优先级排序
            table.sort(
                needData,
                function(a, b)
                    return a.key < b.key
                end
            )
        end
        --检测是否已经在下载列表
        local list, startPos, endPos = self.m_downloadQueue:getList()
        local pushList = {}
        for i = 1, #needData do
            local isPushData = true
            for j = startPos, endPos do
                local queueData = list[j]
                if queueData.key == needData[i].key then
                    isPushData = false
                    break
                end
            end
            --没有重复放入预下载队列
            if isPushData then
                pushList[#pushList + 1] = needData[i]
            end
        end
        if #pushList > 0 then
            --排序之后加入下载队列
            for i = 1, #pushList do
                self.m_downloadQueue:push(pushList[i])
            end
        end
    end

    --基础目录不存在，就清除所有记录
    local machineDirPath = device.writablePath .. "CardsTexture/"
    if not cc.FileUtils:getInstance():isDirectoryExist(machineDirPath) then
        for i = 1, #datas do
            local data = datas[i]
            if data then
                local key = data["zipName"]
                self:setVersion(key, "")
            end
        end
    end
end

--添加CardsTexture搜索路径
function CardsDLControl:initCardsConfigAddSearchPath()
    if CC_DYNAMIC_DOWNLOAD == true then
        local path = device.writablePath .. "CardsTexture"
        cc.FileUtils:getInstance():addSearchPath(path, true)
    else
        cc.FileUtils:getInstance():addSearchPath("CardsTexture", true)
    end
end

function CardsDLControl:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            logDownLoad:sendDownloadLog(eventType, downStatus, downType, zipName, zipSize)
        end
    end
end

function CardsDLControl:getDownloadLogInfoByURL(url)
    if gLobalSendDataManager and gLobalSendDataManager.getLogDownload then
        local logDownLoad = gLobalSendDataManager:getLogDownload()
        if logDownLoad ~= nil then
            return logDownLoad:getDownloadLogInfoByURL(url)
        end
    end
    return nil
end

return CardsDLControl
