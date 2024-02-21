--[[
    登陆网络通信模块
    author: 徐袁
    time: 2021-03-03 10:50:05
]]
local BaseNetModel = import(".BaseNetModel")
local LoginNetModel = class("LoginNetModel", BaseNetModel)

-- 请求全局配置表
function LoginNetModel:reqGameGlobalConfig(successCallFunc, failedCallFunc)
    local successFunc = function(protoResult)
        --更新数据
        globalData.syncGameGlobalConfig(protoResult)

        if successCallFunc then
            successCallFunc()
        end
    end

    local _reqData = {}
    _reqData.udid = gLobalSendDataManager:getDeviceUuid()
    
    local _platformType = self.PlatFormType
    if _platformType == 1 then
        _reqData.platform = "Android"
    elseif _platformType == 2 then
        _reqData.platform = "iOS"
    elseif _platformType == 3 then
        _reqData.platform = "Amazon"
    end
    local _platform = device.platform
    if _platform == "mac" then
        _reqData.version = "1.1.1"
    else
        local curVersion = util_getAppVersionCode()
        _reqData.version = curVersion
    end

    self:sendMessage(ProtoConfig.GAME_GLOBAL_CONFIG, _reqData, successFunc, failedCallFunc)
end

-- 苹果登陆
function LoginNetModel:appleLoginGame(appleID, token)
    local appleLoginSuccess = function(protoResult)
        globalData.userRunData.appleID = protoResult.user.udid
        self:loginGame(false, true)
    end

    local appleLoginFailed = function(errorCode, errorData)
        -- login 失败
        gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD, {errorCode, errorData})
    end

    local requestData = {}
    requestData.appleId = appleID
    requestData.identityToken = token
    requestData.udid = globalData.userRunData.userUdid
    requestData.productId = PRODUCTID
    requestData.versionCode = util_convertAppCodeToNumber(xcyy.GameBridgeLua:getAppVersionCode()) -- 获取当前app的版本
    requestData.platform = self:getPlatFormType()

    self:_sendMessage(ProtoConfig.APPLE_LOGIN, requestData, appleLoginSuccess, appleLoginFailed)
end

-- Facebook登陆

--[[
    @desc: 检测登录请求的数据是否合法
    time:2019-04-12 16:22:59
    @return:
]]
function LoginNetModel:checkLoginDataIsLegality(checkData)
    -- 如果请求返回的数据中，关卡列表数据为空， 则表明数据不合法
    if checkData.config.games ~= nil and #checkData.config.games > 0 then
        return true
    end
    return false
end

--[[--
    检查是否封停用户
]]
function LoginNetModel:checkAccountClosure(checkData)
    if checkData and checkData.code ~= nil and checkData.code == BaseProto_pb.CLOSURE_USER then
        return true
    end
    return false
end

-- 发送登录请求
function LoginNetModel:loginGame(isFacebookLogin, isAppleLogin)
    isFacebookLogin = isFacebookLogin or false
    isAppleLogin = isAppleLogin or false

    local loginFailed = function(errorCode, errorData)
        globalData.userRunData.isFbLogin = false
        if isFacebookLogin == true then
            globalFaceBookManager:fbLogOut() --清空token
        end
        -- self:loginGameFailedCallFun(errorCode, errorData)
        gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD, {errorCode, errorData})
        --新GameLoadLog
        gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
    end

    local loginSuccess = function(protoResult)
        if isFacebookLogin then
            globalData.userRunData.isFbLogin = true
        end
        local isAccountClosure = self:checkAccountClosure(protoResult)
        local dataIsLegality = self:checkLoginDataIsLegality(protoResult)
        if isAccountClosure == true then
            gLobalViewManager:showAccountClosureDialog()
        elseif dataIsLegality == true then
            globalData.m_isLogin = true
            globalData.userRunData.loginUserData = protoResult
            globalData:saveUserData(protoResult)
            gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_SUCCESS)
            --新手firebase打点
            globalAdjustManager:checkTriggerNPAdjustLog(AdjustNPEventType.login)
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.Login)
            end
            globalFireBaseManager:sendFireBaseProperty()
            gLobalSendDataManager:getNetWorkFeature():sendSaveFirebaseToken()
        else
            -- self:loginGameFailedCallFun()
            loginFailed()
        end
    end

    -- local _request = self:getProtoRequest(ProtoConfig.LOGIN)
    local _request = {}

    _request.productId = PRODUCTID
    _request.platform = self:getPlatFormType()
    _request.ip = globalPlatformManager:getIp() or ""
    _request.imei = globalPlatformManager:getImei() or ""
    _request.deviceId = globalPlatformManager:getDeviceId()
    _request.osVersion = globalPlatformManager:getSystemVersion() or ""
    _request.appVersion = util_getAppVersionCode() or ""
    _request.resVersion = tostring(util_getUpdateVersionCode(false)) or ""

    if isFacebookLogin == true then
        _request.loginType = "Facebook"
        _request.udid = globalData.userRunData.fbUdid
        globalData.userRunData.userUdid = globalData.userRunData.fbUdid
        gLobalBuglyControl:setId(globalData.userRunData.userUdid)
        --新GameLoadLog
        gLobalSendDataManager:getLogGameLoad():setLoginType("FB")
    elseif isAppleLogin == true then
        _request.loginType = "Apple"
        _request.udid = globalData.userRunData.appleID
        globalData.userRunData.userUdid = globalData.userRunData.appleID
        gLobalBuglyControl:setId(globalData.userRunData.userUdid)
        gLobalSendDataManager:getLogGameLoad():setLoginType("APPLE")
    else
        _request.loginType = "Game"
        globalData.userRunData.userUdid = gLobalSendDataManager:getDeviceUuid()
        _request.udid = globalData.userRunData.userUdid -- 如果是访客模式，用设备ID
        globalData.userRunData.isFbLogin = false
        gLobalBuglyControl:setId(globalData.userRunData.userUdid)
        --新GameLoadLog
        gLobalSendDataManager:getLogGameLoad():setLoginType("GUEST")
    end

    if device.platform == "android" then
        if MARKETSEL == GOOGLE_MARKET then
            local androidID = gLobalSendDataManager:getDeviceId()
            local gpsID = globalPlatformManager:getGoogleAdvertisingID()
            _request.android_id = androidID
            local adjustID = globalAdjustManager:getAdjustID()
            if adjustID ~= nil and adjustID ~= "" then
                _request.adid = tostring(adjustID)
            end
            if gpsID ~= androidID then
                _request.gps_adid = tostring(gpsID)
            end
        end
    elseif device.platform == "ios" then
        _request.adid = globalAdjustManager:getAdjustID() or ""
        _request.idfv = globalPlatformManager:getIDFV() or ""
        _request.idfa = globalAdjustManager:getAdjustIDFA() or ""
    end

    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(12)
    self:sendMessage(ProtoConfig.LOGIN, _request, loginSuccess, loginFailed)
end

return LoginNetModel
