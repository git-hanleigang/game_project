---
-- 处理关卡进入时的热更新处理
--
-- island update on 2018-07-16 14:01:50
-- ios fix
local LoginMgr = require("GameLogin.LoginMgr")
local LoadingResConfig = require("views.loading.LoadingResConfig")
local LogonUpgradeView = class("LogonUpgradeView", util_require("base.BaseView"))

LogonUpgradeView.upgradeCompleteCallFun = nil

--资源下载路径信息
LogonUpgradeView.m_versionUrl = nil
LogonUpgradeView.m_newUpdateVersion = nil

LogonUpgradeView.m_updateVerUrl = nil

LogonUpgradeView.m_updteVerZipUrl = nil
-- LogonUpgradeView.m_updateLastVersion = nil

LogonUpgradeView.m_levelsUrl = nil -- levels json 文件地址
LogonUpgradeView.m_isFoceUpdateV = nil --是否存在强制更新vjson文件的版本  例如V104.json

-- LogonUpgradeView.m_curServerMode = nil --当前版本 -1.未设置 0.正式服 1.测试服 2.预发布 3.上线专用 4.上线备用
LogonUpgradeView.m_curCode70 = nil --当前70小版本号
LogonUpgradeView.m_oriCode70 = nil --远端70小号本号

LogonUpgradeView.m_curVZipCount = nil
LogonUpgradeView.m_curVZipName = nil
LogonUpgradeView.m_curVJsonName = nil
-- 进度条相关
LogonUpgradeView.m_loadingBg = nil
LogonUpgradeView.m_loadingBar = nil
LogonUpgradeView.m_loadingRate = nil
LogonUpgradeView.m_loadingTips = nil
LogonUpgradeView.m_targetProcessVal = nil
LogonUpgradeView.m_currentPercent = nil -- 当前进度
LogonUpgradeView.m_processStepVal = nil -- 下载进度步长，
LogonUpgradeView.m_logonLayer = nil

LogonUpgradeView.m_isRestartGame = nil --是否重启游戏
LogonUpgradeView.m_isDownLoadDynamic = nil --活动促销下载
LogonUpgradeView.m_waitTimes = nil --进度100时间
--加载的顺序和索引
local PER_VAL_INDEX = {
    -- 获取强制公告数据
    PER_VAL_ANNOUNCEMENT = 1,
    -- 获取配置
    PER_VAL_CONFIG = 2,
    -- 检测version.json 移动进度
    PER_VAL_VERSION = 3,
    -- 关卡levels.json
    PER_VAL_LEVELJSON = 4,
    -- 检测v json 移动进度
    PER_VAL_VJSON = 5,
    -- 检测zip包进度
    PER_VAL_ZIP = 6,
    -- 动态下载 Dynamic.json
    PER_VAL_DYNAMIC_JSON = 7,
    -- 动态下载 LOAD资源
    PER_VAL_DYNAMIC_ZIP = 8,
    -- 预加载加载进入大厅的资源
    PER_VAL_LOADPLIST = 9,
    -- 下载完成
    PER_VAL_COMPLETED = 10
}
--平滑滚动占用的进度 PER_VAL_UPDATE+PER_VAL_LIST =100
local PER_VAL_UPDATE = 0

--加载的顺序和值
local PER_VAL_LIST = {
    -- 检查强制公告数据
    5,
    -- 检测网络
    10,
    -- 检测version.json 移动进度
    1,
    -- 关卡levels.json
    1,
    -- 检测v json 移动进度
    1,
    -- 检测zip包进度
    25,
    -- 动态下载 Dynamic.json
    1,
    -- 动态下载 LOAD资源
    50,
    -- 预加载进入大厅中的资源
    5,
    --完成
    1,
    0,
    0
}
local loadBeginTime = nil
local loadVersionCostTime = nil
local loadLevelsCostTime = nil
local loadVJsonCostTime = nil
local loadVZIPCostTime = nil

LogonUpgradeView.m_updateProcessVal = nil --缓慢滚动增长
--Loading提示语
local LOADING_TIPS = LoadingResConfig.DT_loadingBarTip

