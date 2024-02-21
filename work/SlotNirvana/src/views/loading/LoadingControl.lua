--[[
    加载控制
    author: 徐袁
    time: 2021-05-27 10:26:04
    cxc : 70卡主(虚假的进度条 从原来95改为70)  70到95下载映射(新增)  95-100其他阶段
    -- 
]]
local LoadingResConfig = require("views.loading.LoadingResConfig")
local PreloadPngMap = util_require("Levels.PreloadPngMap")
local LoadingControl = class("LoadingControl", BaseSingleton)

local LoadingOrder = {
    Load_Download = 1,
    Load_UnLoadResource = 2,
    Load_Scene = 3,
    Load_Resource = 4,
    Load_GameStatus = 5,
    Load_EnterLevel = 6
}

-- 准备阶段
local Process_Ready = 10
--下载关卡(目前新手引导第一关使用)
local Process_DownLoad = 70
--释放上一个场景资源
local Process_UnLoad = 75
--加载下一个场景资源
local Process_LoadLayer = 80
--加载关卡合图
local Process_LoadGameRes_Plist = 85
--预加载关卡信号节点
local Process_LoadGameRes_Node = 90
--请求关卡数据
local Process_LoadGameStatus = 95
-- 走lobby 资源时就不在走 game res ， 加载完毕后直接进入游戏
local Process_LoadLobbyRes = 80

-- 已下载的关卡默认进度设置为100
local Process_DownLoadOver = 100
-- cxc 下载映射(70 - 95 为下载进度的映射)
local Process_Download_Map = {70, 95}
-- 当前有需要下载的关卡资源进度条设置为 (70 - 95 为下载进度的映射, 变化这个值就行)
local Process_DownLoading = 70
-- 下载资源进度条最长时间限制
local Process_DownLoadingTime = 5
-- 下载资源完毕后加速阶段每帧随机值
local Process_DownLoadOverSpeedUpInterval = {5, 10}

function LoadingControl:ctor()
    LoadingControl.super.ctor(self)

    self.m_targetProcessVal = nil -- 目标进度
    self.m_processStepVal = nil

    self.m_isLoadRuning = nil -- 是否处于某个 step 加载中..
    self.m_curSceneType = nil
    self.m_nextSceneType = nil -- loading 加载的sceneType
    self.m_loadIndex = nil -- 加载顺序
    self.m_sceneLayer = nil -- 场景layer  lobby 或者 game
    -- 加载步骤
    self.m_curLoadingStep = 0

    self.m_LogSlots = gLobalSendDataManager:getLogSlots()
    self:loadingLogonBgConfig()
end

function LoadingControl:resetLoading()
    self:clearAllSchedule()

    self.m_loadIndex = 1
    self.m_curLoadingStep = 0
    self.m_curProcessVal = 0
    self.m_targetProcessVal = 0
    self.m_isLoadRuning = false
    self.m_startTime = xcyy.SlotsUtil:getMilliSeconds()
    self.m_processStepVal = 0.65
    self.m_machineData = nil
    self.m_nextSceneType = nil
    self.m_curSceneType = nil
    self.m_sceneLayer = nil
    -- 上一个玩的的老虎机信息
    self.m_preMachineData = nil
    self:resetDownloadLevel()
    self.m_bIsDownLoadOver = false -- 当前进入的关卡是否已下载
    self.m_bGameStatus = false -- 当前是否请求到服务器数据

    self.m_currCodeAccomplishSizeSize = 0
    self.m_currResAccomplishSizeSize = 0
    self.m_mergeDownloadCodeOk = false
    self.m_mergeDownloadResOk = false

    self.m_configData = nil
    -- 需要手动先清理一遍注册的事件
    gLobalNoticManager:removeAllObservers(self)
end

function LoadingControl:clearAllSchedule()
    if self.m_loadLobbySchedule then
        scheduler.unscheduleGlobal(self.m_loadLobbySchedule)
        self.m_loadLobbySchedule = nil
    end

    if self.m_loadGameSchedule then
        scheduler.unscheduleGlobal(self.m_loadGameSchedule)
        self.m_loadGameSchedule = nil
    end

    if self.m_unloadGameSchedule then
        scheduler.unscheduleGlobal(self.m_unloadGameSchedule)
        self.m_unloadGameSchedule = nil
    end

    if self.loadingLogicAction then
        scheduler.unscheduleGlobal(self.loadingLogicAction)
        self.loadingLogicAction = nil
    end

    if self.newLoadingAction ~= nil then
        scheduler.unscheduleGlobal(self.newLoadingAction)
        self.newLoadingAction = nil
    end
end

-- 初始化加载信息
function LoadingControl:initLoadingData(data)
    self:resetLoading()
    self.m_clearGameData = false
    self.m_isCsbLoading = false

    self.m_nextSceneType = data.nextScene
    self.m_curSceneType = data.curScene
    if self.m_nextSceneType == SceneType.Scene_Lobby then
        if self.m_curSceneType == SceneType.Scene_Game then
            self.m_lastMachineData = globalData.slotRunData.machineData
        end
        --返回大厅加快
        self.m_processStepVal = 10
    elseif self.m_nextSceneType == SceneType.Scene_Game then
        if globalData.slotRunData.nextMachineData then
            self.m_machineData = globalData.slotRunData.nextMachineData
        else
            self.m_machineData = globalData.slotRunData.machineData
        end

        -- 鲸鱼船长特殊处理
        if self.m_machineData.p_levelName == "GameScreenOrcaCaptain" then
            self.m_isCsbLoading = true
            self.m_processStepVal = 0.56
        end
        -- ================

        self.m_isFastLevel = self.m_machineData.p_fastLevel
        if not self.m_isFastLevel then
            -- setDefaultTextureType("RGBA4444", nil)
        end
    end
end

function LoadingControl:isNextSceneType(sceneType)
    return self.m_nextSceneType == sceneType
end

function LoadingControl:isCurSceneType(sceneType)
    return self.m_curSceneType == sceneType
end

function LoadingControl:isNeedLoading()
    if not self.m_curSceneType or not self.m_nextSceneType then
        return false
    end

    return true
end

function LoadingControl:getLoadingLayer()
    local _scene = display.getRunningScene()
    if _scene then
        return _scene:getChildByName("LoadingLayer")
    else
        return nil
    end
end

function LoadingControl:getMachineData()
    return self.m_machineData
end
function LoadingControl:getLastMachineData()
    return self.m_lastMachineData
end

-- 开始加载
function LoadingControl:startLoading()
    if self:isNeedLoading() then
        if self.m_nextSceneType == SceneType.Scene_Game then
            gL_logData:createNearestGameSessionId(self.m_machineData.p_name)
            self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.START)

            --检测下载
            if self.m_machineData and self.m_machineData.p_levelName and self.m_machineData.p_md5 then
                self:checkLevelDownLoad(self.m_machineData)
            end
        end

        -- 插屛打点
        if self.m_curSceneType == SceneType.Scene_Game and self.m_nextSceneType == SceneType.Scene_Lobby then
            local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
            if questConfig and questConfig.p_isLevelEnterQuest then
                --通过点击quest返回大厅不播广告
            else
                local questActivity = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
                if questActivity and questActivity:isEnterQuestFromGame() then
                    --通过点击quest返回大厅不播广告
                else
                    globalFireBaseManager:sendFireBaseLog("lobby_", "appearing")
                    if globalData.adsRunData:isPlayAutoForPos(PushViewPosType.LevelToLobby) then
                        gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.LevelToLobby)
                        gLobalAdsControl:playAutoAds(PushViewPosType.LevelToLobby)
                    end
                end
            end
        end

        self:runLoadingLogic()
        -- csc 2021-09-08 23:15:04 启动新的进度条进度定时器
        self:runNewLoadingProgress()
    end

    local _loadingLayer = self:getLoadingLayer()
    if _loadingLayer and _loadingLayer["updateLoadingTip"] then
        _loadingLayer:updateLoadingTip()
    end
end

