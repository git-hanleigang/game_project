--
-- LevelDash活动打点
-- Author:{author}
-- Date: 2019-06-24 21:40:00
--
local NetworkLog = require "network.NetworkLog"
local LogGameLoad = class("LogGameLoad", NetworkLog)

function LogGameLoad:ctor()
    NetworkLog.ctor(self)

    self.m_bNewAppLoad = gLobalDataManager:getBoolByField("user_first_load_new_app", true)                      
    gLobalDataManager:setBoolByField("user_first_load_new_app", false)
end

--创建本次购买唯一标识
function LogGameLoad:createLoadSessionId()
    local randomTag = xcyy.SlotsUtil:getMilliSeconds()
    local platform = device.platform
    local id = nil
    if platform == "ios" then
        id = globalPlatformManager:getIDFV() or "ID"
    else
        id = globalPlatformManager:getAndroidID() or "ID"
    end
    self.m_loadSessionId = tostring(id) .. "_" .. "load_" .. randomTag
    gLobalDataManager:setStringByField("createLoadSessionId", self.m_loadSessionId)
    self.m_isClear_flag = gLobalDataManager:getStringByField("appDelegate_isClearRes_flag", "0")
end
--热更后读取上次的sessid
function LogGameLoad:readLoadSessionId()
    self.m_loadSessionId = gLobalDataManager:getStringByField("createLoadSessionId", "")
    self.m_isClear_flag = gLobalDataManager:getStringByField("appDelegate_isClearRes_flag", "0")
end

--是否是热更重启(弃用)
function LogGameLoad:setUpdateReStart(flag)
    self.m_updateReStart = flag
end
--是否有热更新 0.无热更新 1.有热更新
function LogGameLoad:setIsUpdateVzip(type)
    self.m_updateStatus = type
end
function LogGameLoad:setStartPush(flag)
    self.m_startPush = flag
end

function LogGameLoad:setLogDirectory(flag)
    self.m_isLogDirectory = flag
end

function LogGameLoad:setVZipInfo(name, count, size)
    self.m_vZipName = name
    self.m_vZipCount = count
    self.m_vZipSize = size
end

--启动类型:1.正常启动2.超时启动3.更新失败启动 isUpdateReStart是否是热更重启
function LogGameLoad:setStartType(type, isUpdateReStart)
    self.m_startType = type
    self.m_updateReStart = isUpdateReStart
    if isUpdateReStart then
        --热更新重启
        self:readLoadSessionId()
        self:setIsUpdateVzip(1)
        self:sendNewLog(7)
    else
        --不是热更重启创建sessionId
        self:createLoadSessionId()
        self:setIsUpdateVzip(0)
        self:sendNewLog(1)
    end
end
--Auto=自动登陆 Tap=手动选择登陆
function LogGameLoad:setLoginStatus(loginStatus)
    self.m_loginStatus = loginStatus
end
function LogGameLoad:getLoginStatus()
    return self.m_loginStatus
end
--FB=faceBook登陆 GUEST=游客登陆 APPLE=苹果登录
function LogGameLoad:setLoginType(loginType)
    self.m_loginType = loginType
end
function LogGameLoad:getLoginType()
    return self.m_loginType
end

-- 第一次链接创建新用户
function LogGameLoad:setFirstLink(isFirst)
    self.m_isFirstLink = isFirst or false
    local first = self.m_isFirstLink and 1 or 0
end

--下载完成回传信息
function LogGameLoad:setDownLoadInfo(downLoadInfo)
    if not downLoadInfo or not self.m_lastLoadId or self.m_lastLoadId ~= 8 then
        return
    end
    if not self.m_loadNameDetailed then
        self.m_loadNameDetailed = ""
    end
    if not self.m_loadDyCount then
        self.m_loadDyCount = 0
    end
    if not self.m_loadDySize then
        self.m_loadDySize = 0
    end
    local name = downLoadInfo.key or "nil"
    local size = downLoadInfo.size or 0
    local time = downLoadInfo.startTime or xcyy.SlotsUtil:getMilliSeconds()
    local costTime = xcyy.SlotsUtil:getMilliSeconds() - time
    self.m_loadNameDetailed = self.m_loadNameDetailed .. name .. "-" .. costTime .. "-" .. size .. "|"
    self.m_loadDyCount = self.m_loadDyCount + 1
    self.m_loadDySize = self.m_loadDySize + size
end
--动态下载详细信息 文件名-耗时|文件名-耗时|…|...
function LogGameLoad:setLoadNameDetailed()
end
--设置时间戳
function LogGameLoad:updateCostTime()
    self.m_costTime = xcyy.SlotsUtil:getMilliSeconds()
