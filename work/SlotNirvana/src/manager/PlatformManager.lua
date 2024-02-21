local PlatformManager = class("PlatformManager")
--获取平台数据相关
PlatformManager.m_instance = nil
--msgIndex
PlatformManager.KEEP_SCREEN_ON = 1 --保持屏幕长亮
PlatformManager.KEEP_SCREEN_OFF = 2 --关闭屏幕长亮
PlatformManager.OPEN_NOTIFY_ENABLED = 3 --跳转打打开通知界面

PlatformManager.INFO_IS_NOTIFY = 1 --跳转打打开通知界面
PlatformManager.INFO_FIREBASE_TOKEN = 2 --firebasetoken
PlatformManager.INFO_IMEI = 3 --获取手机imei号
PlatformManager.INFO_ANDROID_ID = 4 --获取手机android_id
PlatformManager.INFO_IP = 5 --获取手机ip地址
PlatformManager.INFO_SYSTEM_VERSION = 6 --获取手机系统版本
PlatformManager.INFO_APP_VERSION = 7 --获取游戏版本号
PlatformManager.INFO_PHONE_NAME = 8 --手机型号
PlatformManager.INFO_SYSTEM_NETTYPE = 10 --获取网络状态
PlatformManager.m_systemNetWork = nil --设备网络信息

--设备网络信息类型
PlatformManager.NETWORK_TYPE = {
    NETWORK_INIT = "INIT",
    NETWORK_NONE = "NONE",
    NETWORK_WIFI = "WIFI",
    NETWORK_GPRS = "GPRS",
    NETWORK_HRPD = "HRPD",
    NETWORK_2G = "2G",
    NETWORK_3G = "3G",
    NETWORK_4G = "4G",
    NETWORK_5G = "5G",
    NETWORK_MOBILE = "MOBILE"
}
--android网络类型对应码
PlatformManager.NETWORK_ANDROID_CODE = {
    NETWORK_ANDROID_NONE = "-1",
    NETWORK_ANDROID_WIFI = "10001",
    NETWORK_ANDROID_1xRTT = "7",
    NETWORK_ANDROID_CDMA = "4",
    NETWORK_ANDROID_EDGE = "2",
    NETWORK_ANDROID_EHRPD = "14",
    NETWORK_ANDROID_EVDO_0 = "5",
    NETWORK_ANDROID_EVDO_A = "6",
    NETWORK_ANDROID_EVDO_B = "12",
    NETWORK_ANDROID_GPRS = "1",
    NETWORK_ANDROID_GSM = "16",
    NETWORK_ANDROID_HSDPA = "8",
    NETWORK_ANDROID_HSPA = "10",
    NETWORK_ANDROID_HSPAP = "15",
    NETWORK_ANDROID_HSUPA = "9",
    NETWORK_ANDROID_IDEN = "11",
    NETWORK_ANDROID_IWLAN = "18",
    NETWORK_ANDROID_LTE = "13",
    NETWORK_ANDROID_NR = "20",
    NETWORK_ANDROID_TD_SCDMA = "17",
    NETWORK_ANDROID_UMTS = "3",
    NETWORK_ANDROID_UNKNOWN = "0"
}

PlatformManager.ATTSTATUS_CODE = {
    ATT_NOTDETERMINED = 0,
    ATT_RRESTRICTED = 1,
    ATT_DENIED = 2,
    ATT_AUTHORIZED = 3
}

PlatformManager.SHARE_TYPE = {
    INVITE = 1 --拉新分享
}

function PlatformManager:getInstance()
    if PlatformManager.m_instance == nil then
        PlatformManager.m_instance = PlatformManager.new()
    end
    return PlatformManager.m_instance
end

-- 构造函数
function PlatformManager:ctor()
    self.m_isRebooting = false
end

-- 是否在重启中
function PlatformManager:isRebooting()
    return self.m_isRebooting
end

-- 重启游戏
function PlatformManager:rebootGame(callback)
    if self:isRebooting() then
        -- 防止连续触发两次，导致崩溃
        return
    end

    if callback then
        callback()
    end

    self.m_isRebooting = true
    if scheduler.unscheduleGlobalAll then
        scheduler.unscheduleGlobalAll()
    end
    xcyy.SlotsUtil:restartGame()
end

--调用平台方法
function PlatformManager:sendPlatformMsg(msgIndex)
    if msgIndex and msgIndex == self.KEEP_SCREEN_OFF then
        return
    end

    if msgIndex == self.KEEP_SCREEN_ON then
        if self.curScreenFlag == self.KEEP_SCREEN_ON then
            return
        end
        self.curScreenFlag = self.KEEP_SCREEN_ON
    end

    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyyUtil"

        local ok, ret = luaj.callStaticMethod(className, "sendMsg", {msgIndex})
        if not ok then
            return false
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("AppController", "sendMsg", {msgIndex = msgIndex})
        if not ok then
            return false
        else
            return ret
        end
    end

    if device.platform == "mac" then
    end
