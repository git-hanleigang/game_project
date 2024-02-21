--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-02 11:24:09
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-30 12:11:50
FilePath: /SlotNirvana/src/GameModule/MachineGrandShare/controller/MachineGrandShareManager.lua
Description: 关卡中大奖分享 mgr
--]]
local MachineGrandShareNet = require("GameModule.MachineGrandShare.net.MachineGrandShareNet")
local MachineGrandShareConfig = require("GameModule.MachineGrandShare.config.MachineGrandShareConfig")
local MachineGrandShareSaveData = require("GameModule.MachineGrandShare.model.MachineGrandShareSaveData")
local GrandShareImgSprite = require("GameModule.MachineGrandShare.views.GrandShareImgSprite")
local MachineGrandShareManager = class("MachineGrandShareManager", BaseGameControl)

function MachineGrandShareManager:ctor()
    MachineGrandShareManager.super.ctor(self)
    self:setRefName(G_REF.MachineGrandShare)

    self:checkSaveImgType()
    self:checkRemoveImgDirector()
    self:checkCreateImgDirector()

    self.m_data = MachineGrandShareSaveData:create()
    self.m_net = MachineGrandShareNet:create()
    self.m_downloadUrlList = {}
    self.m_clearScreenShotImgList = {}

    self.m_fbShareCbList = {}
end

function MachineGrandShareManager:getData()
    return self.m_data
end

-- 本设备存储 图片类型
function MachineGrandShareManager:checkSaveImgType()
    self.m_bPng = false
    if device.platform == "ios" and not util_isSupportVersion("1.7.7") then
        self.m_bPng = true
    end
end

-- 图片存储路径
function MachineGrandShareManager:checkCreateImgDirector()
    if not cc.FileUtils:getInstance():isDirectoryExist(MachineGrandShareConfig.IMG_DIRECTORY) then
        cc.FileUtils:getInstance():createDirectory(MachineGrandShareConfig.IMG_DIRECTORY)
    end
    if not cc.FileUtils:getInstance():isDirectoryExist(MachineGrandShareConfig.SCREENSHOT_DIR) then
        cc.FileUtils:getInstance():createDirectory(MachineGrandShareConfig.SCREENSHOT_DIR)
    end
end
function MachineGrandShareManager:removeImgDirector()
    if cc.FileUtils:getInstance():isDirectoryExist(MachineGrandShareConfig.IMG_DIRECTORY) then
        cc.FileUtils:getInstance():removeDirectory(MachineGrandShareConfig.IMG_DIRECTORY)
    end
end

-- 随着时间推移 图片越来越多， 清理下
function MachineGrandShareManager:checkRemoveImgDirector()
    -- 下载的图片目录
    local lastRemoveTime = gLobalDataManager:getNumberByField("GrandShareImgDirClearTime", 0)
    if lastRemoveTime > 0 then
        local diffTime = os.time() - lastRemoveTime
        if diffTime > 2 * 30 * 24 * 3600 then
            self:removeImgDirector()
            gLobalDataManager:setNumberByField("GrandShareImgDirClearTime", os.time())
        end
    else
        gLobalDataManager:setNumberByField("GrandShareImgDirClearTime", os.time())
    end 
end

function MachineGrandShareManager:saveArchiveData()
    self.m_data:saveArchiveData() 
end

-- 保存截屏数据
function MachineGrandShareManager:saveMachineData(_gameId)
    local gameId = _gameId
    local exStr = self.m_bPng and "png" or "jpg"
    local imgPath = string.format(MachineGrandShareConfig.SCREENSHOT_DIR_NAME .. "/img_%s.%s", gameId, exStr)

    local info = {
        imgPath = imgPath,
        gameId = gameId
    }
    self.m_data:push(info)
    return imgPath
end

-- 游戏截屏 保存本地
function MachineGrandShareManager:saveCurScreenImgFile(_gameId, _successCB)
    _gameId = _gameId or globalData.slotRunData.machineData.p_id
    local imgPath = self:saveMachineData(_gameId)
    util_printLog(string.format("关卡大赢开始截屏:%s, bPng:%s", _gameId, self.m_bPng))
    local sp, rt = util_createTargetScreenSprite(nil, display.size, self:getScreenshotsScale())
    util_printLog(string.format("关卡大赢截屏保存到本地——start:%s", imgPath))
    rt:saveToFileLua(imgPath, self.m_bPng, function(_saveFilePath)
        util_printLog(string.format("关卡大赢截屏保存到本地成功:%s", _saveFilePath))
        if _successCB then
            _successCB(_saveFilePath)
        end

        local ClanManager = util_require("manager.System.ClanManager"):getInstance()
        local bTeamMember = ClanManager:checkIsMember() 
        if not bTeamMember then
            self.m_data:pop()
            self:deleteSaveImgByPath(imgPath)
            return
        end
        self.m_data:saveArchiveData()
        -- 截屏成功 发送到服务器
        self:uploadImgToServerReq(imgPath)
    end)
    util_printLog(string.format("关卡大赢截屏保存到本地——end:%s", imgPath))
end