end
--启动步骤loadId
--[[
      * 1.创建loading
      * 2.请求游戏全局配置
      * 3.请求版本配置
      * 4.请求热更下载资源v.zip
      * 5.完成热更下载资源v.zip
      * 6.热更新重启请求
      * 7.热更新重启完成
      * 8.请求下载动态热更新资源
      * 9.完成下载动态热更资源
      * 10.进入登录界面
      * 11.账号绑定
      * 12.登录服务器请求
      * 12.1客户端收到服务器请求
      * 13.进入游戏大厅
      * 99.登录终止
]]
--1.步骤ID
function LogGameLoad:sendNewLog(loadId)
    if not loadId then
        return
    end
    if self.m_updateReStart and loadId < 7 then
        --重启前几步不统计
        return
    end
    local messageData = {
        ssid = self.m_loadSessionId,
        startType = self.m_startType,
        updateStatus = self.m_updateStatus,
        loadId = loadId,
        loginStatus = self.m_loginStatus,
        loginType = self.m_loginType,
        lastLoadId = self.m_lastLoadId,
        clearFlag = self.m_isClear_flag,
        loadStatus = "Normal",
        downLoadType = CC_DOWNLOAD_TYPE,
        nl = self.m_bNewAppLoad and 1 or 0,
        newuser = self.m_isFirstLink and 1 or 0
    }
    --上一个打点的loadid
    self.m_lastLoadId = loadId

    if loadId == 10 then
        --第10步带上下载信息
        messageData.loadNameDetailed = self.m_loadNameDetailed
        messageData.loadDyCount = self.m_loadDyCount
        messageData.loadDySize = self.m_loadDySize
    end
    if loadId == 5 then
        --第5步带上热更信息
        messageData.loadDyName = self.m_vZipName
        messageData.loadDyCount = self.m_vZipCount
        messageData.loadDySize = self.m_vZipSize
    end
    --类型
    if loadId > 9 then
        messageData.startLink = "login"
    else
        messageData.startLink = "loading"
    end
    --成功失败状态
    if loadId >= 99 then
        messageData.result = 0
    else
        messageData.result = 1
    end
    --消耗时间
    if not self.m_costTime then
        messageData.cost = 0
    else
        messageData.cost = (xcyy.SlotsUtil:getMilliSeconds() - self.m_costTime) * 0.001
    end
    --是否通过推送进入
    if self.m_startPush then
        messageData.startPush = self.m_startPush
    else
        messageData.startPush = 0
    end

    -- 新增字段
    local appExistString = globalDeviceInfoManager:getAppExistStatusString({"WeChat", "AliPay", "QQ"})
    if appExistString ~= "" then
        messageData.apps = appExistString
    end

    if device.platform == "android" then
        if MARKETSEL == GOOGLE_MARKET then
            local androidID = gLobalSendDataManager:getDeviceId()
            local gpsID = globalPlatformManager:getGoogleAdvertisingID()
            messageData.android_id = androidID
            local adjustID = globalAdjustManager:getAdjustID()
            if adjustID ~= nil and adjustID ~= "" then
                messageData.adid = tostring(adjustID)
            end
            if gpsID ~= androidID then
                messageData.gps_adid = tostring(gpsID)
            end
        end
    elseif device.platform == "ios" then
        messageData.adid = globalAdjustManager:getAdjustID() or ""
        messageData.idfv = globalPlatformManager:getIDFV() or ""
        messageData.idfa = globalAdjustManager:getAdjustIDFA() or ""
    end

    self:updateCostTime()
    gL_logData:syncUserData()
    gL_logData:syncEventData("GameLoadNew")
    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    if DEBUG == 2 then
        local strData = cjson.encode(messageData)
        print("-----------------------LogGameLoad = " .. strData)
        release_print("-----------------------LogGameLoad = " .. strData)
    end
    self:sendLogData()

    if self.m_isLogDirectory then
        --热更发送文件路径日志 暂时不传
        if loadId == 4 then
            local strData = cjson.encode(messageData)
            if globalPlatformManager and globalPlatformManager.traverseDirectory and util_printErrorDirectory then
                globalPlatformManager:traverseDirectory(
                    "src",
                    function(param)
                        local paramInfo = loadstring(param)()
                        util_printErrorDirectory(paramInfo, strData)
                    end
                )
            end
        end
        --热更后发送文件路径日志
        if loadId == 7 then
            local strData = cjson.encode(messageData)
            if globalPlatformManager and globalPlatformManager.traverseDirectory and util_printErrorDirectory then
                globalPlatformManager:traverseDirectory(
                    "src",
                    function(param)
                        local paramInfo = loadstring(param)()
                        util_printErrorDirectory(paramInfo, strData)
                    end
                )
            end
        end
    end