end
--获得平台返回数据
function PlatformManager:getPlatformInfo(msgIndex)
    if device.platform == "android" then
        local sig = "(F)Ljava/lang/String;"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyyUtil"
        local ok, ret = luaj.callStaticMethod(className, "getPlatformInfo", {msgIndex}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("AppController", "getPlatformInfo", {type = msgIndex})
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "mac" then
        return "mac_test" .. msgIndex
    end
end

function PlatformManager:openRateUSDialog()
    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("AppController", "openRateUSDialog", {})
        if not ok then
        end
    end

    if util_isSupportVersion("1.9.5", "android") and MARKETSEL == GOOGLE_MARKET then
        local luaj = require("cocos.cocos2d.luaj")
        local sig = "(I;I)V"
        local className = "org/cocos2dx/lua/AppActivity"
        
        local succFunc = function()
            release_print("review: lua complete!")
        end

        local failedFunc = function()
            release_print("review: lua failed!")
        end

        local ok, ret = luaj.callStaticMethod(className, "requestReview", {succFunc, failedFunc})
        if not ok then
            return
        else
            return ret
        end
    end
end

function PlatformManager:getGoogleAdvertisingID()
    if device.platform == "android" then
        local sig = "()Ljava/lang/String;"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local ok, ret = luaj.callStaticMethod(className, "getGoogleAdvertisingID", {}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local advertisingID = gLobalDataManager:getStringByField("advertisingID", "", true)
        if advertisingID == nil or advertisingID == "" then
            local ok, ret = luaCallOCStaticMethod("AppController", "getGoogleAdvertisingID", nil)
            if not ok then
                advertisingID = ""
            else
                if ret ~= nil and ret ~= "0" then
                    advertisingID = ret
                    gLobalDataManager:setStringByField("advertisingID", ret)
                else
                    advertisingID = ""
                end
            end
        end
        return advertisingID
    end

    if device.platform == "mac" then
    end
end

function PlatformManager:getIDFV()
    if device.platform == "ios" then
        -- local idfv = gLobalDataManager:getStringByField("idfv_ios","",true)
        local idfv = gLobalDataManager:getStringByField("idfv_ios", "")
        -- 因为调用此处的时候 gLobalDataManager 还没初始化
        if idfv == nil or idfv == "" then
            local ok, ret = luaCallOCStaticMethod("AppController", "getIDFV", nil)
            if not ok then
                idfv = ""
            else
                if ret ~= nil and ret ~= "0" then
                    idfv = ret
                    -- gLobalDataManager:setStringByField("idfv_ios",ret)
                    gLobalDataManager:setStringByField("idfv_ios", ret) -- 因为调用此处的时候 gLobalDataManager 还没初始化
                else
                    idfv = ""
                end
            end
        end
        return idfv
    else
        return ""
    end
end

function PlatformManager:getAmazonAdID()
    if device.platform == "android" then
        local sig = "()Ljava/lang/String;"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local ok, ret = luaj.callStaticMethod(className, "getAmazonAdID", {}, sig)
        if not ok then
            return ""
        else
            return tostring(ret or "")
        end
    end
    return ""
end

function PlatformManager:getMarketSel()
    local platform = device.platform
    if platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local ok, ret = luaj.callStaticMethod(className, "getMarketSel", {}, "()Ljava/lang/String;")
        if not ok then
            return ""
        else
            return ret
        end
    elseif platform == "ios" then
    else
        return "google"
    end
end

-- 进入前台后逻辑
function PlatformManager:enterForegroundLogic()
    -- if globalData.userRunData:getSpanTimes() >= RESET_GAME_TIME then
    --     -- 后台时间超时不执行
    --     return
    -- end

    local platform = device.platform
    if util_isSupportVersion("1.8.6", "android") and (not util_isSupportVersion("1.8.8", "android")) then
        release_print("enter foreground logic in version 1.8.6-1.8.7")
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local ok, ret = luaj.callStaticMethod(className, "jniEnterForegroundLogic", {})
        if not ok then
        else
        end
    elseif platform == "ios" then

    end
end

function PlatformManager:setScreenRotateAnimFlag(flag)
    local platform = device.platform
    self.screenRotateAnimFlag = flag
    if platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("AppController", "setRootViewControllerRotateAnimFlag", {flag = flag})
        if not ok then
        else
        end
    end
end

function PlatformManager:getScreenRotateAnimFlag()
    return self.screenRotateAnimFlag
end

--获取手机imei号
function PlatformManager:getImei()
    return ""
end

--获取手机android_id
function PlatformManager:getAndroidID()
    if not self.m_androidId then
        self.m_androidId = self:getPlatformInfo(self.INFO_ANDROID_ID)
    end
    return self.m_androidId
end
--获取手机ip地址
function PlatformManager:getIp()
    local ip = self:getPlatformInfo(self.INFO_IP)
    return ip
end
--获取手机系统版本
function PlatformManager:getOsSystemVersion()
    local sys_version = self:getPlatformInfo(self.INFO_SYSTEM_VERSION)
    --1.5.5 版本之前需要取后半部分
    if device.platform == "ios" then
        if not util_isSupportVersion("1.5.5") then
            sys_version = util_string_split(sys_version, "  ")[2]
        end
    end
    release_print("----csc getOsSystemVersion =" .. sys_version)
    return sys_version
end
--获取游戏版本号
function PlatformManager:getSystemVersion()
    local app_version = self:getPlatformInfo(self.INFO_APP_VERSION)
    return app_version
end

-- 1.5.5之后 getOsSystemVersion 不再返回原先的结构,为了不影响之前的 att判断,修改接口适配
function PlatformManager:getOsSystemVersionAtt()
    local version = self:getPlatformInfo(self.INFO_SYSTEM_VERSION)
    if device.platform == "ios" then
        if util_isSupportVersion("1.5.5") then
            version = "test" .. "  " .. version
        end
    end
    release_print("----csc getOsSystemVersionAtt =" .. version)
    return version
end

-- 获取手机型号名称
function PlatformManager:getPhoneName()
    local bVersion = false
    if device.platform == "ios" then
        if util_isSupportVersion("1.5.5") then
            bVersion = true
        end
    elseif device.platform == "android" then
        if util_isSupportVersion("1.4.7") then
            bVersion = true
        end
    end
    local phone_name = ""
    if bVersion then
        phone_name = self:getPlatformInfo(self.INFO_PHONE_NAME)
    end
    return phone_name
end

-- 获取设备id 新的接口获取android 设备的id
function PlatformManager:getDeviceId()
    local deviceId = nil
    if device.platform == "android" then
        deviceId = self:getGoogleAdvertisingID()
        if not deviceId or deviceId == "" then
            deviceId = self:getAndroidID()
        end
    elseif device.platform == "ios" then
        deviceId = self:getAndroidID()
        if not deviceId or deviceId == "00000000-0000-0000-0000-000000000000" or deviceId == "" then
            deviceId = self:getIDFV()
        end
    end
    return deviceId or ""
end
--读取真实设备网络信息
function PlatformManager:readSystemNetWork()
    if device.platform == "ios" then
        if util_isSupportVersion("1.4.5") then
            local ok, ret = luaCallOCStaticMethod("Reachability", "getNetWorkType", {url = "www.apple.com"})
            if ok then
                local netTypeMapInfo = {
                    ["NOTREACHABLE"] = self.NETWORK_TYPE.NETWORK_NONE,
                    ["WIFI"] = self.NETWORK_TYPE.NETWORK_WIFI,
                    ["CTRadioAccessTechnologyGPRS"] = self.NETWORK_TYPE.NETWORK_GPRS,
                    ["CTRadioAccessTechnologyEdge"] = self.NETWORK_TYPE.NETWORK_2G,
                    ["CTRadioAccessTechnologyCDMA1x"] = self.NETWORK_TYPE.NETWORK_2G,
                    ["CTRadioAccessTechnologyWCDMA"] = self.NETWORK_TYPE.NETWORK_3G,
                    ["CTRadioAccessTechnologyHSDPA"] = self.NETWORK_TYPE.NETWORK_3G,
                    ["CTRadioAccessTechnologyHSUPA"] = self.NETWORK_TYPE.NETWORK_3G,
                    ["CTRadioAccessTechnologyCDMAEVDORev0"] = self.NETWORK_TYPE.NETWORK_3G,
                    ["CTRadioAccessTechnologyCDMAEVDORevA"] = self.NETWORK_TYPE.NETWORK_3G,
                    ["CTRadioAccessTechnologyCDMAEVDORevB"] = self.NETWORK_TYPE.NETWORK_3G,
                    ["CTRadioAccessTechnologyeHRPD"] = self.NETWORK_TYPE.NETWORK_HRPD,
                    ["CTRadioAccessTechnologyLTE"] = self.NETWORK_TYPE.NETWORK_4G,
                    ["CTRadioAccessTechnologyNRNSA"] = self.NETWORK_TYPE.NETWORK_5G
                }
                self.m_systemNetWork = netTypeMapInfo[ret] or ret
            end
        end
    elseif device.platform == "android" then
        local netType = self:getPlatformInfo(self.INFO_SYSTEM_NETTYPE)
        if netType ~= "" then
            local netTypeMapInfo = {
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_NONE] = self.NETWORK_TYPE.NETWORK_NONE,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_WIFI] = self.NETWORK_TYPE.NETWORK_WIFI,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_GPRS] = self.NETWORK_TYPE.NETWORK_2G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_CDMA] = self.NETWORK_TYPE.NETWORK_2G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_EDGE] = self.NETWORK_TYPE.NETWORK_2G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_1xRTT] = self.NETWORK_TYPE.NETWORK_2G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_IDEN] = self.NETWORK_TYPE.NETWORK_2G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_GSM] = self.NETWORK_TYPE.NETWORK_2G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_EVDO_A] = self.NETWORK_TYPE.NETWORK_3G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_UMTS] = self.NETWORK_TYPE.NETWORK_3G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_EVDO_0] = self.NETWORK_TYPE.NETWORK_3G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_HSDPA] = self.NETWORK_TYPE.NETWORK_3G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_HSUPA] = self.NETWORK_TYPE.NETWORK_3G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_HSPA] = self.NETWORK_TYPE.NETWORK_3G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_EVDO_B] = self.NETWORK_TYPE.NETWORK_3G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_EHRPD] = self.NETWORK_TYPE.NETWORK_3G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_HSPAP] = self.NETWORK_TYPE.NETWORK_3G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_IWLAN] = self.NETWORK_TYPE.NETWORK_3G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_LTE] = self.NETWORK_TYPE.NETWORK_4G,
                [self.NETWORK_ANDROID_CODE.NETWORK_ANDROID_NR] = self.NETWORK_TYPE.NETWORK_5G
            }
            self.m_systemNetWork = netTypeMapInfo[netType] or netType
        end
    end
    if DEBUG == 2 then
        if self.m_systemNetWork then
            print("-------------------systemNetWork == " .. self.m_systemNetWork)
            release_print("-------------------systemNetWork == " .. self.m_systemNetWork)
        end
    end
