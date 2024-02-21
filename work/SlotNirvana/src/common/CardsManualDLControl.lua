--
-- 集卡以往赛季下载
-- 动态下载控制器
--
-- ios fix
local BaseDLControl = require("common.BaseDLControl")
local CardsManualDLControl = class("CardsManualDLControl", BaseDLControl)
CardsManualDLControl.instance = nil
CardsManualDLControl.m_initQueue = nil
function CardsManualDLControl:getInstance()
    if not CardsManualDLControl.instance then
        CardsManualDLControl.instance = CardsManualDLControl:create()
        CardsManualDLControl.instance:initData()
    end

    return CardsManualDLControl.instance
end

function CardsManualDLControl:purge()
    self:clearData()
end

-- function CardsManualDLControl:notifyDownLoad(url, downType, data)
--     CardsManualDLControl.super.notifyDownLoad(self, url, downType, data)
-- end

--刷新下载进度
function CardsManualDLControl:pushPercent(key, value)
    -- if DEBUG == 2 then
    --     release_print("Dynamic_"..key, value)
    --     print("Dynamic_"..key, value)
    -- end

    --集卡下载进度需要显示
    -- print("------------------- CardsManualDLControl pushPercent 1 ", key, value)
    if CardSysManager and CardSysManager.getManualDLNotifyNames then
        local DLList = CardSysManager:getManualDLNotifyNames()
        for i = 1, #DLList do
            if key == DLList[i] then
                -- print("------------------- CardsManualDLControl pushPercent 2 ", key, value)
                gLobalNoticManager:postNotification("DL_Percent" .. key, value)
                if value > 1 then
                    gLobalNoticManager:postNotification("DL_Complete" .. key, value)
                end
            end
        end
    end
    if ObsidianCard and ObsidianCardCfg.CardObsidianDynamicKey then
        for k,v in pairs(ObsidianCardCfg.CardObsidianDynamicKey) do
            if v == key then
                gLobalNoticManager:postNotification("DL_Percent" .. key, value)
                if value > 1 then
                    gLobalNoticManager:postNotification("DL_Complete" .. key, value)
                end
            end
        end
    end
end

--开始下载
function CardsManualDLControl:startDownload(vType, downloadList)
    if not CC_DYNAMIC_DOWNLOAD then
        return
    end
    if not CC_CAN_ENTER_CARD_COLLECTION then
        return
    end

    if not downloadList or #downloadList == 0 then
        return
    end

    self:addQueue(vType, downloadList)
    --开启新的下载
    self.m_downLoadCount = self.m_downloadQueue:getListCount()
    self:onDownload()
end

--后台下载逻辑
function CardsManualDLControl:onDownload()
    if self.m_downloadQueue:empty() then
        return
    end

    local info = self.m_downloadQueue:pop()
    if info ~= nil then
        self:checkDownLoad(info)
    end
end

-- function CardsManualDLControl:addDownLoadInfo(_dlInfo)
--     if not self.m_downLoadInfoList then
--         self.m_downLoadInfoList = {}
--     end
--     table.insert(self.m_downLoadInfoList, _dlInfo)
-- end

-- function CardsManualDLControl:delDownLoadInfo(_dlInfo)
--     for i= #self.m_downLoadInfoList, 1, -1 do
--         if self.m_downLoadInfoList[i].url == _dlInfo.url then
--             table.remove(self.m_downLoadInfoList, i)
--             break
--         end
--     end
-- end

-- function CardsManualDLControl:isDownLoadInfoEmpty()
--     if table.nums(self.m_downLoadInfoList) == 0 then
--         return true
--     end
--     return false
-- end

-- function CardsManualDLControl:isInDownLoadInfo(_dlInfo)
--     if _dlInfo == nil then
--         return false
--     end
--     if _dlInfo.url == nil then
--         return false
--     end
--     for i = 1, #self.m_downLoadInfoList do
--         if self.m_downLoadInfoList[i].url == _dlInfo.url then
--             return true
--         end
--     end
--     return false
-- end

-- function CardsManualDLControl:getDownLoadInfo(_url)
--     for i=1,#self.m_downLoadInfoList do
--         if self.m_downLoadInfoList[i].url == _url then
--             return self.m_downLoadInfoList[i]
--         end
--     end
--     return nil
-- end

function CardsManualDLControl:checkDownLoad(info)
    local key = info.key
    local md5 = info.md5
    local ret = self:isDownLoad(key, md5)
    if ret ~= 2 then
        -- 开始开始下载
        local url = string.format("%s%s.zip", DYNAMIC_DOWNLOAD_URL, key)
        local downInfo = {key = key, url = url, md5 = md5, percent = 0.01, dl = ret}
        -- if self.isDownloadInThread ~= nil and self:isDownloadInThread(url) then
        --     downInfo.delegate = self:getDownloadDelegate(url)
        -- else
        local downLoadDelegate = self:beginDownLoad(url, key)
        downInfo.delegate = downLoadDelegate
        -- end

        self.m_downLoadInfo = downInfo
        -- self:addDownLoadInfo(downInfo)

        self:pushUnzipInfo(url, downInfo)
    else
        self:notifyDownLoad(nil, DownLoadType.DOWN_UNCOMPRESSED)
    end
end

-- 手动下载资源列表
function CardsManualDLControl:addQueue(vType, downloadList)
    local needData = {}
    local datas = globalData.GameConfig.dynamicData or {}
    for i = 1, #downloadList do
        local key = downloadList[i]
        local data = datas[key]
        if data and tonumber(data["type"]) == vType then
            local tb = {
                key = data["zipName"],
                md5 = data["md5"],
                type = data["type"],
                zOrder = data["zOrder"]
            }
            needData[#needData + 1] = tb
        end
    end

    if needData and #needData > 0 then
        local len = #needData
        if len > 1 then
            --按照窗口优先级排序
            table.sort(
                needData,
                function(a, b)
                    return a.zOrder < b.zOrder
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
end

return CardsManualDLControl