function LoadingControl:checkLevelCodeDownload(_info)
    local levelName = _info.p_levelName
    local downloadKey = levelName .. "_Code"
    local codeSize = _info.p_codeSize or 1
    local bytesSize = _info.p_bytesSize or 1
    local totalSize = codeSize + bytesSize
    self.m_currCodeAccomplishSizeSize = 0
    self.m_mergeDownloadCodeOk = false

    --创建loading期间下载ssid
    if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL then
        gLobalSendDataManager:getLogGameLevelDL():createLoadSessionId(levelName)
    end
    local md5 = _info.p_md5
    local codemd5 = _info.p_codemd5
    -- csc 2021-09-09 12:06:08 下载标识 判断移到另外的方法中进行判断
    -- csc 2021-09-09 12:08:01 如果只需要下载关卡代码的话，不需要加上资源大小
    if not self.isDownLoadLevel then
        totalSize = codeSize
    end
    -- 免费关卡
    if self.m_machineData.p_freeOpen then
        totalSize = codeSize
    end

    if self.downloadLevelCodeFlag then
        local downLevelCodeListener = function(target, params)
            local showProgressTxt = function(percent)
                local _loadingLayer = self:getLoadingLayer()
                if _loadingLayer then
                    -- 显示下载文本
                    _loadingLayer:setDlNotify("LOADING RESOURCES")
                    local bytesTxt = globalLevelNodeDLControl:getDLProgress(percent, codeSize, totalSize, 0)
                    _loadingLayer:setDlBytes("[" .. bytesTxt .. "]")
                end
            end

            self:updateDownLoad(
                params,
                function()
                    self.m_mergeDownloadCodeOk = true
                    showProgressTxt(1)
                    self:checkLevelResDownload(_info)
                    self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DECOMPRESS_CODE_END)
                end,
                function()
                    self:checkLevelCodeDownload(_info)
                end,
                function()
                    local _curPer = math.min(params, 1)
                    if _curPer == 1 then
                        -- 下载完成 c++没有回调下载完成事件
                        self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DOWNLOAD_CODE_END, nil, _info, "code")
                    end
                    -- csc 2021-09-08 22:47:46 取消这块的进度条设置 另起一个下载期间的定时器
                    -- self.m_targetProcessVal = _curPer * Process_Ready
                    -- cxc 2021-11-15 14:53:08 增加70 到 95 的下载映射
                    self.m_currCodeAccomplishSizeSize = math.floor(_curPer * codeSize)
                    Process_DownLoading = Process_Download_Map[1] + (self.m_currCodeAccomplishSizeSize / totalSize * (Process_Download_Map[2] - Process_Download_Map[1]))
                    showProgressTxt(_curPer)
                end
            )
        end

        gLobalNoticManager:removeObserver(self, "LevelDownLoadError_" .. downloadKey)
        gLobalNoticManager:addObserver(
            self,
            function(_target, _errorCode)
                self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.ERROR, self.m_LogSlots.EnterLevelStepErrorEnum.CODE_DOWNLOAD_ERROR, _info, "code", _errorCode)
            end,
            "LevelDownLoadError_" .. downloadKey
        )

        gLobalNoticManager:removeObserver(self, "LevelPercent_" .. downloadKey)
        gLobalNoticManager:addObserver(self, downLevelCodeListener, "LevelPercent_" .. downloadKey)

        local dlFlag = gLobaLevelDLControl:getLevelPercent(downloadKey)
        if not dlFlag or dlFlag == -1 then
            gLobaLevelDLControl:checkDownLoadLevelCode(_info)
            self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DOWNLOAD_CODE_START, nil, _info, "code")
        end
    else
        self:checkLevelResDownload(_info)
    end
end

function LoadingControl:checkLevelResDownload(_info)
    local levelName = _info.p_levelName
    local md5 = _info.p_md5
    local codeSize = _info.p_codeSize or 1
    local bytesSize = _info.p_bytesSize or 1
    local totalSize = codeSize + bytesSize
    self.m_currResAccomplishSizeSize = 0
    self.m_mergeDownloadResOk = false

    -- printInfo("DOWNLOADING LEVEL bytesSize = " .. bytesSize)
    -- csc 2021-09-09 12:06:08 下载标识 判断移到另外的方法中进行判断
    if self.isDownLoadLevel then
        local downLevelResListener = function(target, params)
            local showProgressTxt = function(percent)
                local _loadingLayer = self:getLoadingLayer()
                if _loadingLayer then
                    -- 显示下载文本
                    _loadingLayer:setDlNotify("LOADING RESOURCES")
                    local bytesTxt = globalLevelNodeDLControl:getDLProgress(percent, bytesSize, totalSize, codeSize)
                    _loadingLayer:setDlBytes("[" .. bytesTxt .. "]")
                end
            end

            self:updateDownLoad(
                params,
                function()
                    self.m_mergeDownloadResOk = true
                    showProgressTxt(1)
                    self:downloadOver()
                    self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DECOMPRESS_RES_END)
                end,
                function()
                    self:checkLevelResDownload(_info)
                end,
                function()
                    local _curPer = math.min(params, 1)
                    if _curPer == 1 then
                        -- 下载完成 c++没有回调下载完成事件
                        self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DOWNLOAD_RES_END, nil, _info, "res")
                    end
                    -- csc 2021-09-08 22:47:46 取消这块的进度条设置 另起一个下载期间的定时器
                    -- self.m_targetProcessVal = _curPer * (Process_DownLoading - Process_Ready) + Process_Ready
                    -- cxc 2021-11-15 14:53:08 增加70 到 95 的下载映射
                    self.m_currResAccomplishSizeSize = math.floor(_curPer * bytesSize + codeSize)
                    Process_DownLoading = Process_Download_Map[1] + (self.m_currResAccomplishSizeSize / totalSize * (Process_Download_Map[2] - Process_Download_Map[1]))
                    showProgressTxt(_curPer)
                end
            )
        end
        gLobalNoticManager:removeObserver(self, "LevelDownLoadError_" .. levelName)
        gLobalNoticManager:addObserver(
            self,
            function(_target, _errorCode)
                self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.ERROR, self.m_LogSlots.EnterLevelStepErrorEnum.RES_DOWNLOAD_ERROR, _info, "res", _errorCode)
            end,
            "LevelDownLoadError_" .. levelName
        )

        gLobalNoticManager:removeObserver(self, "LevelPercent_" .. levelName)
        gLobalNoticManager:addObserver(self, downLevelResListener, "LevelPercent_" .. levelName)

        local dlFlag = gLobaLevelDLControl:getLevelPercent(levelName)
        if not dlFlag or dlFlag == -1 then
            local info = self.m_machineData
            gLobaLevelDLControl:checkDownLoadLevel(info)
            self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DOWNLOAD_RES_START, nil, _info, "res")
        end
    else
        --已经有资源，直接进入游戏
        self:downloadOver()
    end
    release_print("checkLevelResDownload end")
end