end

--获取手机网络信息
function PlatformManager:getSystemNetWork()
    if self.m_systemNetWork then
        return self.m_systemNetWork
    end
    return self.NETWORK_INIT
end

-- 请求OtpDeepLink Code
function PlatformManager:sendOtpDeepLinkRequest(_urlCode, callback)
    local succFunc = function(_, resData)
        if resData:HasField("result") then
            local optResult = cjson.decode(resData.result)
            local errCode = optResult.result
            if errCode == 0 then
                local view = gLobalViewManager:getViewByName("AChargeOtpErrLayer")
                if not tolua.isnull(view) then
                    view:closeUI()
                end

                -- 成功
                if optResult.code and tostring(optResult.code) ~= "" then
                    local view = gLobalViewManager:getViewByName("AChargeOtpCodeLayer")
                    if tolua.isnull(view) then
                        view = util_createView("GameModule.ACharge.views.AChargeOtpCodeLayer")
                        view:setName("AChargeOtpCodeLayer")
                        gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)
                    end
                    if not tolua.isnull(view) then
                        view:updateCode(tostring(optResult.code))
                        view:setOverFunc(callback)
                    end
                elseif optResult.url and tostring(optResult.url) ~= "" then
                    local view = gLobalViewManager:getViewByName("AChargeOtpCodeLayer")
                    if not tolua.isnull(view) then
                        view:closeUI()
                    end
                    cc.Application:getInstance():openURL(tostring(optResult.url))

                    if callback then
                        callback()
                    end
                end
            elseif errCode == 1 then
                local codeView = gLobalViewManager:getViewByName("AChargeOtpCodeLayer")
                if not tolua.isnull(codeView) then
                    codeView:closeUI()
                end
                -- 过期
                local view = gLobalViewManager:getViewByName("AChargeOtpErrLayer")
                if tolua.isnull(view) then
                    view = util_createView("GameModule.ACharge.views.AChargeOtpErrLayer", errCode)
                    view:setName("AChargeOtpErrLayer")
                    
                    gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)
                end
                if not tolua.isnull(view) then
                    view:setOverFunc(callback)
                end
            end
        end
    end

    local failedFunc = function()
        if callback then
            callback()
        end
    end

    gLobalSendDataManager:getNetWorkLogon():sendOtpRequest(_urlCode, succFunc, failedFunc)
end

