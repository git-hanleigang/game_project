--[[
    author:JohnnyFred
    time:2020-06-03 12:05:55
]]
local URLImageManager = class("NetSprite")
URLImageManager.instance = nil

function URLImageManager:ctor()
    self.downLoadList = {}
end

function URLImageManager.getInstance()
    if URLImageManager.instance == nil then
        URLImageManager.instance = URLImageManager:create()
    end
    return URLImageManager.instance
end

function URLImageManager:pushDownloadInfo(url,node,callBack)
    table.insert(self.downLoadList,{url = url,node = node,callBack = callBack})
    if addCleanupListenerNode ~= nil then
        addCleanupListenerNode(node,
        function()
            self:removeDownloadInfoByNode(node)
        end)
    end
    self:run()
end

function URLImageManager:removeDownloadInfo(url)
    local downLoadList = self.downLoadList
    local index = 1
    while index <= #downLoadList do
        local downloadInfo = downLoadList[index]
        if downloadInfo.url == url then
            table.remove(downLoadList,index)
        else
            index = index + 1
        end
    end
end

function URLImageManager:removeDownloadInfoByNode(node)
    local downLoadList = self.downLoadList
    local index = 1
    while index <= #downLoadList do
        local downloadInfo = downLoadList[index]
        if downloadInfo.node == node then
            table.remove(downLoadList, index)
            break
        else
            index = index + 1
        end
    end
end

function URLImageManager:run()
    local downLoadList = self.downLoadList
    if downLoadList ~= nil and self.downloadCor == nil then
        self.downloadCor = coroutine.create(
        function()
            while #downLoadList > 0 do
                local downloadInfo = downLoadList[1]
                local url = downloadInfo.url
                local callBack = downloadInfo.callBack
                local function httpCallBack(statusCode, status)
                    util_resumeCoroutine(self.downloadCor)
                    if callBack ~= nil then
                        callBack(statusCode, status)
                    end
                end
                local status = 3
                if self:checkExitImg(url) then
                    util_nextFrameFunc(function()
                        httpCallBack(200, status)
                    end)
                else
                    xcyy.UrlImage:getInstance():requestUrlImage(url, httpCallBack, status)
                end
                table.remove(downLoadList, 1)
                coroutine.yield()
            end
            self.downloadCor = nil
        end)
        util_resumeCoroutine(self.downloadCor)
    end
end

-- 监测url 对应的图片是否下载过
function URLImageManager:checkExitImg(url)
    local tempMd5 = xcyy.UrlImage:getInstance():getMd5(url)
    local path = device.writablePath .. "pub/head"
    local file = path .. "/" .. tempMd5 .. ".png"
    -- local bExit = cc.FileUtils:getInstance():isFileExist(file)
    local texture = display.getImage(file)
    local bExit = texture ~= nil

    return bExit
end

return URLImageManager