-- csc 2021年11月29日18:08:38 新增合并下载的方法
function LoadingControl:checkLevelCodeAndResDownload(_info, _failedType)
    local levelName = _info.p_levelName
    local codeSize = _info.p_codeSize or 1 -- 代码大小
    local bytesSize = _info.p_bytesSize or 1 -- 资源大小
    local totalSize = codeSize + bytesSize
    --创建loading期间下载ssid
    if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL then
        gLobalSendDataManager:getLogGameLevelDL():createLoadSessionId(levelName)
    end
    local md5 = _info.p_md5
    local codemd5 = _info.p_codemd5

    -- 区别当前下载失败
    if _failedType == "code" then
        self.m_currCodeAccomplishSizeSize = 0
        self.m_mergeDownloadCodeOk = false
    elseif _failedType == "res" then
        self.m_currResAccomplishSizeSize = 0
        self.m_mergeDownloadResOk = false
    end
    self.m_currAllPercent = 0
    -- code 下载
    local showProgressTxt = function()
        local _loadingLayer = self:getLoadingLayer()
        if _loadingLayer then
            -- 显示下载文本
            _loadingLayer:setDlNotify("LOADING RESOURCES")
            local totalPercentSize = self.m_currCodeAccomplishSizeSize + self.m_currResAccomplishSizeSize
            self.m_currAllPercent = math.floor(totalPercentSize) / totalSize
            local bytesTxt = globalLevelNodeDLControl:getDLProgress(self.m_currAllPercent, totalSize, totalSize, 0)
            -- printInfo("--- csc      总下载大小进度 = "..math.floor(totalPercentSize).."("..self.m_currCodeAccomplishSizeSize .. "+" ..self.m_currResAccomplishSizeSize ..")" .. " 下载进度 =  ".. "[" .. bytesTxt .. "]")
            _loadingLayer:setDlBytes("[" .. bytesTxt .. "]")
        end
    end

    local downloadCode = function()
        local downLevelCodeListener = function(target, params)
            local updateProgress = function(percent)
                self.m_currCodeAccomplishSizeSize = math.floor(codeSize * percent)
                -- printInfo("--- csc 代码已经下载 == "..self.m_currCodeAccomplishSizeSize .. " codeSize = "..codeSize .. " percent = ".. percent)
                showProgressTxt()
            end
            self:updateDownLoad(
                params,
                function()
                    updateProgress(1)
                    self.m_mergeDownloadCodeOk = true
                    self:checkDownLoadOver()
                    self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DECOMPRESS_CODE_END)
                end,
                function()
                    -- 需要预警当前出错的类型
                    self:checkLevelCodeAndResDownload(_info, "code")
                end,
                function()
                    local _curPer = math.min(params, 1)
                    if _curPer == 1 then
                        -- 下载完成 c++没有回调下载完成事件
                        self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DOWNLOAD_CODE_END, nil, _info, "code")
                    end
                    Process_DownLoading = Process_Download_Map[1] + math.floor((_curPer * codeSize) / totalSize * (Process_Download_Map[2] - Process_Download_Map[1]))
                    updateProgress(_curPer)
                end
            )
        end
        gLobalNoticManager:removeObserver(self, "LevelDownLoadError_" .. levelName .. "_Code")
        gLobalNoticManager:addObserver(
            self,
            function(_target, _errorCode)
                self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.ERROR, self.m_LogSlots.EnterLevelStepErrorEnum.CODE_DOWNLOAD_ERROR, _info, "code", _errorCode)
            end,
            "LevelDownLoadError_" .. levelName .. "_Code"
        )

        gLobalNoticManager:removeObserver(self, "LevelPercent_" .. levelName .. "_Code")
        gLobalNoticManager:addObserver(self, downLevelCodeListener, "LevelPercent_" .. levelName .. "_Code")
        local dlFlag = gLobaLevelDLControl:getLevelPercent(levelName .. "_Code")
        if not dlFlag or dlFlag == -1 then
            gLobaLevelDLControl:checkDownLoadLevelCode(_info)
            self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DOWNLOAD_CODE_START, nil, _info, "code")
        end
    end

    local downloadRes = function()
        --
        local downLevelResListener = function(target, params)
            local updateProgress = function(percent)
                self.m_currResAccomplishSizeSize = math.floor(bytesSize * percent)
                -- printInfo("--- csc   资源已经下载 == "..self.m_currResAccomplishSizeSize .. " bytesSize = "..bytesSize .. " percent = ".. percent)
                showProgressTxt()
            end
            self:updateDownLoad(
                params,
                function()
                    updateProgress(1)
                    self.m_mergeDownloadResOk = true
                    self:checkDownLoadOver()
                    self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DECOMPRESS_RES_END)
                end,
                function()
                    -- 需要预警当前出错的类型
                    self:checkLevelCodeAndResDownload(_info, "res")
                end,
                function()
                    local _curPer = math.min(params, 1)
                    if _curPer == 1 then
                        -- 下载完成 c++没有回调下载完成事件
                        self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DOWNLOAD_RES_END, nil, _info, "res")
                    end
                    Process_DownLoading = Process_Download_Map[1] + math.floor((_curPer * bytesSize) / totalSize * (Process_Download_Map[2] - Process_Download_Map[1]))
                    updateProgress(_curPer)
                end
            )
        end
        gLobalNoticManager:removeObserver(self, "LevelDownLoadError_" .. levelName)
        gLobalNoticManager:addObserver(
            self,
            function(_target, _errorCode)
                self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.ERROR, self.m_LogSlots.EnterLevelStepErrorEnum.RES_DOWNLOAD_ERROR, _info, "res", _errorCode)
            end,
            "LevelDownLoadError_" .. levelName
        )

        gLobalNoticManager:removeObserver(self, "LevelPercent_" .. levelName)
        gLobalNoticManager:addObserver(self, downLevelResListener, "LevelPercent_" .. levelName)
        local dlFlag = gLobaLevelDLControl:getLevelPercent(levelName)
        if not dlFlag or dlFlag == -1 then
            local info = self.m_machineData
            gLobaLevelDLControl:checkDownLoadLevel(info)
            self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.DOWNLOAD_RES_START, nil, _info, "res")
        end
    end

    -- 启动下载
    self.startT = socket.gettime()

    if not self.m_mergeDownloadCodeOk then
        -- 没下载成功尝试下载
        downloadCode()
    end

    if not self.m_mergeDownloadResOk then
        -- 没下载成功尝试下载
        downloadRes()
    end
end

function LoadingControl:checkLevelDownLoad(_info)
    self:checkDownLoadFlag(_info)

    -- csc 2021年11月29日18:06:15 修改 下载代码跟关卡同时进行
    self.startT = socket.gettime()
    if self.downloadLevelCodeFlag and self.isDownLoadLevel then
        self:checkLevelCodeAndResDownload(_info)
    else
        self:checkLevelCodeDownload(_info)
    end
end

-- csc 2021-11-29 18:03:42 新增下载检测
function LoadingControl:checkDownLoadOver()
    if self.m_mergeDownloadResOk and self.m_mergeDownloadCodeOk then
        -- 此时才认为全部下载完毕
        self.m_mergeDownloadResOk = false
        self.m_mergeDownloadCodeOk = false
        self:downloadOver()
    end
end

-- 是否是minz关卡
function LoadingControl:isMinzLevel()
    local curMachineData = self.m_machineData
    local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
    if minzMgr then
        return minzMgr:isMinzLevel(curMachineData)
    end
    return false
end

-- 是否是DiyFeature 触发关卡
function LoadingControl:isDiyFeatureLevel()
    local diyFeatureMgr = G_GetMgr(ACTIVITY_REF.DiyFeature)
    local curMachineData = self.m_machineData
    if diyFeatureMgr then
        return diyFeatureMgr:isDiyFeatureLevel(curMachineData)
    end
    return false
end

function LoadingControl:runLoadingLogic()
    if self.loadingLogicAction == nil then
        -- 是开开启返回按钮
        if self.m_nextSceneType == SceneType.Scene_Game then
            local _loadingLayer = self:getLoadingLayer()
            if _loadingLayer then
                if self:isMinzLevel() or self:isDiyFeatureLevel() then
                    _loadingLayer:setBtnBackVisible(false)
                else
                    _loadingLayer:setBtnBackVisible(true)
                end
            end
        end

        self.m_startTime = xcyy.SlotsUtil:getMilliSeconds()
        -- 改变进度条进度
        self.loadingLogicAction =
            scheduler.scheduleGlobal(
            function()
                if self.m_pause then
                    return
                end

                self:loadResStep()

                -- local self.m_curProcessVal = self.m_loadingBar:getPercent()
                if self.m_curProcessVal == self.m_targetProcessVal then
                    -- csc 2021-09-08 17:42:14 需要判断当前满了以后服务器回调后进入游戏
                    if self.m_curProcessVal == 100 and self.m_nextSceneType == SceneType.Scene_Game and self.m_bGameStatus then
                        self:loadComplete()
                    end
                    return
                end
                self.m_curProcessVal = self.m_curProcessVal + self.m_processStepVal

                if self.m_curProcessVal >= self.m_targetProcessVal then
                    self.m_curProcessVal = self.m_targetProcessVal
                end

                local _loadingLayer = self:getLoadingLayer()
                if not tolua.isnull(_loadingLayer) then
                    _loadingLayer:updatePercent(self.m_curProcessVal)
                end

                if self.m_curProcessVal == 100 then
                    -- 加载完成， 进入游戏
                    if self.m_nextSceneType == SceneType.Scene_Game and not self.m_bGameStatus then
                        return
                    end
                    self:loadComplete()
                end
            end,
            1/60
        )
    end