----------------------------------------Facebook,邮件推送 领奖相关 BEGIN-----------------------------------
function PlatformManager:checkShowFacebookLinkReward(callBack)
    local strFaceBookReward = gLobalDataManager:getStringByField("facebookLinkReward", "", true)
    local faceRewardInfo = nil
    local rewardParam = nil
    if strFaceBookReward ~= nil and strFaceBookReward ~= "" then
        faceRewardInfo = cjson.decode(strFaceBookReward)
        if faceRewardInfo ~= nil then
            for k, v in pairs(faceRewardInfo) do
                rewardParam = v
            end
        end
    end

    if faceRewardInfo ~= nil and rewardParam ~= nil then
        local urlParam = rewardParam.param
        if urlParam ~= nil and urlParam.code ~= nil then
            local _urlCode = tostring(urlParam.code)
            release_print("otpDeepLink:" .. _urlCode)
            local st, _ = string.find(_urlCode, "^CTSCode-")
            if st then
                -- OtpDeepLink Code
                self:sendOtpDeepLinkRequest(_urlCode, callBack)
            else
                local loginCallback = function(flag)
                    if flag then
                        local loginExtendData = globalData.userRunData.loginExtendData
                        if loginExtendData:HasField("linkCode") then
                            if loginExtendData.linkCode.cardDrop then
                                CardSysManager:doDropCardsData(loginExtendData.linkCode.cardDrop, false)
                            end
                            local linkResult = loginExtendData.linkCode.result
                            if linkResult == 0 then
                                if loginExtendData.linkCode.cardDrop ~= nil and #loginExtendData.linkCode.cardDrop > 0 then
                                    CardSysManager:doDropCardsData(loginExtendData.linkCode.cardDrop)
                                end
                                if loginExtendData.linkCode.theme == 1 then
                                    local notifyRewardUI = util_createView("views.NotifyReward.EmailNotifyRewardUI", loginExtendData.linkCode, callBack)
                                    gLobalViewManager:showUI(notifyRewardUI)
                                else
                                    local notifyRewardUI = util_createView("views.NotifyReward.NotifyRewardUI", loginExtendData.linkCode, callBack, 1)
                                    gLobalViewManager:showUI(notifyRewardUI)
                                end
                            elseif linkResult == 2 or linkResult == 3 then
                                -- 2:过期 | 3:已使用
                                local view =
                                    util_createView(
                                    "views.dialogs.DialogLayer",
                                    "Dialog/MaintainLayer.csb",
                                    callBack,
                                    nil,
                                    false,
                                    {
                                        {buttomName = "btn_ok", labelString = "OK"}
                                    }
                                )
                                if view then
                                    if linkResult == 2 then
                                        view:updateContentTipUI("lb_text", "The link is invalid!")
                                    elseif linkResult == 3 then
                                        view:updateContentTipUI("lb_text", "You've claimed the coins of this link before!")
                                    end
                                    gLobalViewManager:showUI(view)
                                end
                            elseif callBack ~= nil then
                                callBack()
                            end
                        elseif callBack ~= nil then
                            callBack()
                        end
                    elseif callBack ~= nil then
                        callBack()
                    end
                end
                gLobalSendDataManager:getNetWorkLogon():sendLoginExtendRequest({["fblinkCode"] = urlParam.code}, loginCallback)
            end
        elseif callBack ~= nil then
            callBack()
        end
        gLobalDataManager:setStringByField("facebookLinkReward", "")
    elseif callBack ~= nil then
        callBack()
    end
end
-----------------------------------------Facebook 领奖相关 END------------------------------------

-- 获取Facebook好友列表
function PlatformManager:getFaceBookFriendList(callBack)
    local platform = device.platform
    if callBack ~= nil then
        if util_isSupportVersion("1.2.9") then
            if platform == "ios" then
                local ok, ret = luaCallOCStaticMethod("FacebookPlugin", "getFriendList", {callBack = callBack})
                if not ok then
                else
                end
            elseif platform == "android" then
                local sig = "(I)V"
                local luaj = require("cocos.cocos2d.luaj")
                local className = "org/cocos2dx/lua/FacebookPlugin"
                local ok, ret = luaj.callStaticMethod(className, "getFriendList", {callBack}, sig)
                if not ok then
                    return ""
                else
                    return ret
                end
            end
        end
    end
end

----------------------------------------AIHelp  BEGIN-----------------------------------
-- AIHELP 获取用户信息
function PlatformManager:getAIHelpData()
    local data = nil
    local newData = nil
    local userRunData = globalData.userRunData
    if userRunData ~= nil then
        local userUdid = userRunData.userUdid
        local level = userRunData.levelNum
        local vipLevel = userRunData.vipLevel
        local register = userRunData.createTime ~= nil and util_chaneTimeFormat(userRunData.createTime / 1000) or "unknown"
        local userName = userRunData.fbName and userRunData.fbName or ""
        local userPayLevel = "unknown"
        local loginUserData = userRunData.loginUserData
        if loginUserData ~= nil then
            -- 计算下用户R级
            if loginUserData.extra == "" then
                userPayLevel = "s" .. 1
            else
                local verStrs = util_string_split(loginUserData.extra, "|")
                userPayLevel = "s" .. verStrs[table.nums(verStrs)]
            end
        end
        data = {
            userUdid = userUdid,
            level = level,
            vipLevel = vipLevel,
            register = register,
            userName = userName,
            userPayLevel = userPayLevel
        }

        -- 新字段有新的命名结构格式
        newData = {
            userId = userUdid,
            userName = userName,
            userTag = userPayLevel,
            userJsonData = {
                userUid = globalData.userRunData.uid,
                userLevel = level,
                userVipLevel = vipLevel,
                userRegisterTime = register
            }
        }
    end
    if globalXSDKThirdPartyManager and globalXSDKThirdPartyManager:isUseNewXcyySDK() then
        return newData
    else
        return data
    end
    return data
end