-- 发送给服务器 最新截图
function MachineGrandShareManager:uploadImgToServerReq(_filePath, _bConnect)
    if not gLobalSendDataManager:isLogin() then
        return
    end

    local bFileExit = util_IsFileExist(_filePath)
    if not bFileExit or self.m_uploadImgReqIng then
        return
    end

    if _bConnect then
        self:deleteSaveImgByPath(_filePath)
    end
    self.m_uploadImgReqIng = true
    local data = cc.FileUtils:getInstance():getDataFromFile(_filePath)
    self.m_net:uploadImgToServerReq(data, _filePath, handler(self, self.uploadSuccess))
end
function MachineGrandShareManager:uploadSuccess()
    self.m_uploadImgReqIng = false
    local data = self.m_data:pop()
    if data then
        self.m_data:saveArchiveData()
        self:deleteSaveImgByPath(data:getImagePath())
    end
    
    local topData = self.m_data:getTop()
    if not topData then
        return
    end
    
    performWithDelay(display.getRunningScene(), function()
        local imgPath = topData:getImagePath()
        self:uploadImgToServerReq(imgPath)
    end, 0)
end
function MachineGrandShareManager:deleteSaveImgByPath(_imgPath)
    if not _imgPath then
        return
    end

    local fileName = string.match(_imgPath, "([%w-_]+)%.")
    if not fileName then
        return
    end

    self.m_clearScreenShotImgList[fileName] = (self.m_clearScreenShotImgList[fileName] or 0) + 1
    if self.m_clearScreenShotImgList[fileName] < 2 then
        return
    end

    local bFileExit = util_IsFileExist(_imgPath)
    if bFileExit then
        cc.FileUtils:getInstance():removeFile(_imgPath)
    end
end

-- 下载分享 图片
function MachineGrandShareManager:downloadImgFromServerReq()
    if not gLobalSendDataManager:isLogin() then
        return
    end

    if self.m_downloadImgReqIng then
        return
    end

    local url = table.remove(self.m_downloadUrlList, 1)
    if not url then
        return
    end

    self.m_downloadImgReqIng = true
    self.m_net:downloadImgFromServerReq(url, handler(self, self.downlaodImgSuccess))
end
function MachineGrandShareManager:downlaodImgSuccess(_imgName)
    self.m_downloadImgReqIng = false
    if _imgName then
        gLobalNoticManager:postNotification(MachineGrandShareConfig.EVENT_NAME.DOWNLOAD_IMG_SUCCESS .. _imgName)
    end
    self:downloadImgFromServerReq()
end

--创建 分享图片
function MachineGrandShareManager:getShareImgSp(_urlPath, _size, _defaultImgPath, _bImageFull)
    local url = GRAND_SHARE_IMG_URL .. _urlPath
    -- local url = "https://tupian.sioe.cn/uploadfile/201104/10/1958299577.jpg"
    table.insert(self.m_downloadUrlList, url)

    local view = GrandShareImgSprite:create()
    view:setUrl(url, _size, _defaultImgPath, _bImageFull)
    return view
end

-- fb分享图片(网页版 分享没有回调 10秒后固定回调)
function MachineGrandShareManager:shareToFb(_imgPath, _cb)
    _cb = _cb or function() end
    if not util_IsFileExist(_imgPath) or device.platform == "mac" then
        _cb(-1)
        return
    end
    
    local shareCallback = function (_message)
        gLobalViewManager:removeLoadingAnima()
        local msg = cjson.decode(_message)
        if msg.succuess == 1 then 
            self:sendFbActLog("Success")
        elseif msg.succuess == -1 then 
            self:sendFbActLog("Fail")
        else
            self:sendFbActLog("Cancel")
        end

        if self.m_fbShareCbList[_cb] then
            _cb(msg.succuess)
        end
        self.m_fbShareCbList[_cb] = nil
        self:checkStopRemoveDelayAct()
    end
    globalFaceBookManager:facebookSharePicture(_imgPath, shareCallback)
    self:checkStopRemoveDelayAct()
    gLobalViewManager:addLoadingAnima(false, 0, 10)
    self.m_delayAct = performWithDelay(display.getRunningScene(), function()
        if self.m_fbShareCbList[_cb] then
            _cb()
        end
        self.m_fbShareCbList[_cb] = nil
    end, 10)
    self.m_fbShareCbList[_cb] = _cb
end
-- 数据打点
function MachineGrandShareManager:sendFbActLog(_status)
    local type = "GrandShare"
    local actionType = "Click"
    local sst = _status
    gLobalSendDataManager:getLogFbFun():sendFbActLog(type, actionType, "", "", "", sst)
end

-- 获取截屏大小
function MachineGrandShareManager:getScreenshotsScale()
    local scale = self.m_bPng and 0.6 or 0.8
    if globalData.slotRunData.isPortrait then
        -- 竖屏也不会翻转90度展示，不需要截图那么大
        scale = 0.4
    end
    return scale
end

-- 移除动作
function MachineGrandShareManager:checkStopRemoveDelayAct()
    if tolua.isnull(self.m_delayAct) then
        self.m_delayAct = nil
        return
    end

    display.getRunningScene():stopAction(self.m_delayAct)
    self.m_delayAct = nil
end

return MachineGrandShareManager