end

function LoadingControl:loadComplete()
    if self.m_nextSceneType == SceneType.Scene_Lobby then
        if globalData.slotRunData.isPortrait == true then
            globalData.slotRunData.isChangeScreenOrientation = true
            globalData.slotRunData:changeScreenOrientation(false)
        end
        RotateScreen:getInstance():initScreenDir()
        self.m_sceneLayer = util_createView("views.lobby.LobbyView")
        self.m_preLoadLobbyNodes = self.m_sceneLayer:getPreLoadLobbyNodes()
        -- if self.m_sceneLayer.freshLevelNode then
        --     self.m_sceneLayer:freshLevelNode("ReturnLobby")
        -- end
        self.m_sceneLayer:retain()
    elseif self.m_nextSceneType == SceneType.Scene_Game then
        RotateScreen:getInstance():initScreenDir()
        local _loadingLayer = self:getLoadingLayer()
        if _loadingLayer then
            if _loadingLayer["setCanSendEnterLevelLogOnExit"] then
                -- loading界面关闭是否需要报送
                _loadingLayer:setCanSendEnterLevelLogOnExit(true)
            end
            _loadingLayer:setBtnBackVisible(false)
        end

        --记录本次进入关卡信息
        globalData.slotRunData:setLastEnterLevelInfo(self.m_machineData)

        if self.m_loadIndex == LoadingOrder.Load_EnterLevel then
            self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.ENTER_LEVEL)
        end
    end
    -- if self.loadingLogicAction ~= nil then
    --     scheduler.unscheduleGlobal(self.loadingLogicAction)
    --     self.loadingLogicAction = nil
    -- end
    -- self:stopAllActions()

    -- 进入scene
    gLobalViewManager:changeScene(self.m_nextSceneType, self.m_sceneLayer)

    self.m_sceneLayer:release() -- 在创建出来时先不加入到场景中，所以手动调用了一次retain

    self:resetLoading()
end

function LoadingControl:completeCurrentLoad()
    self.m_isLoadRuning = false
    --
    if not self.m_loadIndex then
        self.m_loadIndex = 1
    end
    self.m_loadIndex = self.m_loadIndex + 1
end

function LoadingControl:loadResStep()
    if self.m_isLoadRuning == true then
        return
    end

    if self.m_loadIndex == LoadingOrder.Load_Download then
        self:checkDownLoad()
    elseif self.m_loadIndex == LoadingOrder.Load_UnLoadResource then
        self:unloadResource()
    elseif self.m_loadIndex == LoadingOrder.Load_Scene then
        local time = xcyy.SlotsUtil:getMilliSeconds()
        self:loadLayerBySceneType()
        local time1 = xcyy.SlotsUtil:getMilliSeconds()
        printInfo("加载scene 时间" .. (time1 - time))
    elseif self.m_loadIndex == LoadingOrder.Load_Resource then
        if self.m_nextSceneType == SceneType.Scene_Game then
            self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.LOAD_NEW_SCENE)
        end
        release_print("LoadingControl loadSceneResources!!!")
        self:loadSceneResources()
    elseif self.m_loadIndex == LoadingOrder.Load_GameStatus then
        if self.m_nextSceneType == SceneType.Scene_Game then
            self:requestGameStatus()
        else
            self:completeCurrentLoad()
        end
    else
        -- 加载完成
        -- if self.m_targetProcessVal ~= 100 then
        --     if self.m_curSceneType == SceneType.Scene_Game and self.m_nextSceneType == SceneType.Scene_Lobby then
        --         local extra = {}
        --         extra.levelName = self.m_levelName
        --     end
        -- end
        -- self.m_loadAction = nil
        self.m_targetProcessVal = 100
    end

    -- print("----csc loadResStep self.m_targetProcessVal == "..self.m_targetProcessVal)
end

function LoadingControl:checkDownLoad()
    self.m_isLoadRuning = true
    if not self.isDownLoadLevel and not self.downloadLevelCodeFlag then
        release_print("LoadingControl:checkDownLoad false")
        self:completeCurrentLoad()
        self.m_targetProcessVal = Process_DownLoad
    end
end

function LoadingControl:downloadOver()
    -- csc 2021-09-08 23:51:28 下载完毕检测一下是否需要快进进度条
    local endTime = socket.gettime()
    printInfo("--- csc 总用时 == " .. endTime - self.startT)
    self:downloadOvercheckNewLoading()
    -- if self.newLoadingAction then
    --     self:downloadOvercheckNewLoading()
    -- else
    --     self:completeCurrentLoad()
    --     -- self.m_targetProcessVal = Process_DownLoad
    --     -- csc 2021-09-08 16:46:37 修改下载完毕之后,进度直接推到 100
    --     self.m_targetProcessVal = Process_DownLoadOver
    --     self.m_bIsDownLoadOver = true
    --     self:resetDownloadLevel()
    -- end
end

function LoadingControl:resetDownloadLevel()
    self.isDownLoadLevel = false
    self.downloadLevelCodeFlag = false
    self.m_currCodeAccomplishSizeSize = 0
    self.m_currResAccomplishSizeSize = 0
end
function LoadingControl:getNeedDownloadLevel()
    return self.downloadLevelCodeFlag or self.isDownLoadLevel
end

function LoadingControl:updateDownLoad(params, successCallBack, failedCallBack, processCallBack)
    if params == -1 then
        local _loadingLayer = self:getLoadingLayer()
        if _loadingLayer and _loadingLayer:getChildByName("LoadingFixLevelResourcesDialog") then
            -- 有玩家主动弹出的提示弹板不需要弹网络下载提示弹板
            return
        end

        -- local function getSceneChildListByName(name)
        --     local scene = display.getRunningScene()
        --     local childList = {}
        --     if scene ~= nil then
        --         for k, v in ipairs(scene:getChildren()) do
        --             if v:getName() == name then
        --                 table.insert(childList, v)
        --             end
        --         end
        --     end
        --     return childList
        -- end

        -- local downloadFailedDialogList = getSceneChildListByName("DownLoadLevelFailed")
        -- for k, v in ipairs(downloadFailedDialogList) do
        --     if v ~= nil and v.m_okFunc ~= nil then
        --         local preCallBack = v.m_okFunc
        --         v.m_okFunc = function()
        --             if preCallBack ~= nil then
        --                 preCallBack()
        --             end
        --             if failedCallBack ~= nil then
        --                 failedCallBack()
        --             end
        --             v.m_okFunc = nil
        --         end
        --         return
        --     end
        -- end

        local _scene = display.getRunningScene()
        if _scene then
            -- 提示弹框
            local view = _scene:getChildByName("DownLoadLevelFailed")
            if not view then
                view =
                    util_createView(
                    "views.dialogs.DialogLayer",
                    "Dialog/DowanLoadLevelFailed.csb",
                    failedCallBack,
                    nil,
                    false,
                    {
                        {buttomName = "btn_ok", labelString = "RETRY"}
                    }
                )
                view:setName("DownLoadLevelFailed")
                _scene:addChild(view, 1000)
            end
        end
    elseif params == 2 then
        if successCallBack ~= nil then
            successCallBack()
        end
        release_print("LoadingControl:updateDownLoad true")
    else
        if processCallBack ~= nil then
            processCallBack()
        end
    end
end