function PlatformManager:openAIHelpFAQ(_popType)
    -- 需要分析下客户端版本是否满足条件
    _popType = _popType and _popType or "Setting"
    if _popType and (device.platform == "android" or device.platform == "ios") then
        gLobalSendDataManager:getLogFeature():sendClickAIHelpLog(_popType)
    end
    local data = self:getAIHelpData()
    if not data then
        return
    end
    -- 调用
    if globalXSDKThirdPartyManager and globalXSDKThirdPartyManager:isUseNewXcyySDK() then
        globalXSDKThirdPartyManager:openAIHelpFAQ(data)
        return
    end

    if device.platform == "android" then
        local userUdid = data.userUdid
        local level = data.level
        local vipLevel = data.vipLevel
        local register = data.register
        local userName = data.userName
        local userPayLevel = data.userPayLevel

        local sig = "(Ljava/lang/String;IILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyyUtil"
        local ok, ret = luaj.callStaticMethod(className, "openFAQ", {userUdid, level, vipLevel, register, userName, userPayLevel}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("ElvaChatService", "showFAQs", data)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "mac" then
        return "mac"
    end
end

function PlatformManager:openAIHelpRobot(_popType)
    -- 需要分析下客户端版本是否满足条件
    _popType = _popType and _popType or "Setting"
    if _popType and (device.platform == "android" or device.platform == "ios") then
        gLobalSendDataManager:getLogFeature():sendClickAIHelpLog(_popType)
    end
    local data = self:getAIHelpData()
    if not data then
        return
    end
    -- 调用
    if globalXSDKThirdPartyManager and globalXSDKThirdPartyManager:isUseNewXcyySDK() then
        globalXSDKThirdPartyManager:openAIHelpRobot(data)
        return
    end

    if device.platform == "android" then
        local userUdid = data.userUdid
        local level = data.level
        local vipLevel = data.vipLevel
        local register = data.register
        local userName = data.userName
        local userPayLevel = data.userPayLevel

        local sig = "(Ljava/lang/String;IILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyyUtil"
        local ok, ret = luaj.callStaticMethod(className, "openRobot", {userUdid, level, vipLevel, register, userName, userPayLevel}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("ElvaChatService", "showRobot", data)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "mac" then
        return "mac"
    end
end

-- 开始巡检有没有客服回复的未读消息
function PlatformManager:checkAIHelpNewMessage()
    local udid = globalData.userRunData.userUdid

    if globalXSDKThirdPartyManager and globalXSDKThirdPartyManager:isUseNewXcyySDK() then
        globalXSDKThirdPartyManager:startCheckAIHelpNewMessage(udid)
        return
    end

    local userUdid = globalData.userRunData.userUdid
    if device.platform == "android" then
        local sig = "(Ljava/lang/String;)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyyUtil"
        local ok, ret = luaj.callStaticMethod(className, "getNewMessage", {userUdid}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("ElvaChatService", "getNewMessage", {userUdid = userUdid})
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "mac" then
        return "mac"
    end
end
----------------------------------------AIHelp BEGIN-----------------------------------

----------------------------------------付费新接口 BEGIN-----------------------------------

function PlatformManager:buyGoods(itemID, buyType, applicationUserID, privatePayMentKey, callBack, callBack2)
    local platform = device.platform
    if util_isSupportVersion("1.3.3") then
        local data = {
            itemID = itemID,
            buyType = buyType,
            callBack = callBack,
            applicationUserID = applicationUserID,
            privatePayMentKey = privatePayMentKey
        }
        if platform == "ios" then
            local ok, ret = luaCallOCStaticMethod("IAPLayer", "buyGoods", data)
            if not ok then
                gLobalIAPManager:sendBuglyLog(
                    "PlatformManager||buyGoods||failed " ..
                        tostring(ret) ..
                            ",itemID = " ..
                                itemID ..
                                    ",buyType = " ..
                                        buyType ..
                                            ",applicationUserID = " ..
                                                tostring(applicationUserID) ..
                                                    ",privatePayMentKey = " .. tostring(privatePayMentKey) .. ",callBack type = " .. tolua.type(callBack) .. ",callBack =" .. tostring(callBack)
                )
                ok, ret =
                    luaCallOCStaticMethod(
                    "IAPLayer",
                    "buyGoods",
                    {
                        itemID = itemID,
                        buyType = buyType,
                        callBack = callBack,
                        applicationUserID = applicationUserID,
                        privatePayMentKey = applicationUserID
                    }
                )
                if ok then
                    gLobalIAPManager:sendBuglyLog("PlatformManager||buyGoods||callBack2||ok")
                else
                    gLobalIAPManager:sendBuglyLog(
                        "PlatformManager||buyGoods---2222222||failed " ..
                            tostring(ret) ..
                                ",itemID = " ..
                                    itemID ..
                                        ",buyType = " ..
                                            buyType ..
                                                ",applicationUserID = " ..
                                                    tostring(applicationUserID) ..
                                                        ",privatePayMentKey = " .. tostring(privatePayMentKey) .. ",callBack2 type = " .. tolua.type(callBack2) .. ",callBack2 =" .. tostring(callBack2)
                    )
                end
                return ""
            else
                gLobalIAPManager:sendBuglyLog("PlatformManager||buyGoods||ok")
                return ret
            end
        elseif platform == "android" then
            local sig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)V"
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/InappSelectCtrl"
            local classFunctionName = "buyGoods"
            local androidData = {globalData.userRunData.uid, itemID, buyType, callBack}
            -- csc 2022-01-08 新版android iap 修改
            -- if not util_isSupportVersion("1.6.0") then -- 老版本的用 buyonegoods , 只传三个参数
            --     sig = "(Ljava/lang/String;Ljava/lang/String;I)V"
            --     classFunctionName = "buyOneGoods"
            --     androidData = {itemID, buyType, callBack}
            -- end

            local ok, ret = luaj.callStaticMethod(className, classFunctionName, androidData, sig)
            if not ok then
                gLobalIAPManager:sendBuglyLog("PlatformManager||" .. classFunctionName .. "||failed " .. tostring(ret))
                return ""
            else
                gLobalIAPManager:sendBuglyLog("PlatformManager||" .. classFunctionName .. "||ok")
                return ret
            end
        end
    end
end

-- android 消耗把sReceipt 解析后回传
-- ios 获取 orderID 去消耗
function PlatformManager:consumePurchase(orderID, receipt)
    local platform = device.platform
    if util_isSupportVersion("1.3.3") then
        if platform == "ios" then
            local data = {
                orderID = orderID
            }
            local ok, ret = luaCallOCStaticMethod("IAPLayer", "consumePurchase", data)
            if not ok then
                return ""
            else
                return ret
            end
        elseif platform == "android" then
            local receipt = receipt
            local sig = "(Ljava/lang/String;)V"
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/InappSelectCtrl"
            local ok, ret = luaj.callStaticMethod(className, "consumePurchase", {receipt}, sig)
            if not ok then
                return ""
            else
                return ret
            end
        end
    end
end

function PlatformManager:onlyConsumePurchase(orderID, receipt)
    local platform = device.platform
    if device.platform == "mac" then
    end
    if util_isSupportVersion("1.3.3") then
        if platform == "ios" then
            local data = {
                orderID = orderID
            }
            local ok, ret = luaCallOCStaticMethod("IAPLayer", "onlyConsumePurchase", data)
            if not ok then
                return ""
            else
                return ret
            end
        elseif platform == "android" then
            local sig = "(Ljava/lang/String;)V"
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/InappSelectCtrl"
            local ok, ret = luaj.callStaticMethod(className, "onlyConsumePurchase", {receipt}, sig)
            if not ok then
                return ""
            else
                return ret
            end
        end
    end
end

-- 检测事务列表
function PlatformManager:checkUncompleteTransactions(callback)
    local platform = device.platform
    if device.platform == "mac" then
        if callback then
            --组装test 数据
            local json = {}
            local bHas = false
            if table.nums(json) > 0 then
                bHas = true
            end
            local data = {
                hasOrder = bHas,
                jsonData = json
            }
            -- "{\"hasOrder\":false}"
            callback(cjson.encode(data))
        end
    end
    if util_isSupportVersion("1.3.3") then
        if platform == "ios" then
            local ok, ret = luaCallOCStaticMethod("IAPLayer", "checkUncompleteTransactions", {callback = callback})
            if not ok then
                return ""
            else
                return ret
            end
        elseif platform == "android" then
            local sig = "(I)V"
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/InappSelectCtrl"
            local ok, ret = luaj.callStaticMethod(className, "checkUncompleteTransactions", {callback}, sig)
            if not ok then
                return ""
            else
                return ret
            end
        end
    end
end

-- 检测支付中的事物列表
function PlatformManager:checkPendingTransactions(callback)
    local platform = device.platform
    if device.platform == "mac" then
        if callback then
            --组装test 数据
            local json = {}
            local bHas = false
            if table.nums(json) > 0 then
                bHas = true
            end
            local data = {
                hasPendingOrder = bHas,
                jsonData = json
            }
            -- "{\"hasOrder\":false}"
            callback(cjson.encode(data))
        end
    end
    if util_isSupportVersion("1.3.3") then
        if platform == "ios" then
            local ok, ret = luaCallOCStaticMethod("IAPLayer", "checkPendingTransactions", {callback = callback})
            if not ok then
                return ""
            else
                return ret
            end
        elseif platform == "android" then
            local sig = "(I)V"
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/InappSelectCtrl"
            local ok, ret = luaj.callStaticMethod(className, "checkPendingTransactions", {callback}, sig)
            if not ok then
                return ""
            else
                return ret
            end
        end
    end
end

function PlatformManager:removePendingTransactions(orderID)
    if util_isSupportVersion("1.3.3") then
        if device.platform == "ios" then
            local ok, ret = luaCallOCStaticMethod("IAPLayer", "removePendingTransactions", {orderID = orderID})
            if not ok then
                return ""
            else
                return ret
            end
        elseif device.platform == "android" then
            local sig = "(Ljava/lang/String;)V"
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/InappSelectCtrl"
            local ok, ret = luaj.callStaticMethod(className, "removePendingTransactions", {orderID}, sig)
            if not ok then
                return ""
            else
                return ret
            end
        end
    end
end

-- 发起调用向google 获取最新的订单列表
function PlatformManager:queryPurchases()
    if util_isSupportVersion("1.5.7") then
        if device.platform == "android" then
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/InappSelectCtrl"
            local ok, ret = luaj.callStaticMethod(className, "queryPurchases")
            if not ok then
                return ""
            else
                return ret
            end
        end
    end
end
----------------------------------------付费新接口 END-----------------------------------
--遍历文件夹目录(subPath：可写目录下的文件路径，传空则遍历所有可写目录下的文件)
function PlatformManager:traverseDirectory(subPath, callBack)
    local writablePath = cc.FileUtils:getInstance():getWritablePath() .. (subPath or "")
    if device.platform == "ios" then
        if util_isSupportVersion("1.4.5") then
            local ok, ret = luaCallOCStaticMethod("AppController", "traverseDirectory", {dirPath = writablePath, callBack = callBack})
            if not ok then
            else
            end
        end
    elseif device.platform == "android" then
        if util_isSupportVersion("1.4.0") then
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/XcyyUtil"
            local ok, ret = luaj.callStaticMethod(className, "traverseDirectory", {writablePath, callBack})
            if not ok then
            else
            end
        end
    end
end

function PlatformManager:checkATTrackingStatus(_callBack)
    if device.platform == "ios" then
        if util_isSupportVersion("1.4.7") then
            local ok, ret = luaCallOCStaticMethod("AppController", "requestATTracking", {callBack = _callBack})
            if not ok then
            else
            end
        else
            if _callBack then
                _callBack()
            end
        end
    elseif device.platform == "android" or device.platform == "mac" then
        -- android 暂时不用
        if _callBack then
            _callBack()
        end
    end
end

function PlatformManager:gotoSetting(_callBack)
    if device.platform == "ios" then
        if util_isSupportVersion("1.5.9") then
            local ok, ret = luaCallOCStaticMethod("AppController", "gotoSetting", {callBack = _callBack})
            if not ok then
            else
            end
        else
            if _callBack then
                _callBack()
            end
        end
    elseif device.platform == "android" or device.platform == "mac" then
        -- android 暂时不用
        if _callBack then
            _callBack()
        end
    end
end

function PlatformManager:requestNotificationStatus(_callBack)
    if device.platform == "ios" then
        if util_isSupportVersion("1.5.9") then
            local ok, ret = luaCallOCStaticMethod("AppController", "requestNotificationStatus", {callBack = _callBack})
            if not ok then
            else
            end
        else
            if _callBack then
                _callBack()
            end
        end
    elseif device.platform == "android" or device.platform == "mac" then
        -- android 暂时不用
        if _callBack then
            _callBack()
        end
    end
end
---------------------------------------- FaceBook 分享 -----------------------------------
--[[
    --@_url:            分享的链接地址
	--@_title:          分享的标题
	--@_description:    分享的文本内容
	--@_imgUrl:         分享的图片链接
	--@_callBack:       分享后的回调
]]
function PlatformManager:facebookShare(_url, _callback)
    local platform = device.platform
    if platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("FacebookPlugin", "facebookShare", {url = _url, callback = _callback})
        if not ok then
        else
        end
    elseif platform == "android" then
        local sig = "(Ljava/lang/String;I)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/FacebookPlugin"
        local ok, ret = luaj.callStaticMethod(className, "facebookShare", {_url, _callback}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end
end

function PlatformManager:parseFacebookShareClanId(_callback)
    local strFacebookClanID = gLobalDataManager:getStringByField("facebookShareClanId", "", true)
    local faceShareInfo = nil
    local jsonData = nil
    if strFacebookClanID ~= nil and strFacebookClanID ~= "" then
        faceShareInfo = cjson.decode(strFacebookClanID)
        if faceShareInfo ~= nil then
            for k, v in pairs(faceShareInfo) do
                jsonData = v
            end
        end
    end
    if faceShareInfo ~= nil and jsonData ~= nil then
        local urlParam = jsonData.param or {}
        if next(urlParam) then
            -- 玩家通过公会 fb邀请链接 点进来进入游戏
            release_print("----csc 工会id 为 " .. (urlParam.clanId or ""))
            release_print("----csc 邀请人udid 为 " .. (urlParam.udid or ""))
            local clanId = urlParam.clanId
            local udid = urlParam.udid
            local ClanManager = util_require("manager.System.ClanManager"):getInstance()
            ClanManager:requestFbInvite(clanId, udid)

            if _callback ~= nil then
                _callback(true)
            end
        elseif _callback ~= nil then
            _callback()
        end
        gLobalDataManager:setStringByField("facebookShareClanId", "")
    elseif _callback ~= nil then
        _callback()
    end
end

function PlatformManager:getKeyChainValueForKey(_key)
    if DEBUG ~= 0 then
        return
    end
    if _key == nil or _key == "" then
        return
    end
    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("IosAppUUid", "getKeyChainValueForKey", {key = _key})
        if ok then
            return ret
        else
            return nil
        end
    end
end

function PlatformManager:saveKeyChainValueForKey(_key, _value)
    if DEBUG ~= 0 then
        return
    end
    if _key == nil or _key == "" then
        return
    end
    if _value == nil or _value == "" then
        return
    end
    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("IosAppUUid", "saveKeyChainValueForKey", {key = _key, value = _value})
        if not ok then
            return ""
        else
            return ret
        end
    end
end

-- csc 获取att当前状态码
--[[
    0:没有请求过Att
    1:需要管理值
    2:关闭总开关 、 拒绝 att 弹板
    3:用户允许
]]
function PlatformManager:getATTrackingStatusCode()
    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("AppController", "getATTrackingStatusCode")
        if ok then
            return ret
        else
            return nil
        end
    end
end

--[[发送邀请消息:
type: 1:短信,2:邮箱,3:FB邀请
msgInfo:
    type是1:
        content:内容
    type是2:
        title:标题
        content:内容
        persionList:收件人地址（可选）
        linkFlag:是否是链接
    tpye是3:
        content:内容
callBack:分享结果
例:
    globalPlatformManager:sendFuncMsg(1,
    {
        content = "这是内容1 https://link.topultragame.com/cashlink_invite?inviteId=123456 这是内容2",
    },
    function(result)
        local resultInfo = util_cjsonDecode(result)
    end)
    globalPlatformManager:sendFuncMsg(2,
    {
        title = "这是标题",
        content = "这是内容1 <a href='https://link.topultragame.com/cashlink_invite?inviteId=123456'>https://link.topultragame.com/cashlink_invite?inviteId=123456</a> 这是内容2",
        personList = "aaaaaa@qq.com,bbbbbb@gmail.com",
        linkFlag = 1
    },
    function(result)
        local resultInfo = util_cjsonDecode(result)
    end)
    globalPlatformManager:sendFuncMsg(3,
    {
        title = "这是标题",
        content = "这是内容"
    },
    function(result)
        local resultInfo = util_cjsonDecode(result)
    end)
]]
function PlatformManager:sendFuncMsg(type, msgInfo, callBack)
    local platform = device.platform
    if platform == "ios" then
        if util_isSupportVersion("1.7.3") then
            local ok, ret = luaCallOCStaticMethod("AppController", "sendFuncMsg", {type = type, info = cjson.encode(msgInfo), callBack = callBack})
            if ok then
                return ret
            else
                return nil
            end
        end
    elseif platform == "android" then
        if util_isSupportVersion("1.6.5") then
            local sig = "(ILjava/lang/String;I)V"
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/XcyyUtil"
            local ok, ret = luaj.callStaticMethod(className, "sendFuncMsg", {type, cjson.encode(msgInfo), callBack}, sig)
            if not ok then
                return false
            else
                return ret
            end
        end
    end
end

--点击邀请链接进入游戏解析
function PlatformManager:parseCommonLink(_callback, _tip)
    local strInviteUid = gLobalDataManager:getStringByField("commonLink", "", true)
    release_print("strInviteUid-----------------", strInviteUid)
    local inviteShareInfo = nil
    local jsonData = nil
    if strInviteUid ~= nil and strInviteUid ~= "" then
        inviteShareInfo = cjson.decode(strInviteUid)
        if inviteShareInfo ~= nil then
            for k, v in pairs(inviteShareInfo) do
                jsonData = v
            end
        end
    end
    if inviteShareInfo ~= nil and jsonData ~= nil and jsonData ~= "" then
        local urlParam = self:parseUid(jsonData) or {}
        local _type = urlParam.type
        if next(urlParam) then
            if tonumber(_type) == self.SHARE_TYPE.INVITE then --拉新分享
                local invite = G_GetMgr(G_REF.Invite):getData()
                if invite then
                    local uid = urlParam.id
                    if uid ~= nil and uid ~= "" then
                        release_print("uid-----------------", uid)
                        invite:setInviteUid(tonumber(uid))
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_INVITE_UID, _tip)
                    end
                end
            end
        end
    elseif _callback ~= nil then
        _callback()
    end
end

function PlatformManager:parseUid(str)
    local str3 = self:split(str, ",")
    local map = {}
    for i, v in ipairs(str3) do
        local tu = self:split(v, "=")
        map[tu[1]] = tu[2]
    end
    return map
end

function PlatformManager:split(str, delimiter)
    local dLen = string.len(delimiter)
    local newDeli = ""
    for i = 1, dLen, 1 do
        newDeli = newDeli .. "[" .. string.sub(delimiter, i, i) .. "]"
    end

    local locaStart, locaEnd = string.find(str, newDeli)
    local arr = {}
    local n = 1
    while locaStart ~= nil do
        if locaStart > 0 then
            arr[n] = string.sub(str, 1, locaStart - 1)
            n = n + 1
        end

        str = string.sub(str, locaEnd + 1, string.len(str))
        locaStart, locaEnd = string.find(str, newDeli)
    end
    if str ~= nil then
        arr[n] = str
    end
    return arr
end

--删除账号
function PlatformManager:deleteAccount()
    local platform = device.platform
    local uid = globalData.userRunData.loginUserData.displayUid
    local formID = "7c41ce57bf8b43aaba7c45cea2a7d843"
    local appID = nil
    if platform == "ios" then
        appID = "LuckiosGames_platform_a443fccc-0e65-41f8-899f-792ff360a16f"
    elseif platform == "android" then
        if MARKETSEL == "google" then
            appID = "LuckiosGames_platform_bdd4021c-b54b-45c2-9cae-1cefed20d5b8"
        elseif MARKETSEL == "amazon" then
            appID = "LuckiosGames_platform_d5792243-4246-4269-aa01-7e9ebad67548"
        end
    end
    if appID ~= nil then
        cc.Application:getInstance():openURL(string.format("https://aihelp.net/questionnaire/#/?formId=%s&appId=%s&uid=%s", formID, appID, uid))
    end
end

-- 打开FB页面接口
function PlatformManager:openFB(fbUrl, part)
    local url = ""
    part = part or ""
    -- if part ~= "" then
    --     part = part .. "/"
    -- end

    -- 判断是否是fb链接
    local _st, _ed = string.find(fbUrl, "^https://www.facebook.com/")
    if _ed then
        -- if globalXSDKDeviceInfoManager:checkApkExist("FaceBook") then
        if globalDeviceInfoManager:checkApkExist("FaceBook") then
            release_print("openFB -- installed FB APP!!!")
            if device.platform == "android" then
                url = "fb://facewebmodal/f?href=" .. fbUrl
            elseif device.platform == "ios" then
                if part ~= "video" then
                    local _iosLink = string.sub(fbUrl, (_ed + 1), string.len(fbUrl))
                    if part ~= "" then
                        local _, _ed2 = string.find(_iosLink, "^" .. part .. "/")
                        _iosLink = string.sub(_iosLink, (_ed2 + 1), string.len(_iosLink))
                    end
                    url = "fb://profile?id=" .. _iosLink
                end
            end
        end
    else
        release_print("openFB -- not FB Url !!!")
    end

    if url == "" then
        url = fbUrl
    end

    -- release_print("openFB -- url = " .. url)

    cc.Application:getInstance():openURL(url)
end

-- app使用内存
function PlatformManager:getMemoryUsage()
    local mmUsage = 0
    
    if util_isSupportVersion("1.7.9", "ios") then
        local ok, ret = luaCallOCStaticMethod("AppController", "memoryUsage", nil)
        if not ok then
        else
            if ret ~= nil and ret ~= "0" then
                mmUsage = tonumber(ret)
            end
        end
    elseif util_isSupportVersion("1.7.2", "android") then
        local sig = "()Ljava/lang/String;"

        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local ok, ret = luaj.callStaticMethod(className, "getMemoryUsage", {}, sig)
        if ok then
            if ret ~= nil and ret ~= "0" then
                mmUsage = tonumber(ret)
            end
        end
    end

    return mmUsage
end

function PlatformManager:getMemoryUsageStr()
    local mmUsage = self:getMemoryUsage()
    mmUsage = string.format("%.2fM", (mmUsage / 1024 / 1024))
    -- printInfo("--xy--getMemoryUsage = " .. mmUsage)
    return mmUsage
end

-- 是否低可用内存
function PlatformManager:isLowMemUnused()
    local mem = self:getMemoryUnused()
    if mem <= 0 then
        return false
    end

    local limit = 0
    if device.platform == "android" then
        limit = 1024 * 1.6
    elseif device.platform == "ios" then
        limit = 1024
    end

    return limit > mem
end

-- 系统可用内存
function PlatformManager:getMemoryUnused()
    local mmUnused = -1
    
    if util_isSupportVersion("1.9.0", "ios") then
        local ok, ret = luaCallOCStaticMethod("AppController", "memoryUnused", nil)
        if ok then
            if ret ~= nil and ret ~= "0" then
                mmUnused = tonumber(ret)
            end
        end
    elseif util_isSupportVersion("1.8.7", "android") then
        local sig = "()Ljava/lang/String;"

        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local ok, ret = luaj.callStaticMethod(className, "getMemUnused", {}, sig)
        if ok then
            if ret ~= nil and ret ~= "0" then
                mmUnused = tonumber(ret)
            end
        end
    end

    return mmUnused
end

-- 设备振动接口 -- globalPlatformManager:deviceVibrate(6)
function PlatformManager:deviceVibrate(vibrateType)
    local vibrationStatus = gLobalDataManager:getBoolByField(kAllow_Vibration_switch, true)
    if not vibrationStatus then
        return
    end

    local bVersion = false
    if device.platform == "ios" then
        if util_isSupportVersion("1.6.8") then
            bVersion = true
        end
    elseif device.platform == "android" then
        if util_isSupportVersion("1.5.9") then
            bVersion = true
        end
    end
    if not bVersion then
        return
    end

    -- 震动Type --
    vibrateType = vibrateType or 1

    if device.platform == "android" then
        local vibrateTime = {
            [1] = 1000,
            [2] = 900,
            [3] = 800,
            [4] = 700,
            [5] = 600,
            [6] = 500,
            [7] = 400,
            [8] = 300,
            [9] = 200
        }

        local vTime = vibrateTime[vibrateType]
        vTime = vTime or 500

        local sig = "(F)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyyUtil"

        local ok, ret = luaj.callStaticMethod(className, "deviceVibrate", {vTime}, sig)
        if not ok then
            release_print("====deviceVibrate luaj error ==== : " .. tostring(ret))
            return false
        else
            release_print("====deviceVibrate The JNI return is:" .. tostring(ret))
            return ret
        end

        return
    end

    if device.platform == "ios" then --
        --[[
        1：长时振动
        2: 普通短震，3D Touch 中 Peek 震动反馈
        3: 普通短震，3D Touch 中 Pop 震动反馈
        4: 连续三次短震
        5: UIImpactFeedbackStyleLight
        6: UIImpactFeedbackStyleMedium
        7: UIImpactFeedbackStyleHeavy
        8: UIImpactFeedbackStyleSoft
        9: UIImpactFeedbackStyleRigid
        ]] 
        local ok,ret = luaCallOCStaticMethod("AppController", "deviceVibrate", {type = vibrateType})
        if not ok then
            release_print("====deviceVibrate lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("====deviceVibrate lua oc return is:" .. tostring(ret))
            return ret
        end
        return
    end

    if device.platform == "mac" then
        return
    end
end

return PlatformManager