local function util_string_split(str, split_char, isNumber)
    if isNumber == nil then
        isNumber = false
    end

    local sub_str_tab = {}
    if str == nil or str == "" then
        return sub_str_tab
    end
    local i = 0
    local j = 0
    while true do
        -- 从目标串str第i+1个字符开始搜索指定串
        j = string.find(str, split_char, i + 1)

        if j == nil then
            if isNumber then
                sub_str_tab[#sub_str_tab + 1] = tonumber(string.sub(str, i + 1))
            else
                sub_str_tab[#sub_str_tab + 1] = string.sub(str, i + 1)
            end

            break
        end

        if isNumber then
            sub_str_tab[#sub_str_tab + 1] = tonumber(string.sub(str, i + 1, j - 1))
        else
            sub_str_tab[#sub_str_tab + 1] = string.sub(str, i + 1, j - 1)
        end

        i = j
    end
    return sub_str_tab
end

--获得上一个进度和当前进度
function LogonUpgradeView:getPerVal(index)
    local lastPerVal = 0
    if index <= 1 then
        return lastPerVal, PER_VAL_LIST[1]
    else
        for i = 1, index - 1 do
            lastPerVal = lastPerVal + PER_VAL_LIST[i]
        end
        return lastPerVal, PER_VAL_LIST[index]
    end
end

function LogonUpgradeView:initUI()
    self:createCsbNode("Logon/LoadingBar.csb")

    self.m_loadingBar = self:findChild("loadingBar")
    self.m_loadingBar:setPercent(0)

    self.m_loadingBg = self:findChild("Image_1")

    self.m_loadingRate = self:findChild("loadingRate")
    if self.m_loadingRate then
        self.m_loadingRate:setString("0%")
    end

    self.m_spTipBg = self:findChild("tiao_bg")
    self.m_txtDownload = self:findChild("txtDownload")
    if self.m_txtDownload then
        self.m_txtDownload:setPositionX(-100)
    end
    self.m_txtBytes = self:findChild("txtBytes")
    self.m_loadingTips = self:findChild("loadingTips")
    self.m_loadingTips:setPositionY(self.m_txtDownload:getPositionY())
    self:initTxtDL()
    self:initLoadingTips()

    --流动效果
    self:initClipMask()

    -- self:showCheckUpdateTip( )
    self:showLoadingTip()

    self:initProcess()
end

function LogonUpgradeView:initTxtDL()
    if self.m_txtDownload then
        self.m_txtDownload:setString("")
    end

    if self.m_txtBytes then
        self.m_txtBytes:setString("")
    end

    if self.m_spTipBg then
        self.m_spTipBg:setVisible(true)
    end

    if self.m_loadingTips then
        self.m_loadingTips:setVisible(true)
    end
end

-- 初始化加载提示
function LogonUpgradeView:initLoadingTips()
    local index = math.random(1, #LOADING_TIPS)
    if self.m_loadingTips then
        self.m_loadingTips:setString(LOADING_TIPS[index])
    end
end

function LogonUpgradeView:autoScale()
    local loadingBg = self:findChild("Image_1")
    local tempSize = loadingBg:getContentSize()
    local rate = display.width * 0.85 / tempSize.width
    loadingBg:setScaleX(rate)
    self.m_loadingRate:setPositionX(loadingBg:getPositionX() + tempSize.width / 2 * rate + 10)
end

--裁切实现  流动效果
function LogonUpgradeView:initClipMask()
    -- self:autoScale()

    local clipNode = cc.ClippingNode:create()

    local loadEff = util_createAnimation("Logon/LoadingBarEff.csb")
    self.m_changeClip = loadEff:findChild("panel_clip")
    loadEff:playAction("animation0", true)

    self.m_loadingBar:addChild(clipNode)
    clipNode:addChild(loadEff)
    self.m_clipSize = self.m_loadingBar:getContentSize()

    self.m_changeClip:setContentSize({width = 0, height = self.m_clipSize.height})

    local stencilNode = cc.Node:create()
    local sp_clip = display.newSprite("Logon/ui/loading_jindu2.png")

    stencilNode:addChild(sp_clip)
    clipNode:setStencil(stencilNode)
    clipNode:setPosition(cc.p(self.m_clipSize.width / 2, self.m_clipSize.height / 2))
    clipNode:setInverted(false)
    clipNode:setAlphaThreshold(0.98)
end

function LogonUpgradeView:showCheckUpdateTip()
    self.m_loadingBar:setVisible(false)
    self.m_loadingRate:setVisible(false)
    self.m_loadingBg:setVisible(false)
    self.m_loadingTips:setVisible(false)
    self.m_spTipBg:setVisible(false)
end
function LogonUpgradeView:showLoadingTip()
    self.m_loadingBar:stopAllActions()
    self.m_loadingBg:setVisible(true)
    self.m_loadingBar:setVisible(true)
    self.m_loadingRate:setVisible(true)
    self.m_loadingTips:setVisible(false)
    self.m_spTipBg:setVisible(false)
end
--[[
    @desc: 清理掉 loading过程中 ， loadingbar的action
    time:2019-01-09 21:40:46
]]
function LogonUpgradeView:clearLoadingTips()
    if not tolua.isnull(self.m_loadingBar) and self.m_loadingBar.stopAllActions then
        self.m_loadingBar:stopAllActions()
    end
end

-- 设置目标进度
function LogonUpgradeView:setTargetProcess(value)
    value = value or 0
    self.m_targetProcessVal = math.max(self.m_targetProcessVal, value)
end

-- 初始化进度
function LogonUpgradeView:initProcess()
    self.m_targetProcessVal = 1
    self.m_currentPercent = -1
    self.m_processStepVal = 0.1
    self.m_updateProcessVal = 0
    self.m_lastProcessVal = 0

    local initTarget, initUpdate = self:getInitPercent()
    local _val = 0
    --检测因为前后版本设定进度值不同超过上限问题
    if initTarget > 0 then
        --真实进度等于下载完热更zip包的进度
        local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_ZIP)
        _val = lastPerVal + curPerVal
    else
        local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_ANNOUNCEMENT)
        _val = lastPerVal + curPerVal
    end
    self:clearInitPercent()

    self.m_currentPercent = math.min(initTarget, _val)
    self.m_targetProcessVal = math.max(initTarget, _val)

    -- 热更新后重启标识`
    if initTarget and initTarget > 0 then
        self.m_isUpdateReStartGame = true
    else
        --检测热更新
        self.m_isUpdateReStartGame = false
    end

    self.m_initProcessTarget = initTarget

    return initTarget
end

function LogonUpgradeView:updatePercent(percent)
    self.m_loadingBar:setPercent(percent)
    self.m_loadingRate:setString(math.floor(percent) .. "%")
    if self.m_changeClip and self.m_clipSize then
        self.m_changeClip:setContentSize({width = self.m_clipSize.width * percent / 100, height = self.m_clipSize.height})
    end
end

--[[
    @desc: 检测是否执行热更新
    @param upgradeCompleteCallFun 热更新完成后的回调函数
    time:2018-07-16 14:08:43
    @return:
]]
function LogonUpgradeView:checkUpgrade(logonLayer, upgradeCompleteCallFun)
    self.m_logonLayer = logonLayer
    -- 初始化upgrade 信息
    self.upgradeCompleteCallFun = upgradeCompleteCallFun

    local initTarget = self.m_initProcessTarget
    local percent = initTarget

    if percent > 0 then
        self:updatePercent(percent)
    end
    self:checkUpdateLoadBar()

    self:registerDownLoadCallBack()

    if CC_NETWORK_TEST == true then
        -- 直接进入游戏
        GD_LevelsName = "levels_test.json"
        CC_IS_READ_DOWNLOAD_PATH = false
        self:completeUpgrade()
        return
    end

    if not initTarget or initTarget <= 0 then
        --欢迎音效
        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASHLINK_LOADINGSOUND)
            end,
            0.5
        )
    end

    self:gotoReqGameGlobalConfig()
end

--获得全局数据后检测是否是热更后重启
function LogonUpgradeView:checkReStartGame()
    local serverJsonInfo = globalData.GameConfig.serverAddrConfig
    if globalData.GameConfig.isInitVersionConfig and serverJsonInfo ~= nil then
        LoginMgr:getInstance():setServerUrlInfo(serverJsonInfo)

        self:checkUpgradeVersion()
    else
        self:checkUpgradeVersion()
    end
end

-- 重启
function LogonUpgradeView:restartGame()
    -- 重启前保存log
    local NetworkLog = util_require("network.NetworkLog")
    if NetworkLog ~= nil then
        NetworkLog.saveLogToFile()
    end

    if globalPlatformManager and globalPlatformManager.rebootGame then
        globalPlatformManager:rebootGame()
    else
        if scheduler.unscheduleGlobalAll then
            scheduler.unscheduleGlobalAll()
        end
        xcyy.SlotsUtil:restartGame()
    end
end

--初始进度
function LogonUpgradeView:getInitPercent()
    local initTarget = gLobalDataManager:getNumberByField("UpgradePercentTarget", 0)
    local initUpdate = gLobalDataManager:getNumberByField("UpgradePercentUpdate", 0)
    return initTarget, initUpdate
end
--清除进度
function LogonUpgradeView:clearInitPercent()
    gLobalDataManager:setNumberByField("UpgradePercentTarget", 0)
    gLobalDataManager:setNumberByField("UpgradePercentUpdate", 0)
end
--设置进度
function LogonUpgradeView:setInitPercent(initTarget, initUpdate)
    gLobalDataManager:setNumberByField("UpgradePercentTarget", initTarget)
    gLobalDataManager:setNumberByField("UpgradePercentUpdate", initUpdate)
end

function LogonUpgradeView:completeUpgrade()
    cc.FileUtils:getInstance():purgeCachedEntries()
    if self.m_isRestartGame then
        self.m_isRestartGame = nil
        self:setInitPercent(self.m_currentPercent, self.m_updateProcessVal)
        gLobalDataManager:setNumberByField("ReStartGameStatus", 1)

        -- 重启前处理
        if gLobalRemoveDir and gLobalRemoveDir ~= "" then
            release_print(gLobalRemoveDir)
        end

        if util_stopAllDownloadThread then
            util_stopAllDownloadThread()
        end
        -- 清理下载回调
        local dlCallFunc = function()
        end
        xcyy.HandlerIF:registerDownloadHandler(dlCallFunc, dlCallFunc, dlCallFunc, dlCallFunc)

        --新GameLoadLog
        gLobalSendDataManager:getLogGameLoad():sendNewLog(6)
        if gLobalGameHeartBeatManager then
            gLobalGameHeartBeatManager:stopHeartBeat()
        end
        release_print("completeUpgrade restartGame!")
        self:restartGame()
    else
        -- 热更完就可以加载了
        util_pcallRequire("GameStart")
        --50进度 热更部分已下载
        local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_ZIP)
        self:setTargetProcess(lastPerVal + curPerVal)

        if CC_DYNAMIC_DOWNLOAD == true then
            if util_isSupportVersion("1.9.1", "ios") or util_isSupportVersion("1.8.8", "android") then
                -- 检查动态资源下载
                self:checkLoadDynamicJson()
            else
                self:checkDownloadFreeLevelCode()
            end
        else
            --跳过热更，也跳过自动下载
            self:loadSuccess_DynamicZip()
        end
    end
end

function LogonUpgradeView:checkUpdateLoadBar()
    schedule(
        self,
        function()
            if self.m_isRestartGame then
                -- 需要重启跳出
                return
            end
            --活动促销下载
            if self.m_isDownLoadDynamic then
                self:loadProcess_DynamicZip(globalDynamicDLControl:getPercent())
            end
            -- local _txt = "LogonUpgradeView==>"
            -- _txt  = _txt .. " cur = " .. self.m_currentPercent
            -- _txt  = _txt .. " target = " .. self.m_targetProcessVal
            -- _txt  = _txt .. " step = " .. self.m_processStepVal
            -- printInfo(_txt)
            -- 检测更新进度步长
            if self.m_currentPercent ~= self.m_targetProcessVal --[[or self.m_updateProcessVal~=PER_VAL_UPDATE]] then
                self.m_currentPercent = self.m_currentPercent + self.m_processStepVal
                if self.m_currentPercent > self.m_targetProcessVal then
                    self.m_currentPercent = self.m_targetProcessVal
                end
                -- self.m_updateProcessVal = self.m_updateProcessVal + self.m_processStepVal
                -- if self.m_updateProcessVal > PER_VAL_UPDATE then
                --     self.m_updateProcessVal = PER_VAL_UPDATE
                -- end
                -- print("进度条" .. self.m_currentPercent)
                local curPercent = self.m_currentPercent
                -- + self.m_updateProcessVal
                --进度不能比上次低防止进度条回退
                -- if self.m_lastProcessVal and self.m_lastProcessVal>curPercent then
                --     curPercent = self.m_lastProcessVal
                -- end
                self.m_loadingBar:setPercent(curPercent)

                if self.m_changeClip and self.m_clipSize then
                    self.m_changeClip:setContentSize({width = self.m_clipSize.width * curPercent / 100, height = self.m_clipSize.height})
                end

                if self.m_loadingRate then
                    self.m_loadingRate:setString(math.floor(curPercent) .. "%")
                end
                -- 表明下载完成， 则立即进入游戏
                if curPercent >= 100 then
                    --检测动态下载是否有问题
                    if self.m_isDownLoadDynamic and self.m_waitTimes and self.m_waitTimes > 0 then
                        self.m_waitTimes = self.m_waitTimes - 1
                        if globalDynamicDLControl:getAdvPercent() < 100 then
                            return
                        end
                    end

                    if self.m_isRestartGame then
                        release_print("需要重新启动， 但是没有启动")
                    end
                    release_print("进入游戏")

                    self:clearLoadingTips()

                    if self.upgradeCompleteCallFun ~= nil then
                        self.upgradeCompleteCallFun()
                    end

                    self.upgradeCompleteCallFun = nil
                end
            end
        end,
        0.02
    )
end

function LogonUpgradeView:convertAppCodeToNumber(appCode)
    appCode = appCode or ""
    if appCode == "" then
        return 0
    end
    local strLen = string.len(appCode)
    local targetStr = ""
    local isFirstP = false
    -- 主要是将字符串格式的 带小数点版本号  .. 例如版本号设置为1.4.5 将其改为1.45 利于数字运算
    for i = 1, strLen do
        local cStr = string.sub(appCode, i, i)
        if cStr ~= "." then
            targetStr = targetStr .. cStr
        elseif isFirstP == false then
            targetStr = targetStr .. cStr
            isFirstP = true
        end
    end
    local targetNum = tonumber(targetStr)
    if targetNum == nil then
        return 0
    end
    return targetNum
end

--[[
    @desc: 检测网络是否有问题
    time:2018-07-16 14:43:31
    @return:
]]
function LogonUpgradeView:checkNetWork()
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == true then
        return true
    else
        -- 提示网络问题
        gLobalViewManager:showReConnectNew(
            function()
                self:checkUpgradeVersion()
            end
        )
        return false
    end
    return true
end

function LogonUpgradeView:registerDownLoadCallBack()
    local function loadSuccessCallBack(target, url)
        if url == self.m_versionUrl then
            self:loadSuccess_Version()
        elseif url == self.m_updateVerUrl then
            self:loadSuccess_VJson()
        elseif url == self.m_levelsUrl then
            self:loadSuccess_LevelsJson()
        elseif url == self.m_dynamicUrl then
            self:loadSuccess_DynamicJson()
        elseif url == self.m_updteVerZipUrl then
            self:loadSuccessCallFun_VZip()
        elseif url == "DynamicZip" then
            self:loadSuccess_DynamicZip()
        else
            self:checkFreeLevelCodeState(GlobalEvent.GEvent_UncompressSuccess, url)
        end
    end
    gLobalNoticManager:addObserver(self, loadSuccessCallBack, GlobalEvent.GEvent_UncompressSuccess)

    gLobalNoticManager:addObserver(
        self,
        function(target, downData)
            if downData.url == self.m_versionUrl then
                self:loadProcess_Version(downData)
            elseif downData.url == self.m_levelsUrl then
                self:loadProcess_LevelsJson(downData)
            elseif downData.url == self.m_dynamicUrl then
                self:loadProcess_DynamicJson(downData)
            elseif downData.url == self.m_updateVerUrl then
                self:loadProcess_VJson(downData)
            elseif downData.url == self.m_updteVerZipUrl then
                self:loadProcessCallFun_VZip(downData)
            end
        end,
        GlobalEvent.GEvent_LoadedProcess
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, downData)
            if downData.url == self.m_versionUrl then
                self:loadFaild_Version(downData.errorEnum)
            elseif downData.url == self.m_updateVerUrl then
                self:loadError_VJson(downData.errorEnum)
            elseif downData.url == self.m_updteVerZipUrl then
                self:loadErrorCallFun_VZip(downData.errorEnum)
            elseif downData.url == self.m_levelsUrl then
                self:loadFaild_LevelsJson()
            elseif downData.url == self.m_dynamicUrl then
                self:loadFaild_DynamicJson()
            else
                self:checkFreeLevelCodeState(GlobalEvent.GEvent_LoadedError, downData.url)
            end
        end,
        GlobalEvent.GEvent_LoadedError
    )
end

------------------------------     全局配置检测 START     --------------------------------
function LogonUpgradeView:gotoReqGameGlobalConfig()
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_CONFIG)
    self:setTargetProcess(lastPerVal + curPerVal)

    self:goDelayCallSDK()

    -- 安装后第一次启动
    globalFireBaseManager:firstLaunchLog()

    --请求全局数据
    self:checkReqGameGlobalConfig()
end

-- 延迟启动的SDK
function LogonUpgradeView:goDelayCallSDK()
    if device.platform == "android" then
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/AppActivity"
            
            local adsDebug = LoginMgr:getInstance():isAdsDebug() or false
            local params = {adsDebug}
            local sig = "(Z)V"
            if util_isSupportVersion("1.8.8") then
                local adsMemLimit = tostring(util_lowMemLimit(true))
                params = {adsMemLimit, adsDebug}
                sig = "(Ljava/lang/String;Z)V"
            end
            local ok, ret = luaj.callStaticMethod(className, "goDelayCallSDK", params, sig)
            if not ok then
                return ""
            else
                return ret
            end
        
    elseif device.platform == "ios" then
        if util_isSupportVersion("1.8.5") then
            local params = {}
            if DEBUG ~= 0 then
                params.adsDebug = LoginMgr:getInstance():isAdsDebug()
            end
            -- "https://www.cashtornado-slots.com/privacy.html"
            params.ppUrl = PRIVACY_POLICY
            -- "https://www.cashtornado-slots.com/TermOfService.html"
            params.teamUrl = TERMS_OF_SERVICE

            local ok, ret = luaCallOCStaticMethod("AppController", "goDelayCallSDK", params)
            if not ok then
                return ""
            else
                return ret
            end
        end
    end
end

function LogonUpgradeView:checkReqGameGlobalConfig()
    release_print("checkReqGameGlobalConfig")
    --请求游戏全局配置
    if CC_DYNAMIC_DOWNLOAD == true or CC_GAMEGLOBAL_CONFIG == true then
        -- G_GetNetModel(NetType.Login):reqGameGlobalConfig(successFunc, failedFunc)
        local successFunc = function(data)
            local ok, result = xpcall(
                function()
                    gLobalSendDataManager:getLogGameLoad():sendNewLog(1.2)
                    --更新数据
                    globalData.syncGameGlobalConfig(data)
                end,
                function(_errorMsg)
                    gLobalSendDataManager:getLogGameLoad():sendNewLog(1.5)
                    release_print("loadFaild_ReqGameGlobalConfig syncGameGlobalConfig error")
                    if isMac() then
                        showErrorDialog(_errorMsg)
                    else
                        local strErr = string.format("sys global config error!!  errMsg:%s", tostring(_errorMsg))
                        util_sendToSplunkMsg("reqGlobalConfig", strErr)
                    end
                end
            )
            if (not ok) or (not globalData.GameConfig.isInitVersionConfig) then
                gLobalSendDataManager:getLogGameLoad():sendNewLog(1.6)
                util_sendToSplunkMsg("reqGlobalConfig", "global config num err!! ")
                -- 配置获取失败
                gLobalViewManager:showReConnectNew(
                    function()
                        release_print("ReConnect restartGame!")
                        self:restartGame()
                    end
                )
                release_print("syn GameGlobalConfig failed!!!")
            else
                gLobalSendDataManager:getLogGameLoad():sendNewLog(1.3)
                gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_GLOBALCONFIG_SUCCESS)
            end
        end

        local failedFunc = function(errorCode, errorData)
            -- 组装这个错误信息
            local errorInfo = {}
            errorInfo.errorCode = errorCode
            errorInfo.errorMsg = errorData
            local strErr = string.format("request global config failed!!  errCode:%s; errMsg:%s", tostring(errorCode), tostring(errorData))
            util_sendToSplunkMsg("reqGlobalConfig", strErr)
            gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_GLOBALCONFIG_FAILD, errorInfo)
        end

        -- 已选资源类型
        local _resMode = ""
        if not CC_IS_RELEASE_NETWORK then
            _resMode = LoginMgr:getInstance():getResMode()
            _resMode = (_resMode ~= "Online") and _resMode or ""
        end

        if globalData.GameConfig.clearVerCfg then
            globalData.GameConfig:clearVerCfg()
        end
        gLobalSendDataManager:getLogGameLoad():sendNewLog(1.1)
        gLobalSendDataManager:getNetWorkLogon():reqGameGlobalConfig(_resMode, successFunc, failedFunc)
    else
        self:loadSuccess_ReqGameGlobalConfig()
    end
end
function LogonUpgradeView:loadFaild_ReqGameGlobalConfig(_errorInfo)
    release_print("loadFaild_ReqGameGlobalConfig")
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
    if DEBUG == 0 then
        --请求强制公告数据
        globalAnnouncementManager:requestAnnouncement()
    else
        self:showLoadErrorTipView(nil, _errorInfo)
    end
end

function LogonUpgradeView:loadSuccess_ReqGameGlobalConfig()
    release_print("loadSuccess_ReqGameGlobalConfig")
    -- 获取配置成功，加快步进速度
    self.m_processStepVal = 2.5
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(2)

    self:checkReStartGame()
end
------------------------------     全局配置检测 END     --------------------------------
------------------------------     强制公告数据检测 START     ----------------------------
function LogonUpgradeView:announcementSuccess()
    release_print("announcementSuccess")
    if globalAnnouncementManager:checkAnnouncement(1) then
        globalAnnouncementManager:showAnnouncementUI()
    else
        self:showLoadErrorTipView()
    end
end

function LogonUpgradeView:announcementFaild()
    release_print("announcementFaild")
    self:showLoadErrorTipView()
end
------------------------------     强制公告数据检测 END     ------------------------------
------------------------------     Version 检测     --------------------------------

--[[
    @desc: 检测更新version ，
    time:2018-07-16 14:48:22
    @return:
]]
function LogonUpgradeView:checkUpgradeVersion()
    if device.platform == "mac" then
        --mac读取本地
        self:checkLoadLevelsJson()
        return
    end

    local isConnected = self:checkNetWork()
    if isConnected == true then
        --使用服务器下发的数据
        local content = globalData.GameConfig:getVerInfo()
        self:loadSuccess_Version(content)
    end
end

function LogonUpgradeView:loadFaild_Version(errorCode)
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
    self:showLoadErrorTipView(
        function()
            -- 防止界面关闭时 还在执行回调
            if self.checkUpgradeVersion ~= nil then
                self:checkUpgradeVersion()
            end
        end
    )
end
--[[
    @desc: 显示下载失败提示界面 ，
    time:2018-11-21 17:06:59
    --@callFun: 界面关闭后的回调函数
]]
function LogonUpgradeView:showLoadErrorTipView(callfunc, errorInfo)
    -- 请检查您的网络，或者重新尝试 加载
    gLobalViewManager:showReConnectNew(
        function()
            if callfunc then
                callfunc()
            else
                gLobalDataManager:setNumberByField("ReStartGameStatus", 3)
                if gLobalGameHeartBeatManager then
                    gLobalGameHeartBeatManager:stopHeartBeat()
                end

                release_print("loadErrorTip restartGame!")
                --默认回调是重启游戏
                self:restartGame()
            end
        end,
        nil,
        nil,
        errorInfo
    )
end

function LogonUpgradeView:loadProcess_Version(prcent)
    local loadPercent = prcent.loadPercent
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_VERSION)
    self:setTargetProcess(lastPerVal + curPerVal * loadPercent)
end

function LogonUpgradeView:loadSuccess_Version(content)
    self:showLoadingTip()
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_VERSION)
    self:setTargetProcess(lastPerVal + curPerVal)

    if not content then
        content = globalData.GameConfig:getVerInfo()
        if (not content) or (not next(content)) then
            release_print("loadSuccess_Version json decode error")
            --新GameLoadLog
            gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
            self:loadFaild_Version(DownErrorCode.READ)
            return
        end
    end

    -- if device.platform == "android" then
    --     if MARKETSEL == AMAZON_MARKET then
    --         local amazonContent = content["amazon"]
    --         if amazonContent then
    --             content = amazonContent
    --         end
    --     end
    -- elseif device.platform == "ios" then
    --     local iosContent = content["ios"]
    --     if iosContent then
    --         content = iosContent
    --     end
    -- end

    local newAppVer = content["new_app_version"] -- 最新app version
    local foceUpgradeAppVer = content["foce_upgrade_app_version"] -- 强制更新的版本号
    local newUpdateVer = content["new_update_version"] -- 最新的资源版本号
    local upgradeAppDes = content["upgradeAppDes"]
    local forceUpdateV = content["foce_upgrade_vjson"] --是否存在强制更新的vjson版本
    self.m_newUpdateVersion = newUpdateVer
    -- self:readDownloadInfo(content["download_info"]) --读取下载方案
    local vZipLogFlag = content["zipLogFlag"] --是否发送zip包log
    if vZipLogFlag and vZipLogFlag == 1 then
        gLobalDataManager:setStringByField("downloadVzipLogFlag", "1")
    else
        gLobalDataManager:setStringByField("downloadVzipLogFlag", "0")
    end
    local vZipCheckFlag = content["zipCheckFlag"] --是否检测写入文件的完整性
    if vZipCheckFlag and vZipCheckFlag == 1 then
        gLobalDataManager:setStringByField("downloadVzipCheckFlag", "1")
    else
        gLobalDataManager:setStringByField("downloadVzipCheckFlag", "0")
    end
    --是否在热更前后打印文件路径
    if gLobalSendDataManager:getLogGameLoad().setLogDirectory then
        gLobalSendDataManager:getLogGameLoad():setLogDirectory(content["logDirectoryFlag"])
    end
    -- if self.m_curServerMode and self.m_curServerMode == 3 then
    if LoginMgr:getInstance():isSupportLowUpdateVzip() then
        self.m_curCode70 = gLobalDataManager:getNumberByField("release_update_version", 0) -- 获取本地70小版本号
        self.m_oriCode70 = content["release_update_version"] or 0 --70小版本号
    end

    -- 远端版本信息
    local remoteVer = {
        foceUpgradeAppVer = foceUpgradeAppVer,
        newAppVer = newAppVer,
        forceUpdateV = forceUpdateV,
        upgradeAppDes = upgradeAppDes
    }
    local isUpgrade = self:checkIsUpgradeApp(remoteVer)
    if isUpgrade == false then
        self:checkLoadLevelsJson()
    end
end

--读取下载方案
function LogonUpgradeView:readDownloadInfo(downloadInfo)
    if not downloadInfo then
        return
    end
    local fieldValue = util_getAppVersionCode()
    local curAppVer = self:convertAppCodeToNumber(fieldValue)
    for info, value in pairs(downloadInfo) do
        local apps = util_string_split(info, "~", false)
        if #apps == 1 and self:convertAppCodeToNumber(apps[1]) <= curAppVer then
            self:checkUpdateDownloadType(value)
        elseif #apps == 2 and self:convertAppCodeToNumber(apps[1]) <= curAppVer and self:convertAppCodeToNumber(apps[2]) >= curAppVer then
            self:checkUpdateDownloadType(value)
        end
    end
end
--尝试更新下载方案
function LogonUpgradeView:checkUpdateDownloadType(downloadType)
    if downloadType == 1 then
        --cocos2dx版本
        if device.platform == "android" and util_isSupportVersion("1.4.0") then
            CC_DOWNLOAD_TYPE = downloadType
        elseif device.platform == "ios" then
            CC_DOWNLOAD_TYPE = downloadType
        else
            CC_DOWNLOAD_TYPE = 3
        end
    elseif downloadType == 2 then
        --最老的下载版本-修改解压部分
        if device.platform == "android" and util_isSupportVersion("1.4.0") then
            CC_DOWNLOAD_TYPE = downloadType
        elseif device.platform == "ios" then
            CC_DOWNLOAD_TYPE = downloadType
        else
            --app版本不够走默认值
            CC_DOWNLOAD_TYPE = 3
        end
    elseif downloadType == 3 then
        --多线程版本
        CC_DOWNLOAD_TYPE = downloadType
    else
        --最老的下载版本
        CC_DOWNLOAD_TYPE = downloadType
    end
end

--检测app版本更新
-- function LogonUpgradeView:checkUpgradeApp()
--     local content = nil

--     --使用服务器下发的数据
--     content = globalData.GameConfig.versionData

--     if not content then
--         --新GameLoadLog
--         gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
--         return
--     end
--     local newAppVer = content["new_app_version"] -- 最新app version
--     local foceUpgradeAppVer = content["foce_upgrade_app_version"] -- 强制更新的版本号
--     local upgradeAppDes = content["upgradeAppDes"]
--     local forceUpdateV = content["foce_upgrade_vjson"] --是否存在强制更新的vjson版本
--     -- 远端版本信息
--     local remoteVer = {
--         foceUpgradeAppVer = foceUpgradeAppVer,
--         newAppVer = newAppVer,
--         forceUpdateV = forceUpdateV,
--         upgradeAppDes = upgradeAppDes
--     }
--     self:checkIsUpgradeApp(remoteVer)
-- end

-- 检测app版本更新
function LogonUpgradeView:checkIsUpgradeApp(remoteVer)
    if not remoteVer then
        return false
    end

    local isForceUpgrade = false

    -- 检测是否需要强制更新到新版本
    local fieldValue = util_getAppVersionCode()
    local curAppVer = self:convertAppCodeToNumber(fieldValue)
    if curAppVer < self:convertAppCodeToNumber(remoteVer.newAppVer) then --tonumber(newAppVer) then
        globalData.isUpgradeTips = true
        isForceUpgrade = isForceUpgrade or (self:checkIsForceUpgradeApp(curAppVer, remoteVer.foceUpgradeAppVer))
    end

    -- 获得本地热更版本
    local _hotV = util_getUpdateVersionCode(true)
    isForceUpgrade = isForceUpgrade or (self:checkIsForceUpgradeV(_hotV, remoteVer.forceUpdateV))

    globalData.isForceUpgrade = isForceUpgrade
    -- 检测当前版本是否强制更新
    if globalData.isForceUpgrade == true then
        -- 不在显示 loading bar
        self:showNewAppVersionWin(true, "")
        self.m_loadingBar:setVisible(false)
        return true -- 不在执行后续的下载流程
    end

    return false
end
--[[
    @desc: 显示新版本更新界面
    author:{author}
    time:2018-07-16 19:27:48
    @return:
]]
function LogonUpgradeView:showNewAppVersionWin(isForceUpgrade, upgradeDes)
    local warnView = util_createView("views.logon.NewVersion", isForceUpgrade)

    self.m_logonLayer:addChild(warnView)
end
---
-- 检测是否需要强制更新app版本
--
function LogonUpgradeView:checkIsForceUpgradeApp(curAppVer, foceUpgradeAppVer)
    local isForce = false
    local appStrs = util_string_split(foceUpgradeAppVer, ",", false)
    for i = 1, #appStrs do
        local appVer = appStrs[i]
        local apps = util_string_split(appVer, "~", false)
        if #apps == 1 then
            if curAppVer == self:convertAppCodeToNumber(apps[1]) then --apps[1] then
                isForce = true
                break
            end
        elseif #apps == 2 then
            if self:convertAppCodeToNumber(apps[1]) <= curAppVer and self:convertAppCodeToNumber(apps[2]) >= curAppVer then
                isForce = true
                break
            end
        end
    end

    return isForce
end
-- V版本判断强更
function LogonUpgradeView:checkIsForceUpgradeV(curHotVer, forceUpdateV)
    curHotVer = tonumber(curHotVer or 0) or 0
    forceUpdateV = tonumber(forceUpdateV or 0) or 0

    if forceUpdateV > 0 and curHotVer < forceUpdateV then
        -- 当前热更低于强更版本则需要强更
        return true
    end

    return false
end
------------------------------     Version 检测  END    --------------------------------

------------------------------     levels.json 检测     --------------------------------
function LogonUpgradeView:checkLoadLevelsJson()
    if device.platform == "mac" then
        --mac读取本地
        self:completeUpgrade()
        return
    end

    --使用服务器下发的数据
    self:loadSuccess_LevelsJson(globalData.GameConfig.levelsData)
end

function LogonUpgradeView:loadFaild_LevelsJson()
    release_print("loadFaild_LevelsJson")
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
    self:showLoadErrorTipView()
end
function LogonUpgradeView:loadProcess_LevelsJson(prcent)
    local loadPercent = prcent.loadPercent
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_LEVELJSON)
    self:setTargetProcess(lastPerVal + curPerVal * loadPercent)
end
function LogonUpgradeView:loadSuccess_LevelsJson(levelsContent)
    -- cc.FileUtils:getInstance():purgeCachedEntries()
    if not levelsContent then
        -- 检测下载的文件是否正确
        gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
        self:loadFaild_LevelsJson() -- 这里表明下载成功了， 但是文件内容不对
        return
    end

    release_print("loadSuccess_LevelsJson")
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_LEVELJSON)
    self:setTargetProcess(lastPerVal + curPerVal)
    self:checkUpdateVJson()
end

------------------------------     levels.json 检测  END    --------------------------------
------------------------------     V Json  检测     --------------------------------

function LogonUpgradeView:checkUpdateVJson()
    -- 处理更新
    local fieldValue = util_getUpdateVersionCode(true)
    local curUpdateVersion = tonumber(fieldValue) or 0
    local printMsg = string.format("curUpdateVersion = %d,newUpdateVersion = %d", curUpdateVersion, self.m_newUpdateVersion)
    print(printMsg)
    release_print(printMsg)
    if curUpdateVersion < self.m_newUpdateVersion then
        local vJsonName = "V" .. (curUpdateVersion + 1) .. ".json"
        self.m_curVZipName = "V" .. (curUpdateVersion + 1)
        self.m_curVJsonName = vJsonName
        self.m_curVZipCount = self.m_newUpdateVersion - curUpdateVersion
        self.m_updateVerUrl = Android_VERSION_URL .. vJsonName
        loadBeginTime = xcyy.SlotsUtil:getMilliSeconds()
        if gLobalSendDataManager:getLogGameLoad().setIsUpdateVzip then
            --新增方法判空处理
            gLobalSendDataManager:getLogGameLoad():setIsUpdateVzip(1)
        end
        globalUpgradeDLControl:checkDownloadJson(self.m_updateVerUrl, {key = vJsonName, url = self.m_updateVerUrl, md5 = ""})
    else
        if LoginMgr:getInstance():isSupportLowUpdateVzip() then
            --70
            self:checkUpdate70VJson()
        else
            self:completeUpgrade()
        end
    end
end

--70新增小版本号
function LogonUpgradeView:checkUpdate70VJson()
    local fieldValue = util_getUpdateVersionCode(true)
    local curUpdateVersion = tonumber(fieldValue) or 0
    local appUpdateVersion = tonumber(xcyy.GameBridgeLua:getPackageUpdateVersion())
    local printMsg = string.format("LogonUpgradeView---curUpdateVersion = %d,newUpdateVersion = %d", curUpdateVersion, self.m_newUpdateVersion)
    print(printMsg)
    release_print(printMsg)
    local printMsg = string.format("LogonUpgradeView---curCode70 = %d,oriCode70 = %d", self.m_curCode70, self.m_oriCode70)
    print(printMsg)
    release_print(printMsg)
    if (self.m_curCode70 < self.m_oriCode70) and (curUpdateVersion <= self.m_newUpdateVersion) and (appUpdateVersion < self.m_newUpdateVersion) then
        local vJsonName = "V" .. self.m_newUpdateVersion .. ".json"
        self.m_curVZipName = "V" .. self.m_newUpdateVersion
        self.m_curVJsonName = vJsonName
        self.m_curVZipCount = self.m_oriCode70 - self.m_curCode70
        self.m_updateVerUrl = Android_VERSION_URL .. vJsonName
        loadBeginTime = xcyy.SlotsUtil:getMilliSeconds()
        if gLobalSendDataManager:getLogGameLoad().setIsUpdateVzip then
            --新增方法判空处理
            gLobalSendDataManager:getLogGameLoad():setIsUpdateVzip(1)
        end
        globalUpgradeDLControl:checkDownloadJson(self.m_updateVerUrl, {key = vJsonName, url = self.m_updateVerUrl, md5 = ""})
    else
        self:completeUpgrade()
    end
end

function LogonUpgradeView:loadError_VJson(errorEnum)
    release_print("xcyy 加载V.json 失败")
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
    self:showLoadErrorTipView()
end
function LogonUpgradeView:loadProcess_VJson(prcent)
    local loadPercent = prcent.loadPercent
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_VJSON)
    self:setTargetProcess(lastPerVal + curPerVal * loadPercent)
end
function LogonUpgradeView:loadSuccess_VJson()
    local filePath = device.writablePath .. "/" .. self.m_curVJsonName
    local contents = util_checkJsonDecode(filePath)
    if not contents then -- 读取文件失败
        self:loadError_VJson(DownErrorCode.READ)
        return
    end
    release_print("loadSuccess_VJson success" .. self.m_targetProcessVal)
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_VJSON)
    self:setTargetProcess(lastPerVal + curPerVal)
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(3)
    self:checkDownLoadFile(filePath)
end

------------------------------     V Json  检测  END    --------------------------------

------------------------------     VZIP   检测     --------------------------------

---
-- 根据V.config 判断是否执行下载 zip 资源
--
function LogonUpgradeView:checkDownLoadFile(vFilePath)
    local vFileTable = util_checkJsonDecode(vFilePath)
    if not vFileTable then
        if cc.FileUtils:getInstance():isFileExist(vFilePath) == true then
            cc.FileUtils:getInstance():removeFile(vFilePath)
        end
        --新GameLoadLog
        gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
        self:showLoadErrorTipView()
        return
    end
    local totalM = vFileTable.zipFileSize
    if totalM ~= nil then
        self.m_loadZipTotalSize = string.format("%.1f", totalM)
    else
        self.m_loadZipTotalSize = 0
    end
    local allowDownload = true
    -- self.m_updateLastVersion = vFileTable["update_last_version"]
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(4)
    self.m_updteVerZipUrl = Android_VERSION_URL .. "/" .. self.m_curVZipName .. ".zip"
    loadBeginTime = xcyy.SlotsUtil:getMilliSeconds()
    globalUpgradeDLControl:checkDownloadJson(self.m_updteVerZipUrl, {key = self.m_curVZipName, url = self.m_updteVerZipUrl, md5 = "", size = totalM, isVizp = true})
    release_print("xcyy checkDownLoadFile  开始下载zip")
end

function LogonUpgradeView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function()
            if self.loadSuccess_ReqGameGlobalConfig then
                self:loadSuccess_ReqGameGlobalConfig()
            end
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_GLOBALCONFIG_SUCCESS
    )
    gLobalNoticManager:addObserver(
        self,
        function(params, errorInfo)
            if self.loadFaild_ReqGameGlobalConfig then
                self:loadFaild_ReqGameGlobalConfig(errorInfo)
            end
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_GLOBALCONFIG_FAILD
    )
    gLobalNoticManager:addObserver(
        self,
        function()
            if self.announcementSuccess then
                self:announcementSuccess()
            end
        end,
        "GL_EVENT_ANNOUNCEMENT_SUCCESS"
    )
    gLobalNoticManager:addObserver(
        self,
        function()
            if self.announcementFaild then
                self:announcementFaild()
            end
        end,
        "GL_EVENT_ANNOUNCEMENT_FAILD"
    )
end

function LogonUpgradeView:onExit()
    LogonUpgradeView.super.onExit(self)
    self.freeLevelCodeCor = nil
    self.m_logonLayer = nil
end

function LogonUpgradeView:loadSuccessCallFun_VZip()
    release_print("loadSuccessCallFun_VZip")

    --保存热更信息
    if gLobalSendDataManager:getLogGameLoad().setVZipInfo then
        gLobalSendDataManager:getLogGameLoad():setVZipInfo(self.m_curVZipName, self.m_curVZipCount, self.m_loadZipTotalSize)
    end
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(5)
    -- 修改本地最新版本号
    util_saveUpdateVersionCode(self.m_newUpdateVersion)
    -- 获取本地70小版本号
    if LoginMgr:getInstance():isSupportLowUpdateVzip() then
        self.m_curCode70 = self.m_oriCode70
        gLobalDataManager:setNumberByField("release_update_version", self.m_curCode70)
    end
    --修改进度
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_ZIP)
    self:setTargetProcess(lastPerVal + curPerVal)
    --热更重启标志
    self.m_isRestartGame = true
    self:initTxtDL()
    --下一步
    self:completeUpgrade()
end

function LogonUpgradeView:loadErrorCallFun_VZip(errorEnum)
    -- 下载失败，是否给予提示
    local errMsg = string.format("xcyy 下载V对应的zip包失败: %s", tostring(errorEnum))
    release_print(errMsg)
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
    self:showLoadErrorTipView()
end

function LogonUpgradeView:loadProcessCallFun_VZip(prcent)
    local loadPercent = prcent.loadPercent
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_ZIP)
    self:setTargetProcess(lastPerVal + curPerVal * loadPercent)
    if self.m_txtDownload then
        local txtDL = "LOADING SYSTEM CONFIG"
        self.m_txtDownload:setString(txtDL)
    end

    if self.m_txtBytes then
        local txtBytes = " ["
        txtBytes = txtBytes .. globalUpgradeDLControl:getDLProgress(loadPercent)
        txtBytes = txtBytes .. "]"
        self.m_txtBytes:setString(txtBytes)
        self.m_txtBytes:setPositionPercent({x = 1, y = 0.5})
    end

    if self.m_spTipBg then
        self.m_spTipBg:setVisible(true)
    end
    if self.m_loadingTips then
        self.m_loadingTips:setString("")
        self.m_loadingTips:setVisible(false)
    end
end

------------------------------     VZIP  检测  END    --------------------------------
------------------------------     Dynamic.json 检测     --------------------------------
function LogonUpgradeView:checkLoadDynamicJson()
    self:loadSuccess_DynamicJson()
end

function LogonUpgradeView:loadFaild_DynamicJson()
    release_print("loadFaild_DynamicJson")
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
    self:showLoadErrorTipView()
end

function LogonUpgradeView:loadProcess_DynamicJson(prcent)
    local loadPercent = prcent.loadPercent
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_DYNAMIC_JSON)
    self:setTargetProcess(lastPerVal + curPerVal * loadPercent)
end

function LogonUpgradeView:loadSuccess_DynamicJson()
    -- cc.FileUtils:getInstance():purgeCachedEntries()
    if globalData.GameConfig.resetDynamicData ~= nil then
        globalData.GameConfig:resetDynamicData()
    end
    local content = globalData.GameConfig.dynamicData
    if not content or not next(content) then
        --新GameLoadLog
        gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
        self:loadFaild_DynamicJson()
        return
    end
    release_print("loadSuccess_DynamicJson")

    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_DYNAMIC_JSON)
    self:setTargetProcess(lastPerVal + curPerVal)
    self:checkLoadDynamicZip()
end

------------------------------     Dynamic.json 检测  END    --------------------------------

------------------------------     Dynamic zip 检测     --------------------------------
function LogonUpgradeView:checkLoadDynamicZip()
    globalDynamicDLControl:initDynamicConfig()
    gLobalSendDataManager:getLogGameLoad():sendNewLog(8)
    globalDynamicDLControl:startDownload(0, 0)
    -- if globalDynamicDLControl:IsAdvPercent() then
    if globalDynamicDLControl:getDLCount() > 0 then
        -- 有需要下载的资源
        self.m_isDownLoadDynamic = true
        self.m_waitTimes = 1000 --延迟等待计数0.01*1000 = 10秒缓冲
    else
        self:loadSuccess_DynamicZip()
    end
end

function LogonUpgradeView:loadFaild_DynamicZip()
    release_print("loadFaild_DynamicZip")
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
    self:showLoadErrorTipView()
end

function LogonUpgradeView:loadProcess_DynamicZip(percent)
    --已完成的进度
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_DYNAMIC_ZIP)
    if not globalDynamicDLControl.isDispatcherDLControl or not globalDynamicDLControl:isDispatcherDLControl() then
        -- 根据当前下载的dynamicZip数量显示进度
        local totalCount = globalDynamicDLControl:getDLCount()
        local curCount = globalDynamicDLControl:getCurUnzipCount()
        -- 每一个文件的进度
        local _step = 1 / totalCount
        curPerVal = curPerVal * (curCount - 1 + percent) * _step
    else
        curPerVal = curPerVal * globalDynamicDLControl:getALLDlPercent()
    end

    self:setTargetProcess(lastPerVal + curPerVal)

    if self.m_txtDownload then
        local txtDL = "LOADING RESOURCES"
        -- txtDL = txtDL .. "("..curCount .. "/" .. totalCount .. ")"
        self.m_txtDownload:setString(txtDL)
    end

    if self.m_txtBytes then
        local txtBytes = " ["
        txtBytes = txtBytes .. globalDynamicDLControl:getDLProgress()
        txtBytes = txtBytes .. "]"
        self.m_txtBytes:setString(txtBytes)
        self.m_txtBytes:setPositionPercent({x = 1, y = 0.5})
    end

    if self.m_spTipBg then
        self.m_spTipBg:setVisible(true)
    end
    if self.m_loadingTips then
        self.m_loadingTips:setString("")
        self.m_loadingTips:setVisible(false)
    end
end

function LogonUpgradeView:loadSuccess_DynamicZip()
    --这个里面不要别的代码 如果下载zip包不会走这里
    release_print("loadSuccess_DynamicZip")
    self.m_isDownLoadDynamic = nil
    local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_LOADPLIST)
    self:setTargetProcess(lastPerVal + curPerVal)
    self:initTxtDL()
    self:loadPlistResource()
end

------------------------------     Dynamic zip 检测  END    --------------------------------

--[[
    @desc: 免费关卡代码下载
    author:JohnnyFred
    time:2021-09-07 17:48:35
    return:
]]
function LogonUpgradeView:checkDownloadFreeLevelCode()
    if self.freeLevelCodeCor == nil then
        self.freeLevelCodeCor =
            coroutine.create(
            function()
                local levelsInfo = self:getLevelsInfo()
                if levelsInfo ~= nil and levelsInfo.config ~= nil and levelsInfo.config.ortherInfo ~= nil and levelsInfo.config.ortherInfo.freeOpen ~= nil and levelsInfo.levels ~= nil then
                    for k, v in ipairs(levelsInfo.config.ortherInfo.freeOpen) do
                        local levelInfo = nil
                        for kk, vv in ipairs(levelsInfo.levels) do
                            if vv.levelName == v then
                                levelInfo = vv
                                break
                            end
                        end
                        if levelInfo ~= nil then
                            local downloadInfo = {p_levelName = levelInfo.levelName, p_codemd5 = levelInfo.codemd5}
                            local LevelDLControl = util_getRequireFile("common/LevelDLControl")
                            if LevelDLControl ~= nil then
                                local levelCodeDLControl = LevelDLControl:create()
                                local levelCodeDownState = levelCodeDLControl:isDownLoadLevelCode(downloadInfo)
                                if levelCodeDownState ~= 2 then
                                    levelCodeDLControl:checkDownLoadLevelCode(downloadInfo)
                                    coroutine.yield()
                                end
                            end
                        end
                    end
                end
                self:checkLoadDynamicJson()
                self.freeLevelCodeCor = nil
            end
        )
        util_resumeCoroutine(self.freeLevelCodeCor)
    end
end

--[[
    @desc: 获取levelsInfo
    author:JohnnyFred
    time:2021-09-07 19:30:24
    return:
]]
function LogonUpgradeView:getLevelsInfo()
    local levelsInfo = globalData.GameConfig.levelsData

    return levelsInfo
end

--[[
    @desc: 检查免费关卡下载状态
    author:JohnnyFred
    time:2021-09-07 19:27:59
    return:
]]
function LogonUpgradeView:checkFreeLevelCodeState(state, url)
    local levelsInfo = self:getLevelsInfo()
    if url ~= nil and levelsInfo ~= nil and levelsInfo.config ~= nil and levelsInfo.config.ortherInfo ~= nil and levelsInfo.config.ortherInfo.freeOpen ~= nil then
        for k, v in ipairs(levelsInfo.config.ortherInfo.freeOpen) do
            if state == GlobalEvent.GEvent_UncompressSuccess then
                local findIndex = string.find(url, v .. "_Code")
                if findIndex ~= nil then
                    util_resumeCoroutine(self.freeLevelCodeCor)
                    break
                end
            elseif state == GlobalEvent.GEvent_LoadedError then
                local findIndex = string.find(url, v .. "_Code")
                if findIndex ~= nil then
                    local levelInfo = nil
                    for kk, vv in ipairs(levelsInfo.levels) do
                        if vv.levelName == v then
                            levelInfo = vv
                            break
                        end
                    end
                    local downloadInfo = {p_levelName = levelInfo.levelName, p_codemd5 = levelInfo.codemd5}
                    local LevelDLControl = util_getRequireFile("common/LevelDLControl")
                    if LevelDLControl ~= nil then
                        local levelCodeDLControl = LevelDLControl:create()
                        local levelCodeDownState = levelCodeDLControl:isDownLoadLevelCode(downloadInfo)
                        if levelCodeDownState ~= 2 then
                            levelCodeDLControl:checkDownLoadLevelCode(downloadInfo)
                        end
                    end
                    break
                end
            end
        end
    end
end

function LogonUpgradeView:getVersion(key)
    local md5 = gLobalDataManager:getStringByField("LogonUpgradeView" .. key, "")
    if md5 ~= "" then
        return md5
    end
    return nil
end
--更新版本号或者md5值
function LogonUpgradeView:setVersion(key, md5)
    gLobalDataManager:setStringByField("LogonUpgradeView" .. key, md5)
end

------------------------------     检测下载 促销资源 END   --------------------------------
------------------------------     预加载大厅PLIST资源 START   ------------------------------
function LogonUpgradeView:loadPlistResource()
    local loadIdx = 0
    local lobbyPlist = (LoadingResConfig.lobbyPlistRes or {})
    local plistCount = #lobbyPlist
    local loadCallback = function()
        loadIdx = loadIdx + 1
        local lastPerVal, curPerVal = self:getPerVal(PER_VAL_INDEX.PER_VAL_COMPLETED)

        if loadIdx == plistCount then
            -- 异步加载图片资源完成
            self:setTargetProcess(lastPerVal + curPerVal)
        else
            local per = math.floor(curPerVal * (loadIdx / plistCount))
            self:setTargetProcess(lastPerVal + per)
        end
    end
    for i = 1, #lobbyPlist do
        local path = lobbyPlist[i]
        display.loadImage(path .. ".png", loadCallback)
    end
end
------------------------------     预加载大厅PLIST资源 END   --------------------------------

return LogonUpgradeView