--[[
    @desc: 卸载当前的场景
    time:2018-07-05 16:14:15
    @return:
]]
function LoadingControl:unloadResource()
    self.m_isLoadRuning = true

    local loading = self:unloadGame()
    self:unloadLobby()

    if not loading then
        self:completeCurrentLoad()
        self.m_targetProcessVal = Process_UnLoad
        -- csc 2021-09-08 16:46:37 修改已下载的关卡,进度直接推到 100
        if self.m_bIsDownLoadOver then
            self.m_targetProcessVal = Process_DownLoadOver
        end
        release_print("LoadingControl unloadResource targetProcessVal:" .. tostring(self.m_targetProcessVal))
    end
end

function LoadingControl:unloadGame()
    local loading = false
    if self.m_curSceneType == SceneType.Scene_Game then
        -- globalMachineController:onExit()

        loading = true
        local unloadGameName = globalData.slotRunData.gameModuleName

        if self.m_nextSceneType ~= SceneType.Scene_Game then
            -- 这么判断主要是老虎机内也可以跳转

            -- 保存当前的老虎机
            self.m_preMachineData = globalData.slotRunData.machineData

            globalData.slotRunData.gameModuleName = nil
            globalData.slotRunData.machineData = nil
            globalData.slotRunData.nextMachineData = nil
            self.m_machineData = nil
        else
            if globalData.slotRunData.nextMachineData then
                globalData.slotRunData.machineData = globalData.slotRunData.nextMachineData
                globalData.slotRunData.nextMachineData = nil
            end
        end

        local preLoadImages = {}
        for i = 1, 20 do
            local pngName = nil
            local plistName = nil
            pngName = string.format("%s%d.png", unloadGameName, i)
            plistName = string.format("%s%d.plist", unloadGameName, i)
            if cc.FileUtils:getInstance():isFileExist(pngName) == true and cc.FileUtils:getInstance():isFileExist(plistName) == true then
                preLoadImages[#preLoadImages + 1] = {pngName, plistName}
            end
            pngName = string.format("%s_%d.png", unloadGameName, i)
            plistName = string.format("%s_%d.plist", unloadGameName, i)
            if cc.FileUtils:getInstance():isFileExist(pngName) == true and cc.FileUtils:getInstance():isFileExist(plistName) == true then
                preLoadImages[#preLoadImages + 1] = {pngName, plistName}
            end
        end

        local count = #preLoadImages
        if count == 0 then
            return
        end
        local loadProcessStep = (Process_UnLoad - Process_DownLoad) / count
        local curProcessStep = self.m_targetProcessVal
        local index = 1
        local isStop = false

        if #preLoadImages == 0 then
            loading = false
        else
            if self.m_unloadGameSchedule then
                scheduler.unscheduleGlobal(self.m_unloadGameSchedule)
                self.m_unloadGameSchedule = nil
            end

            self.m_unloadGameSchedule =
                scheduler.scheduleGlobal(
                function()
                    if self.m_pause then
                        return
                    end
                    -- 将plist 文件全部加载进来
                    if isStop then
                        return
                    end
                    local pngName, plistName = preLoadImages[index][1], preLoadImages[index][2]
                    if cc.FileUtils:getInstance():isFileExist(pngName) == true and cc.FileUtils:getInstance():isFileExist(plistName) == true then
                        display.removeSpriteFrames(plistName, pngName)
                    end
                    self.m_targetProcessVal = curProcessStep + index * loadProcessStep
                    index = index + 1
                    if index >= count then
                        if self.m_unloadGameSchedule then
                            scheduler.unscheduleGlobal(self.m_unloadGameSchedule)
                            self.m_unloadGameSchedule = nil
                        end
                        isStop = true
                        util_removeSearchPath("GameScreen")
                        self:completeCurrentLoad()
                        self.m_targetProcessVal = Process_UnLoad
                    end
                end,
                0.017
            )
        end
    end
    return loading
end

function LoadingControl:unloadLobby()
    if self.m_curSceneType == SceneType.Scene_Lobby and self.m_nextSceneType ~= SceneType.Scene_Lobby then
    end
end
--
-- 加载要进入的场景
--
function LoadingControl:loadLayerBySceneType()
    self.m_isLoadRuning = true

    if self.m_nextSceneType == SceneType.Scene_Lobby then
        -- if globalData.slotRunData.isPortrait == true then
        --     globalData.slotRunData.isChangeScreenOrientation = true
        --     globalData.slotRunData:changeScreenOrientation(false)
        -- end
        -- self.m_sceneLayer = util_createView("views.lobby.LobbyView")
        -- self.m_preLoadLobbyNodes = self.m_sceneLayer:getPreLoadLobbyNodes()
        -- self.m_sceneLayer:retain()
    elseif self.m_nextSceneType == SceneType.Scene_Game then
        release_print("--------------------- loading currentScene = " .. tostring(self.m_curSceneType) .. " nextScene = " .. tostring(self.m_nextSceneType))
        globalData.slotRunData.machineData = self:getMachineData()
        local GameLayerDelegate = require "views.gameviews.GameLayerDelegate"
        local layerDelegate = GameLayerDelegate:create()
        local mainClassName = layerDelegate:getMachineLayer(self:getMachineData())

        local machineLayer = util_createView(mainClassName)
        if self.m_isFastLevel then
            -- setDefaultTextureType("RGBA8888", nil)
        end
        self.m_sceneLayer = machineLayer
        self.m_sceneLayer:retain()
        self.m_preLoadSlotNodes = self.m_sceneLayer:getPreLoadSlotNodes()
        -- 注册进入关卡时事件
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                self:gameStatusCallFun(params)
            end,
            ViewEventType.NOTIFY_GETGAMESTATUS
        )
    elseif self.m_nextSceneType == SceneType.Scene_CoinPusher then
        release_print("--------------------- loading currentScene = " .. tostring(self.m_curSceneType))
        globalData.slotRunData.isChangeScreenOrientation = true
        self.m_sceneLayer = G_GetMgr(ACTIVITY_REF.CoinPusher):GoToCoinPusher(self.m_preMachineData)
        self.m_sceneLayer:retain()
    elseif self.m_nextSceneType == SceneType.Scene_BeerPlinko then
        self.m_sceneLayer = G_GetMgr(G_REF.Plinko):getSceneLayer(self.m_preMachineData or globalData.slotRunData.machineData)
        self.m_sceneLayer:retain()
    elseif self.m_nextSceneType == SceneType.Scene_NewCoinPusher then
        globalData.slotRunData.isChangeScreenOrientation = true
        self.m_sceneLayer = G_GetMgr(ACTIVITY_REF.NewCoinPusher):GoToNewCoinPusher(self.m_preMachineData)
        self.m_sceneLayer:retain()
    elseif self.m_nextSceneType == SceneType.Scene_EgyptCoinPusher then
        globalData.slotRunData.isChangeScreenOrientation = true
        self.m_sceneLayer = G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):GoToEgyptCoinPusher(self.m_preMachineData)
        self.m_sceneLayer:retain()
    end

    self:completeCurrentLoad()
    self.m_targetProcessVal = Process_LoadLayer
    -- csc 2021-09-08 16:46:37 修改已下载的关卡,进度直接推到 100
    if self.m_bIsDownLoadOver then
        self.m_targetProcessVal = Process_DownLoadOver
    end
end
---
-- 加载当前场景中 需要预先加载的资源
--
function LoadingControl:loadSceneResources()
    self.m_isLoadRuning = true

    local isLoadRes = self:loadGameRes()
    isLoadRes = isLoadRes or self:loadLobbyRes()

    if isLoadRes == false then
        self:completeCurrentLoad()
    end