end

--zip包下载log
function LogGameLoad:sendLoadZipLog(strLog)
    local messageData = {
        startType = self.m_startType,
        loginStatus = self.m_loginStatus,
        loginType = self.m_loginType,
        clearFlag = self.m_isClear_flag,
        zipLog = strLog
    }
    local char = "CMDCostDLTimeEnd"
    local startIndex = string.find(strLog, char)
    if startIndex ~= nil then
        messageData.costTime = string.sub(strLog, 1, startIndex - 1)
    end
    gL_logData:syncUserData()
    gL_logData:syncEventData("GameZip")
    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
    if DEBUG == 2 then
        release_print("---------------------sendLoadZipLog" .. strLog)
    end
end
--gameLoadFail
function LogGameLoad:sendLoadFailLog(downLoadInfo)
    if not downLoadInfo then
        return
    end
    local name = downLoadInfo.key or "nil"
    local size = downLoadInfo.size or 0
    local time = downLoadInfo.startTime or xcyy.SlotsUtil:getMilliSeconds()
    local costTime = xcyy.SlotsUtil:getMilliSeconds() - time

    local messageData = {
        name = name,
        size = size,
        cost = costTime,
        ssid = self.m_loadSessionId,
        startType = self.m_startType,
        updateStatus = self.m_updateStatus,
        loginStatus = self.m_loginStatus,
        loginType = self.m_loginType,
        lastLoadId = self.m_lastLoadId,
        clearFlag = self.m_isClear_flag,
        loadNameDetailed = self.m_loadNameDetailed
    }
    gL_logData:syncUserData()
    gL_logData:syncEventData("Dynamic")
    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
end

--错误路径
function LogGameLoad:sendErrorDirectoryLog(msgType, strLog)
    local messageData = {
        startType = self.m_startType,
        loginStatus = self.m_loginStatus,
        loginType = self.m_loginType,
        msgType = msgType,
        requestId = tostring(globalData.requestId),
        clearFlag = self.m_isClear_flag,
        zipLog = strLog,
        traceback = debug.traceback()
    }
    gL_logData:syncUserData()
    gL_logData:syncEventData("ErrorDirectory")
    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
    release_print("----sendErrorDirectoryLog" .. msgType)
    if DEBUG == 2 then
        release_print("---------------------sendErrorDirectoryLog" .. strLog)
    end
end
--spin结果计算不一致的log
function LogGameLoad:sendSpinErrorLog(strLog)
    local seqID = tostring(globalData.seqId)
    local requestId = tostring(globalData.requestId)
    local serverData = tostring(globalData.slotRunData.severGameJsonData)
    local moduleName = tostring(globalData.slotRunData.gameModuleName)
    local messageData = {
        seqID = seqID,
        requestId = requestId,
        serverData = serverData,
        moduleName = moduleName,
        spinLog = strLog
    }
    gL_logData:syncUserData()
    gL_logData:syncEventData("GameSpinError")
    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
    if DEBUG == 2 then
        release_print("---------------------sendSpinErrorLog" .. strLog)
    end
end

--spin结果计算不一致的log
function LogGameLoad:sendNetErrorLog(errorInfo, errorType)
    local seqID = tostring(globalData.seqId)
    local requestId = tostring(globalData.requestId)
    local serverData = tostring(globalData.slotRunData.severGameJsonData)
    local moduleName = tostring(globalData.slotRunData.gameModuleName)
    errorType = errorType or ""

    local messageData = {
        traceback = debug.traceback(),
        seqID = seqID,
        requestId = requestId,
        serverData = serverData,
        moduleName = moduleName,
        errorType = errorType
    }

    if errorInfo ~= nil then
        messageData.errorCode = errorInfo.errorCode
        messageData.errorMsg = errorInfo.errorMsg
    end

    gL_logData:syncUserData()
    gL_logData:syncEventData("NetError")
    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
end

-- Adjust归因变更
function LogGameLoad:sendAdjustAttribLog(data)
    if not data then
        return
    end

    local messageData = clone(data)
    messageData.tp = "Client"

    gL_logData:syncUserData()
    gL_logData:syncEventData("Adjust")
    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
end

-- 登陆打点
function LogGameLoad:sendLoginUILog(uiName, clickType)
    local messageData = {}
    messageData.pn = uiName
    messageData.tp = clickType
    messageData.et = "Login"
    messageData.en = "LoginLobbyPush"
    gL_logData:syncUserData()
    gL_logData:syncEventData("SystemPopup")
    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
end

return LogGameLoad