end
--进入关卡额外资源
function LoadingControl:loadGameOterRes()
    local otherlist = {}
    -- otherlist[#otherlist + 1] = {"GameNode/GameNode.png", "GameNode/GameNode.plist"}
    return otherlist
end

function LoadingControl:loadGameRes()
    if self.m_nextSceneType == SceneType.Scene_Game then
        globalMachineController:onEnter()
        local moduleName = self.m_machineData.p_levelName

        local index = string.find(moduleName, "GameScreen")
        moduleName = string.sub(moduleName, index + string.len("GameScreen"), string.len(moduleName))
        local function loadSlotNode()
            print("loadSlotNode - into")
            -- 预创建小块对象
            if self.m_preLoadSlotNodes ~= nil and #self.m_preLoadSlotNodes > 0 then
                local count = #self.m_preLoadSlotNodes
                local loadProcessStep = (Process_LoadGameRes_Node - self.m_targetProcessVal) / count
                local curProcessStep = self.m_targetProcessVal
                if self.m_loadGameSchedule then
                    scheduler.unscheduleGlobal(self.m_loadGameSchedule)
                    self.m_loadGameSchedule = nil
                end

                self.m_loadGameSchedule =
                    scheduler.scheduleGlobal(
                    function()
                        if self.m_pause then
                            return
                        end
                        if not (self.m_nextSceneType == SceneType.Scene_Game) then
                            -- 不是进入关卡，则返回
                            return
                        end

                        if self.m_preLoadSlotNodes ~= nil and #self.m_preLoadSlotNodes > 0 then
                            local preSlotInfo = self.m_preLoadSlotNodes[1]
                            local index = (count - #self.m_preLoadSlotNodes + 1)

                            if DEBUG == 2 then
                                print("loadSlotNode - loop count=" .. index)
                            end
                            -- csc 2021-09-08 16:55:23 这里不需要动态计算总进度了,之前已经设置好了总进度
                            -- self.m_targetProcessVal = curProcessStep + index * loadProcessStep
                            table.remove(self.m_preLoadSlotNodes, 1)
                            if self.m_sceneLayer and not tolua.isnull(self.m_sceneLayer) then
                                self.m_sceneLayer:preLoadSlotsNodeBySymbolType(preSlotInfo.symbolType, preSlotInfo.count)
                            end
                        else
                            -- actUpdate:stop()
                            if self.m_loadGameSchedule then
                                scheduler.unscheduleGlobal(self.m_loadGameSchedule)
                                self.m_loadGameSchedule = nil
                            end
                            -- 预创建几个slotsNode
                            if self.m_sceneLayer and not tolua.isnull(self.m_sceneLayer) then
                                self.m_sceneLayer:perLoadSLotNodes()
                            end

                            if DEBUG == 2 then
                                print("loadSlotNode - complete")
                            end
                            self:completeCurrentLoad()
                        end
                    end,
                    0.017
                )
                print("loadSlotNode - end true")
                return true
            else
                print("loadSlotNode - end false")
                return false
            end
        end

        -- 将plist 文件全部加载进来
        local preLoadImages = {}

        for i = 1, 20 do
            local pngName = nil
            local plistName = nil
            pngName = string.format("%s%d.png", moduleName, i)
            plistName = string.format("%s%d.plist", moduleName, i)
            if cc.FileUtils:getInstance():isFileExist(pngName) == true and cc.FileUtils:getInstance():isFileExist(plistName) == true then
                preLoadImages[#preLoadImages + 1] = {pngName, plistName}
            end
        end

        --加载关卡的png
        local levelPngList = PreloadPngMap[moduleName]
        if levelPngList ~= nil then
            for k, pngName in ipairs(levelPngList) do
                preLoadImages[#preLoadImages + 1] = {pngName, nil}
            end
        end

        --加载关卡需要的list
        local levelList = self.m_sceneLayer:perLoadLevelList()
        for k, info in ipairs(levelList) do
            preLoadImages[#preLoadImages + 1] = {info[1], info[2]}
        end
        levelList = nil
        local otherlist = self:loadGameOterRes()
        if otherlist and #otherlist > 0 then
            for k, info in ipairs(otherlist) do
                preLoadImages[#preLoadImages + 1] = {info[1], info[2]}
            end
        end
        otherlist = nil
        local totalCount = #preLoadImages
        local leftCount = totalCount
        local loadProcessStep = (Process_LoadGameRes_Plist - Process_LoadLayer) / totalCount

        if leftCount == 0 then
            return loadSlotNode()
        end

        local loadImageComplete
        loadImageComplete = function(...)
            if self.m_clearGameData then
                return
            end
            local loadData = preLoadImages[leftCount]
            if #loadData > 1 then -- 加载plist frame
                local frameCache = cc.SpriteFrameCache:getInstance()
                frameCache:addSpriteFrames(loadData[2])
            end

            leftCount = leftCount - 1
            if leftCount > 0 then
                -- csc 2021-09-08 16:55:23 这里不需要动态计算总进度了,之前已经设置好了总进度
                -- self.m_targetProcessVal = Process_LoadLayer + (totalCount - leftCount) * loadProcessStep
                ---TODO
                local loadData = preLoadImages[leftCount]
                local imageName = loadData[1]

                display.loadImage(imageName, loadImageComplete)
            else
                -- 加载完成 加载小块
                loadSlotNode()
            end
        end

        local function asyncLoadImage()
            local loadData = preLoadImages[leftCount]
            local imageName = loadData[1]

            display.loadImage(imageName, loadImageComplete)
        end

        asyncLoadImage()

        return true
    end
end

function LoadingControl:loadLobbyRes()
    if self.m_nextSceneType == SceneType.Scene_Lobby then
        local successCallback = function()
            self:completeCurrentLoad()
            -- if self.m_sceneLayer.freshLevelNode then
            --     self.m_sceneLayer:freshLevelNode("ReturnLobby")
            -- end
        end

        local lobbyPlist = LoadingResConfig.lobbyPlistRes or {}
        local plistCount = #lobbyPlist
        local loadPlistFunc = function()
            local loadIdx = 0

            if plistCount > 0 then
                local loadCallback = function()
                    loadIdx = loadIdx + 1
                    if loadIdx == plistCount then
                        successCallback()
                    end
                end
                for i = 1, #lobbyPlist do
                    local path = lobbyPlist[i]
                    display.loadImage(path .. ".png", loadCallback)
                end
            else
                successCallback()
            end
        end
        if self.m_preLoadLobbyNodes ~= nil and #self.m_preLoadLobbyNodes > 0 then
            local count = #self.m_preLoadLobbyNodes
            local loadProcessStep = (Process_LoadLobbyRes - self.m_targetProcessVal) / count
            local curProcessStep = self.m_targetProcessVal
            
            if self.m_loadLobbySchedule then
                scheduler.unscheduleGlobal(self.m_loadLobbySchedule)
                self.m_loadLobbySchedule = nil
            end

            self.m_loadLobbySchedule =
                scheduler.scheduleGlobal(
                function()
                    if self.m_pause then
                        return
                    end

                    if self.m_preLoadLobbyNodes ~= nil and #self.m_preLoadLobbyNodes > 0 then
                        local preSlotInfo = self.m_preLoadLobbyNodes[1]
                        local index = (count - #self.m_preLoadLobbyNodes + 1)
                        self.m_targetProcessVal = curProcessStep + index * loadProcessStep
                        table.remove(self.m_preLoadLobbyNodes, 1)
                        if not tolua.isnull(self.m_sceneLayer) then
                            self.m_sceneLayer:preLoadLobbyNode(index, preSlotInfo)
                        end
                    else
                        -- actUpdate:stop()
                        if self.m_loadLobbySchedule then
                            scheduler.unscheduleGlobal(self.m_loadLobbySchedule)
                            self.m_loadLobbySchedule = nil
                        end
                        -- self:completeCurrentLoad()
                        loadPlistFunc()
                    end
                end,
                0.01
            )
            return true
        elseif plistCount > 0 then
            loadPlistFunc()
            return true
        else
            successCallback()
            return false
        end
    end
    return false
end

---
-- 请求game status
--
function LoadingControl:requestGameStatus()
    local _loadingLayer = self:getLoadingLayer()
    if _loadingLayer then
        _loadingLayer:initTxtDL()
    end

    self.m_isLoadRuning = true
    self.m_targetProcessVal = Process_LoadGameStatus
    -- csc 2021-09-08 16:46:37 修改已下载的关卡,进度直接推到 100
    if self.m_bIsDownLoadOver then
        self.m_targetProcessVal = Process_DownLoadOver
    end

    local moduleName = self.m_sceneLayer:getNetWorkModuleName()

    gLobalSendDataManager:getNetWorkSlots():sendActionDataWithEnterGame(moduleName)
    self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.REQ_ENTER_LEVEL)
end

function LoadingControl:gameStatusCallFun(param)
    if param[1] == true then
        local resultData = param[2]
        local levelName = param[3]
        local levelsTable = cjson.decode(resultData.result)
        if levelName == levelsTable.game then
            local configData = resultData.config
            -- release_print("请求进入关卡数据" .. tostring(resultData.result))
            -- print("请求进入关卡数据" .. tostring(resultData.result))
            --设置spin消息校验码
            if levelsTable.validCode then
                globalData.slotRunData:setSpinDataValidCode(levelsTable.validCode)
            end

            util_printLog("请求进入关卡数据" .. tostring(resultData.result))
            -- 存储一下网络数据
            globalData.slotRunData.severGameJsonData = tostring(resultData.result)
            globalData.syncUserConfig(configData)

            if globalData.slotRunData ~= nil and globalData.slotRunData.machineData ~= nil and globalData.slotRunData.machineData.p_betsData ~= nil then
                self.m_sceneLayer:initGameStatusData(levelsTable)
                self.m_bGameStatus = true
                self:completeCurrentLoad()
            else
                self:loadingBackLobby()
                if configData ~= nil then
                    gLobalBuglyControl:luaException("enter level betsData is null 1", tostring(globalData.requestId) .. "," .. tostring(configData.bets) .. "," .. tostring(configData.highLimitBets))
                else
                    gLobalBuglyControl:luaException("enter level betsData is null 2", tostring(globalData.requestId) .. "," .. "configData is null")
                end
            end
        else
            -- 返回大厅
            -- self:loadingBackLobby()
        end
    else
        local errorCode = param[2] or 0
        if DEBUG == 2 and tolua.type(errorCode) == "number" then
            print("请求游戏状态返回失败 " .. errorCode)
        end

        self.m_bGameStatus = false
        if errorCode == BaseProto_pb.GAME_BLOCKED then
            self:showBanLevelLayer()
        else
            self:addUnNetLayer()
        end
        
        self:sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.ERROR, self.m_LogSlots.EnterLevelStepErrorEnum.REQ_ENTER_LEVEL)
    end
end

function LoadingControl:showBanLevelLayer()
    local _scene = display.getRunningScene()
    if _scene then
        -- 提示弹框
        local view = _scene:getChildByName("BanLevelLayer")
        if not view then
            view =
                util_createView(
                "views.dialogs.DialogLayer",
                "Dialog/DowanLoadLevelFailed.csb",
                function()
                    self:loadingBackLobby()
                end,
                nil,
                false,
                {
                    {buttomName = "btn_ok", labelString = "RETURN HOME"}
                }
            )
            view:updateContentTipUI("lb_text", "Something went wrong!")
            view:setName("BanLevelLayer")
            _scene:addChild(view, 1000)
        end
    end
end

function LoadingControl:addUnNetLayer()
    local _loadingLayer = self:getLoadingLayer()
    if _loadingLayer and _loadingLayer:getChildByName("LoadingFixLevelResourcesDialog") then
        -- 有玩家主动弹出的提示弹板不需要弹网络下载提示弹板
        return
    end

    gLobalViewManager:showReConnectNew()
    --     function()
    --         util_nextFrameFunc(
    --             function()
    --                 self:checkNetwork()
    --             end
    --         )
    --     end
    -- )
end

-- function LoadingControl:checkNetwork()
--     if xcyy.GameBridgeLua:checkNetworkIsConnected() == true then
--         -- self:loadingBackLobby()
--         -- self:resetLoading()
--         self:clearGameData()
--         if gLobalGameHeartBeatManager then
--             gLobalGameHeartBeatManager:stopHeartBeat()
--         end
--         util_restartGame()
--     else
--         self:addUnNetLayer()
--     end
-- end

function LoadingControl:loadingBackLobby()
    -- self.m_clickBack = true
    self:clearGameData()
    gLobalViewManager:gotoLobbyByLunch()
end
--清理可能存在的游戏数据
function LoadingControl:clearGameData()
    -- self:stopAllActions()

    self.m_isLoadRuning = true
    if not tolua.isnull(self.m_sceneLayer) then
        local nodeParent = self.m_sceneLayer:getParent()
        if not nodeParent and self.m_sceneLayer:getReferenceCountEx() > 0 then
            release_print("---clearGameData1")
            self.m_sceneLayer:onExit()
            self.m_sceneLayer:removeAllChildren()
            self.m_sceneLayer:cleanup()
            self.m_sceneLayer:release()
        else
            release_print("---clearGameData2")
            self.m_sceneLayer:removeFromParent()
        end
        self.m_sceneLayer = nil
        self.m_clearGameData = true
    end

    self:resetLoading()
    -- 需要手动先清理一遍注册的事件 有的是服务器回调的时候刚好退出导致的bug
    -- gLobalNoticManager:removeAllObservers(self)
end

-- 新的进度条进度计算,用来处理有需要下载的关卡时使用
function LoadingControl:runNewLoadingProgress()
    -- 只要当前有关卡代码 或者 资源需要下载的话,启动定时器
    if self.isDownLoadLevel or self.downloadLevelCodeFlag then
        -- 计算增长到 设定进度 每一帧应该走多少
        local interval = math.min(Process_DownLoading / Process_DownLoadingTime * (1 / 60), 1)
        if self.m_isCsbLoading then
            interval = 0.56
        end
        if self.newLoadingAction == nil then
            -- 改变进度条进度
            self.newLoadingAction =
                scheduler.scheduleGlobal(
                function()
                    if self.m_pause then
                        return
                    end

                    self.m_targetProcessVal = self.m_targetProcessVal + interval

                    if self.m_targetProcessVal >= Process_DownLoading then
                        self.m_targetProcessVal = Process_DownLoading
                    -- 等待下载完毕后进行二段加速
                    end

                    -- print("----csc runNewLoadingProgress self.m_targetProcessVal == "..self.m_targetProcessVal)
                end,
                1 / 60
            )
        end
    end
end

-- 下载完毕之后检测状态
function LoadingControl:downloadOvercheckNewLoading()
    if self.newLoadingAction ~= nil then
        scheduler.unscheduleGlobal(self.newLoadingAction)
        self.newLoadingAction = nil
    end

    -- 当前有资源下载完毕了,启用新的快进逻辑,self.m_processStepVal 增长速率加快

    if self.newLoadingAction == nil then
        -- 改变进度条进度
        self.newLoadingAction =
            scheduler.scheduleGlobal(
            function()
                if self.m_pause then
                    return
                end

                local interval = math.random(Process_DownLoadOverSpeedUpInterval[1], Process_DownLoadOverSpeedUpInterval[2])
                if self.m_isCsbLoading then
                    interval = 0.56
                end
                self.m_processStepVal = interval
                self.m_targetProcessVal = self.m_targetProcessVal + interval

                if self.m_targetProcessVal >= 100 then
                    self.m_targetProcessVal = 100
                end

                if self.m_targetProcessVal == 100 then
                    if self.newLoadingAction ~= nil then
                        scheduler.unscheduleGlobal(self.newLoadingAction)
                        self.newLoadingAction = nil
                    end
                    -- 只要当前有关卡代码 或者 资源需要下载的话,才需要回调下一步
                    if self.isDownLoadLevel or self.downloadLevelCodeFlag then
                        release_print("LoadingControl downLoadLevel is completed!!! dlRes = " .. tostring(self.isDownLoadLevel) .. ", dlCode = " .. tostring(self.downloadLevelCodeFlag))
                        self:completeCurrentLoad()
                        self:resetDownloadLevel()
                    end
                    self.m_bIsDownLoadOver = true
                end
                -- print("----csc downloadOvercheckNewLoading self.m_targetProcessVal == "..self.m_targetProcessVal)
            end,
            1 / 60
        )
    end
end

-- 检测当前 coed 跟 res 的下载状态
function LoadingControl:checkDownLoadFlag(_info)
    if self.m_nextSceneType ~= SceneType.Scene_Game then
        return
    end

    local levelName = _info.p_levelName
    local codeMd5 = _info.p_codemd5
    local resMd5 = _info.p_md5
    local isFreeOpen = self.m_machineData.p_freeOpen or false
    
    local isSupportVersion = util_isSupportVersion("1.8.8", "android") or util_isSupportVersion("1.9.1", "ios")

    --code
    self.downloadLevelCodeFlag = false
    local levelCodeDownState = gLobaLevelDLControl:isDownLoadLevelCode(_info)
    
    if isSupportVersion and isFreeOpen and (not gLobaLevelDLControl:isUpdateFreeOpenLevel(levelName .. "_Code", codeMd5)) then
        if levelCodeDownState ~= 2 then
            -- 不更新，但要设置默认的md5
            gLobaLevelDLControl:setFreeMD5(levelName .. "_Code")
            release_print("checkLevelCodeDownload freeOpen")
        end
    else
        if levelCodeDownState == 1 then
            self.downloadLevelCodeFlag = true
            release_print("checkLevelCodeDownload updateVersion")
        elseif levelCodeDownState == 0 then
            self.downloadLevelCodeFlag = true
            release_print("checkLevelCodeDownload unLoad")
        end
    end

    --res
    self.isDownLoadLevel = false
    local levelResDownState = gLobaLevelDLControl:isDownLoadLevel(_info)
    release_print("checkLevelResDownload start; levelResDownState=" .. tostring(levelResDownState))
    if isFreeOpen and gLobaLevelDLControl:isUpdateFreeOpenLevel(levelName, resMd5) == false then
        if levelResDownState ~= 2 then
            -- 不更新，但要设置默认的md5
            gLobaLevelDLControl:setFreeMD5(levelName)
            release_print("checkLevelResDownload freeOpen")
        end
    elseif levelResDownState == 1 then
        self.isDownLoadLevel = true
        release_print("checkLevelResDownload updateVersion")
    elseif levelResDownState == 0 then
        release_print("checkLevelResDownload unLoad")
        self.isDownLoadLevel = true
    end
end

-- 设置loading 暂停标识
function LoadingControl:setPauseLoading(_bPause)
    self.m_pause = _bPause
end

--[[
@description:  进入关卡 打点
@param  self.m_LogSlots.EnterLevelStepEnum  _type
@param  self.m_LogSlots.EnterLevelStepErrorEnum  _errorCode 
@param  table  _downLoadInfo 下载关卡信息
@param  string  _downloadType 代码下载 还是 资源下载
@param  int  _cppErrorCode  下载出错时 cpp给的错误码
--]]
function LoadingControl:sendEnterLevelLog(_type, _errorCode, _downLoadInfo, _downloadType, _cppErrorCode)
    if not _type then
        return
    end

    local lastLoadingStep = self.m_curLoadingStep
    self.m_curLoadingStep = _type

    local donwLoadInfo = {}
    local faildInfo = {status = "Success"}
    if _downLoadInfo and _downloadType then
        local levelName = _downLoadInfo.p_levelName
        local codeSize = _downLoadInfo.p_codeSize or 1
        local bytesSize = _downLoadInfo.p_bytesSize or 1
        donwLoadInfo.name = levelName
        donwLoadInfo.size = bytesSize
        if _downloadType == "code" then
            donwLoadInfo.name = levelName .. "_Code"
            donwLoadInfo.size = codeSize
        end
    end

    if _type == self.m_LogSlots.EnterLevelStepEnum.START then
        self.m_startTime = xcyy.SlotsUtil:getMilliSeconds()
    elseif _type == self.m_LogSlots.EnterLevelStepEnum.ERROR then
        local errorMsg = self.m_LogSlots:getEnterLevelLogErrorMsg(_errorCode, _cppErrorCode)
        if _errorCode == self.m_LogSlots.EnterLevelStepErrorEnum.CODE_DOWNLOAD_ERROR then
            errorMsg = errorMsg .. (self.m_currCodeAccomplishSizeSize or "0")
        elseif _errorCode == self.m_LogSlots.EnterLevelStepErrorEnum.RES_DOWNLOAD_ERROR then
            errorMsg = errorMsg .. (self.m_currResAccomplishSizeSize or "0")
        end
        faildInfo = {
            status = "Fail",
            code = _errorCode or 99,
            msg = errorMsg,
            ltid = lastLoadingStep
        }
    end

    local costTimeMS = xcyy.SlotsUtil:getMilliSeconds() - self.m_startTime
    self.m_LogSlots:sendEnterLevelLog(_type, donwLoadInfo, faildInfo, costTimeMS) -- 进入关卡打点 初始化开始加载
end


function LoadingControl:getShowDataWeekType()
    if globalData.userRunData.p_serverTime == 0 then
        return 0
    end
    -- 西8区在1970.1.1的Date
    -- local _date1970, _secs1970 = util_UTC2TZ(0)
    local tsSeed = 24*3600
    local _secs1970 = os.time(os.date("!*t", tsSeed))
    if _secs1970 == nil then
        sendBuglyLuaException("timestamp convert err!!")
    end
    local secs1970 = _secs1970 or 0
    -- local date1970 = os.date("*t", secs1970)

    -- 当前时间戳
    local nowTime = tonumber(globalData.userRunData.p_serverTime / 1000)
    -- 西八区时间
    local serverTM = util_UTC2TZ(nowTime, -8)
    local _ts = util_get_time(serverTM)
    local _ss = secs1970 - tsSeed
    local secs = _ts - _ss
    -- 距离1970.1.1的天数
    local _days = secs / (24*3600)
    -- 1970.1.1的起始week (周四)
    local WeekBegan = 3
    -- local b = date1970.yday%7
    -- local WeekBegan = 0
    -- if date1970.wday > b then
    --     WeekBegan = 7 - date1970.wday + b
    -- else
    --     WeekBegan = b - date1970.wday
    -- end

    local week = 1
    local dayW = _days - WeekBegan
    if dayW > 0 then
        if (dayW)%7 > 0 then
            week = math.floor((dayW)/7) + 1
        else
            week = (dayW)/7
        end
    end
    return week
end

-- 随机loading背景图配置
function LoadingControl:loadingLogonBgConfig()
    self.m_configData = nil
    
    -- 搜索路径的处理，此时还没有加载GameStart.lua，不加载"Dynamic/"目录
    -- if CC_DYNAMIC_DOWNLOAD == true then
    --     cc.FileUtils:getInstance():addSearchPath(device.writablePath .. "Dynamic/LoadingBgRes", true)
    -- else
    --     cc.FileUtils:getInstance():addSearchPath("Dynamic/LoadingBgRes/LoadingBgRes", true)
    -- end

    self.m_configData = util_getRequireFile("views/logon/LogonBgConfig")
end

function LoadingControl:getCurrentWeekLoadingBg(viewType) -- 1 Logon  2 LoadingGame
    if self:getShowDataWeekType() < 1 then
        return false, ""
    end
    if not self.m_configData then
        self:loadingLogonBgConfig()
    end
    
    if self.m_configData then
        local checkData = self.m_configData.logonThemes
        if viewType == 2 then
            checkData = self.m_configData.loadingThemes
        end
        local csb_count = #checkData
        local week = self:getShowDataWeekType()
        local chooseIndex = (week - 1) % csb_count + 1
        local chooseCsb = checkData[chooseIndex]
        if chooseCsb then
            return true, chooseCsb
        end
        return false, ""
    end
    return false, ""
end


return LoadingControl
