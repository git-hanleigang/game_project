--[[
    @desc: 提供接口
    author:{author}
    time:2021-04-02 16:50:47
    @return:
]]
local XSDKDeviceInfoManager = class("XSDKDeviceInfoManager")

-- 调用的底层文件路径配置
XSDKDeviceInfoManager.ANDROID_JAVA_FILE = "org/cocos2dx/lua/XcyySDK/XcyySDKCommon"
XSDKDeviceInfoManager.IOS_OC_FILE = "XcyySDKCommon"

-- 定义枚举 与底层相同
XSDKDeviceInfoManager.DEVICE_ID = 1 --获取 IDFA
XSDKDeviceInfoManager.DEVICE_IDFV = 2 --获取 IDFV
XSDKDeviceInfoManager.DEVICE_IP = 3 --获取 IP 地址
XSDKDeviceInfoManager.DEVICE_NETWORKTYPE = 4 --获取 网络类型
XSDKDeviceInfoManager.DEVICE_SYSTEM_VERSION = 5 --获取 操作系统版本
XSDKDeviceInfoManager.DEVICE_APP_VERSION = 6 --获取 游戏版本
XSDKDeviceInfoManager.DEVICE_PHONE_NAME = 7 --获取 设备类型
XSDKDeviceInfoManager.DEVICE_NOTIFY_STATUS = 8 --获取 推送状态
XSDKDeviceInfoManager.DEVICE_TIMEZONE = 9 --获取 设备时区
XSDKDeviceInfoManager.DEVICE_LANGUAGE = 10 --获取 设备语言
XSDKDeviceInfoManager.DEVICE_MEMORY = 11 --获取 设备内存
XSDKDeviceInfoManager.DEVICE_CURR_RAM = 12 --获取 设备当前运存
-- 设备网络信息类型
XSDKDeviceInfoManager.NETWORK_TYPE = {
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
-- android网络类型对应码
XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE = {
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

XSDKDeviceInfoManager.NETWORK_ANDROID_CODE = {
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_NONE] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_NONE,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_WIFI] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_WIFI,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_GPRS] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_2G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_CDMA] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_2G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_EDGE] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_2G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_1xRTT] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_2G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_IDEN] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_2G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_GSM] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_2G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_EVDO_A] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_UMTS] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_EVDO_0] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_HSDPA] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_HSUPA] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_HSPA] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_EVDO_B] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_EHRPD] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_HSPAP] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_IWLAN] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_LTE] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_4G,
    [XSDKDeviceInfoManager.NETWORK_ANDROID_TYPE.NETWORK_ANDROID_NR] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_5G
}

XSDKDeviceInfoManager.NETWORK_IOS_CODE = {
    ["NOTREACHABLE"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_NONE,
    ["WIFI"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_WIFI,
    ["CTRadioAccessTechnologyGPRS"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_GPRS,
    ["CTRadioAccessTechnologyEdge"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_2G,
    ["CTRadioAccessTechnologyCDMA1x"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_2G,
    ["CTRadioAccessTechnologyWCDMA"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    ["CTRadioAccessTechnologyHSDPA"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    ["CTRadioAccessTechnologyHSUPA"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    ["CTRadioAccessTechnologyCDMAEVDORev0"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    ["CTRadioAccessTechnologyCDMAEVDORevA"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    ["CTRadioAccessTechnologyCDMAEVDORevB"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_3G,
    ["CTRadioAccessTechnologyeHRPD"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_HRPD,
    ["CTRadioAccessTechnologyLTE"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_4G,
    ["CTRadioAccessTechnologyNRNSA"] = XSDKDeviceInfoManager.NETWORK_TYPE.NETWORK_5G
}

XSDKDeviceInfoManager.IOS_PHONENAME = {
    --iPhone
    ["iPhone1,1"] = "iPhone 1G",
    ["iPhone1,2"] = "iPhone 3G",
    ["iPhone2,1"] = "iPhone 3GS",
    ["iPhone3,1"] = "iPhone 4G",
    ["iPhone3,2"] = "iPhone 4 Verizon",
    ["iPhone4,1"] = "iPhone 4s",
    ["iPhone5,2"] = "iPhone 5",
    ["iPhone5,3"] = "iPhone 5c",
    ["iPhone5,4"] = "iPhone 5c",
    ["iPhone6,1"] = "iPhone 5s",
    ["iPhone6,2"] = "iPhone 5s",
    ["iPhone7,1"] = "iPhone 6 Plus",
    ["iPhone7,2"] = "iPhone 6",
    ["iPhone8,1"] = "iPhone 6s",
    ["iPhone8,2"] = "iPhone 6s Plus",
    ["iPhone8,4"] = "iPhone SE",
    ["iPhone9,1"] = "iPhone 7",
    ["iPhone9,2"] = "iPhone 7 Plus",
    ["iPhone9,3"] = "iPhone 7",
    ["iPhone9,4"] = "iPhone 7 Plus",
    ["iPhone10,1"] = "iPhone 8 Global",
    ["iPhone10,2"] = "iPhone 8 Plus Global",
    ["iPhone10,3"] = "iPhone X Global",
    ["iPhone10,4"] = "iPhone 8 GSM",
    ["iPhone10,5"] = "iPhone 8 Plus GSM",
    ["iPhone10,6"] = "iPhone X GSM",
    ["iPhone11,2"] = "iPhone XS ",
    ["iPhone11,4"] = "iPhone XS Max (China)",
    ["iPhone11,6"] = "iPhone XS Max",
    ["iPhone11,8"] = "iPhone XR",
    ["iPhone12,1"] = "iPhone 11",
    ["iPhone12,3"] = "iPhone 11 Pro",
    ["iPhone12,5"] = "iPhone 11 Pro Max",
    ["iPhone13,1"] = "iPhone 12 Mini",
    ["iPhone13,2"] = "iPhone 12",
    ["iPhone13,3"] = "iPhone 12 Pro",
    ["iPhone13,4"] = "iPhone 12 Pro Max",
    ["iPhone14,4"] = "iPhone 13 mini",
    ["iPhone14,5"] = "iPhone 13",
    ["iPhone14,2"] = "iPhone 13 Pro",
    ["iPhone14,3"] = "iPhone 13 Pro Max",
    ["iPhone14,7"] = "iPhone 14",
    ["iPhone14,8"] = "iPhone 14 Plus",
    ["iPhone15,2"] = "iPhone 14 Pro",
    ["iPhone15,3"] = "iPhone 14 Pro Max",
    ["iPhone15,4"] = "iPhone 15",
    ["iPhone15,5"] = "iPhone 15 Plus",
    ["iPhone16,1"] = "iPhone 15 Pro",
    ["iPhone16,2"] = "iPhone 15 Pro Max",
    -- iPad
    ["iPad1,1"] = "iPad 1 ",
    ["iPad2,1"] = "iPad 2",
    ["iPad2,2"] = "iPad 2",
    ["iPad2,3"] = "iPad 2",
    ["iPad2,4"] = "iPad 2",
    ["iPad3,1"] = "iPad 3",
    ["iPad3,2"] = "iPad 3",
    ["iPad3,3"] = "iPad 3",
    ["iPad3,4"] = "iPad 4",
    ["iPad3,5"] = "iPad 4",
    ["iPad3,6"] = "iPad 4",
    ["iPad4,1"] = "iPad Air",
    ["iPad4,2"] = "iPad Air",
    ["iPad4,3"] = "iPad Air",
    ["iPad5,3"] = "iPad Air 2",
    ["iPad5,4"] = "iPad Air 2",
    ["iPad6,3"] = "iPad Pro (9.7-inch)",
    ["iPad6,4"] = "iPad Pro (9.7-inch)",
    ["iPad6,7"] = "iPad Pro (12.9-inch)",
    ["iPad6,8"] = "iPad Pro (12.9-inch)",
    ["iPad6,11"] = "iPad 5",
    ["iPad6,12"] = "iPad 5",
    ["iPad7,1"] = "iPad Pro 2 (12.9-inch)",
    ["iPad7,2"] = "iPad Pro 2 (12.9-inch)",
    ["iPad7,3"] = "iPad Pro (10.5-inch)",
    ["iPad7,4"] = "iPad Pro (10.5-inch)",
    ["iPad7,5"] = "iPad 6",
    ["iPad7,6"] = "iPad 6",
    ["iPad7,11"] = "iPad 7",
    ["iPad7,12"] = "iPad 7",
    ["iPad8,1"] = "iPad Pro (11-inch)",
    ["iPad8,2"] = "iPad Pro (11-inch)",
    ["iPad8,3"] = "iPad Pro (11-inch)",
    ["iPad8,4"] = "iPad Pro (11-inch)",
    ["iPad8,5"] = "iPad Pro 3 (12.9-inch)",
    ["iPad8,6"] = "iPad Pro 3 (12.9-inch)",
    ["iPad8,7"] = "iPad Pro 3 (12.9-inch)",
    ["iPad8,8"] = "iPad Pro 3 (12.9-inch)",
    ["iPad8,9"] = "iPad Pro 2 (11-inch)",
    ["iPad8,10"] = "iPad Pro 2 (11-inch)",
    ["iPad8,11"] = "iPad Pro 4 (12.9-inch)",
    ["iPad8,12"] = "iPad Pro 4 (12.9-inch)",
    ["iPad11,3"] = "iPad Air 3",
    ["iPad11,4"] = "iPad Air 3",
    ["iPad13,1"] = "iPad Air 4",
    ["iPad13,2"] = "iPad Air 4",
    ["iPad13,4"] = "iPad Pro 3 (11-inch)",
    ["iPad13,5"] = "iPad Pro 3 (11-inch)",
    ["iPad13,6"] = "iPad Pro 3 (11-inch)",
    ["iPad13,7"] = "iPad Pro 3 (11-inch)",
    ["iPad13,8"] = "iPad Pro 5 (12.9-inch)",
    ["iPad13,9"] = "iPad Pro 5 (12.9-inch)",
    ["iPad13,10"] = "iPad Pro 5 (12.9-inch)",
    ["iPad13,11"] = "iPad Pro 5 (12.9-inch)",
    ["iPad13,16"] = "iPad Air 5",
    ["iPad13,17"] = "iPad Air 5",
    ["iPad13,18"] = "iPad 10",
    ["iPad13,19"] = "iPad 10",
    ["iPad14,3"] = "iPad Pro (11-inch) 4th gen",
    ["iPad14,4"] = "iPad Pro (11-inch) 4th gen",
    ["iPad14,5"] = "iPad Pro (12.9-inch) 6th gen",
    ["iPad14,6"] = "iPad Pro (12.9-inch) 6th gen",
    --iPad Mini
    ["iPad2,5"] = "iPad Mini 1",
    ["iPad2,6"] = "iPad Mini 1",
    ["iPad2,7"] = "iPad Mini 1",
    ["iPad4,4"] = "iPad Mini 2",
    ["iPad4,5"] = "iPad Mini 2",
    ["iPad4,6"] = "iPad Mini 2",
    ["iPad4,7"] = "iPad Mini 3",
    ["iPad4,8"] = "iPad Mini 3",
    ["iPad4,9"] = "iPad Mini 3",
    ["iPad5,1"] = "iPad Mini 4",
    ["iPad5,2"] = "iPad Mini 4",
    ["iPad11,1"] = "iPad Mini 5",
    ["iPad11,2"] = "iPad Mini 5",
    ["iPad14,1"] = "iPad Mini 6",
    ["iPad14,2"] = "iPad Mini 6",
    --iPod
    ["iPod1,1"] = "iTouch 1",
    ["iPod2,1"] = "iTouch 2",
    ["iPod3,1"] = "iTouch 3",
    ["iPod4,1"] = "iTouch 4",
    ["iPod5,1"] = "iTouch 5",
    ["iPod7,1"] = "iTouch 6",
    ["iPod9,1"] = "iTouch 7",
    ["i386"] = "Simulator 32",
    ["x86_64"] = "Simulator 64",
    --
    [""] = "unknown"
}

XSDKDeviceInfoManager.APP_SCHEME_ANDROID = {
    ["WeChat"] = "com.tencent.mm",
    ["AliPay"] = "alipay", -- android 支付宝用url端口来判断
    ["QQ"] = "com.tencent.mobileqq",
    ["FaceBook"] = "com.facebook.katana"
}

XSDKDeviceInfoManager.APP_SCHEME_IOS = {
    ["WeChat"] = "weixin",
    ["AliPay"] = "alipay",
    ["QQ"] = "mqq",
    ["FaceBook"] = "fbapi"
}

local OPEN_VERSION = "1.6.1"

if device.platform == "ios" then
    OPEN_VERSION = "1.6.9"
end

XSDKDeviceInfoManager.m_instance = nil
function XSDKDeviceInfoManager:getInstance()
    if XSDKDeviceInfoManager.m_instance == nil then
        XSDKDeviceInfoManager.m_instance = XSDKDeviceInfoManager.new()
    end
    return XSDKDeviceInfoManager.m_instance
end
-- 构造函数
function XSDKDeviceInfoManager:ctor()
    -- 初始化变量
    if device.platform == "android" then
        self.m_netTypeCode = self.NETWORK_ANDROID_CODE
    elseif device.platform == "ios" then
        self.m_netTypeCode = self.NETWORK_IOS_CODE
    elseif device.platform == "mac" then
        self.m_netTypeCode = self.NETWORK_ANDROID_CODE
    end
    -- 做这个是为了不反复向底层进行交互,如果涉及到底层数据刷新，从底层抛送消息过来监听
    self.m_sDeviceID = nil
    self.m_sDeviceIDFV = nil
    self.m_sDeviceIP = nil
    self.m_sDeviceNetType = nil
    self.m_sDeviceSysVersion = nil
    self.m_sDeviceAppVerion = nil
    self.m_sDevicePhoneName = nil
    self.m_sDeviceNotifyStatus = nil
    self.m_lDeviceMemory = nil
    self.m_sDeiceUdid = nil
end

-- 是否启用当前模块新接口
function XSDKDeviceInfoManager:isUseNewXcyySDK()
    if util_isSupportVersion(OPEN_VERSION) then
        return true
    end
    return false
end

-- 对外暴露接口
function XSDKDeviceInfoManager:getDeviceID()
    if not self.m_sDeviceID then
        self.m_sDeviceID = self:getDeviceInfo(self.DEVICE_ID)
    end
    return self.m_sDeviceID
end

function XSDKDeviceInfoManager:getDeviceIDFV()
    if not self.m_sDeviceIDFV then
        self.m_sDeviceIDFV = self:getDeviceInfo(self.DEVICE_IDFV)
    end
    return self.m_sDeviceIDFV
end

function XSDKDeviceInfoManager:getIPAddress()
    if not self.m_sDeviceIP then
        self.m_sDeviceIP = self:getDeviceInfo(self.DEVICE_IP)
    end
    return self.m_sDeviceIP
end

function XSDKDeviceInfoManager:getNetWorkType()
    if not self.m_sDeviceNetType then
        local currNetType = self:getDeviceInfo(self.DEVICE_NETWORKTYPE)
        self.m_sDeviceNetType = self.m_netTypeCode[currNetType] or currNetType
    end
    return self.m_sDeviceNetType
end

function XSDKDeviceInfoManager:getSystemVersion()
    if not self.m_sDeviceSysVersion then
        self.m_sDeviceSysVersion = self:getDeviceInfo(self.DEVICE_SYSTEM_VERSION)
    end
    return self.m_sDeviceSysVersion
end

function XSDKDeviceInfoManager:getAppVersion()
    if not self.m_sDeviceAppVerion then
        self.m_sDeviceAppVerion = self:getDeviceInfo(self.DEVICE_APP_VERSION)
    end
    return self.m_sDeviceAppVerion
end

function XSDKDeviceInfoManager:getPhoneName()
    if not self.m_sDevicePhoneName then
        local deviceName = self:getDeviceInfo(self.DEVICE_PHONE_NAME)
        if device.platform == "android" then
            self.m_sDevicePhoneName = deviceName
        elseif device.platform == "ios" then
            self.m_sDevicePhoneName = self.IOS_PHONENAME[deviceName] or "unknown"
        end
    end
    return self.m_sDevicePhoneName
end

function XSDKDeviceInfoManager:getNotifiyStatus()
    self.m_sDeviceNotifyStatus = self:getDeviceInfo(self.DEVICE_NOTIFY_STATUS)
    return self.m_sDeviceNotifyStatus
end

function XSDKDeviceInfoManager:refreshIpAndNetWorkType()
    self.m_sDeviceIP = self:getDeviceInfo(self.DEVICE_IP)
    local currNetType = self:getDeviceInfo(self.DEVICE_NETWORKTYPE)
    self.m_sDeviceNetType = self.m_netTypeCode[currNetType] or currNetType
end

function XSDKDeviceInfoManager:getDeviceTimeZone()
    if not self.m_sDeviceTimeZone then
        self.m_sDeviceTimeZone = self:getDeviceInfo(self.DEVICE_TIMEZONE)
    end
    return self.m_sDeviceTimeZone
end

function XSDKDeviceInfoManager:getDeviceLanguage()
    if not self.m_sDeviceLanguage then
        self.m_sDeviceLanguage = self:getDeviceInfo(self.DEVICE_LANGUAGE)
    end
    return self.m_sDeviceLanguage
end

function XSDKDeviceInfoManager:getDeviceUseVPN()
    return self:pullOnGetDeviceUseVPN()
end

function XSDKDeviceInfoManager:checkApkExist(_key)
    local urlKeyList = self.APP_SCHEME_ANDROID
    if device.platform == "ios" then
        urlKeyList = self.APP_SCHEME_IOS
    end
    local urlKey = urlKeyList[_key]
    if not urlKey then
        return false
    end
    return self:pullOncheckApkExist(urlKey)
end

function XSDKDeviceInfoManager:getIsEmulator()
    return self:pullOnGetIsEmulator()
end

function XSDKDeviceInfoManager:getDeviceMemory()
    return self:getDeviceInfo(self.DEVICE_MEMORY)
end

function XSDKDeviceInfoManager:checkNetworkIsConnected()
    return self:pullOnCheckNetworkIsConnected()
end

function XSDKDeviceInfoManager:getKeyChainValueForKey(_key)
    return self:pullOnGetKeyChainValueForKey(_key)
end

function XSDKDeviceInfoManager:saveKeyChainValueForKey(_key, _value)
    self:pullOnSaveKeyChainValueForKey(_key)
end

function XSDKDeviceInfoManager:getDeviceUuid()
    if not self.m_sDeiceUdid then
        self.m_sDeiceUdid = self:pullOnGetDeviceUuid()
        if not self.m_sDeiceUdid and device.platform == "mac" and DEBUG == 2 then
            return ""
        end
    end
    return self.m_sDeiceUdid
end

function XSDKDeviceInfoManager:getDeviceCurrentlyRam()
    return self:getDeviceInfo(self.DEVICE_CURR_RAM)
end

function XSDKDeviceInfoManager:getDeviceSpaceInfo(_callback)
    self:pullOnGetDeviceSpaceInfo(_callback)
end

function XSDKDeviceInfoManager:goToNotificationSettings()
    if util_isSupportVersion("1.9.6", "android") then
        local sig = "()V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local ok, ret = luaj.callStaticMethod(className, "verifyNotification", {}, sig)
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    else
        return self:pullOnGoToNotificationSettings()
    end
end
--内部接口
function XSDKDeviceInfoManager:getDeviceInfo(msgIndex)
    if device.platform == "android" then
        local sig = "(I)Ljava/lang/String;"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "getDeviceInfo", {msgIndex}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "getDeviceInfo", {type = msgIndex})
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "mac" then
        return "mac_test_deviceid_" .. msgIndex
    end
end

function XSDKDeviceInfoManager:pullOnGetDeviceUseVPN()
    if device.platform == "android" then
        local sig = "()Z"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "getDeviceUseVPN", {}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "getDeviceUseVPN")
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "mac" then
        return false
    end
end

function XSDKDeviceInfoManager:pullOncheckApkExist(_urlKey)
    if device.platform == "android" then
        local sig = "(Ljava/lang/String;)Z"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "checkApkExist", {_urlKey}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "checkApkExist", {appUrlScheme = _urlKey})
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "mac" then
        return false
    end
end

function XSDKDeviceInfoManager:pullOnGetIsEmulator()
    if device.platform == "android" then
        local sig = "()Z"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "getIsEmulator", {}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        return false
    end

    if device.platform == "mac" then
        return false
    end
end

-- IOS 获取钥匙串存储数据 --
function XSDKDeviceInfoManager:pullOnGetKeyChainValueForKey(_key)
    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "getKeyChainValueForKey", {key = _key})
        if ok then
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        else
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return nil
        end
    end
end
-- IOS 保存数据到钥匙串 --
function XSDKDeviceInfoManager:pullOnSaveKeyChainValueForKey(_key, _value)
    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "saveKeyChainValueForKey", {key = _key, value = _value})
        if not ok then
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        end
    end
end

function XSDKDeviceInfoManager:pullOnGetDeviceUuid()
    if device.platform == "android" then
        local sig = "()Ljava/lang/String;"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "getDeviceUuid", {}, sig)
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "getDeviceUuid")
        if not ok then
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        end
    end

    if device.platform == "mac" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_MAC_FILE, "getDeviceUuid")
        if not ok then
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        end
    end
end

function XSDKDeviceInfoManager:pullOnCheckNetworkIsConnected()
    if device.platform == "android" then
        local sig = "()Z"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "checkNetworkIsConnected", {}, sig)
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "checkNetworkIsConnected")
        if not ok then
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        end
    end

    if device.platform == "mac" then
        return true
    end
end

function XSDKDeviceInfoManager:pullOnGetDeviceSpaceInfo(_callback)
    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "getDeviceSpaceInfo", {callback = _callback})
        if not ok then
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        end
    elseif device.platform == "android" then
        local sig = "(I)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "getDeviceSpaceInfo", {_callback}, sig)
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    end
end

function XSDKDeviceInfoManager:pullOnGoToNotificationSettings()
    if device.platform == "android" then
        local sig = "()V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "goToNotificationSettings", {}, sig)
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    elseif device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "goToNotificationSettings")
        if not ok then
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        end
    end
end

--外部接口
GD.xsdkDeviceInfoListener = function(msg)
    release_print("==== XcyyDeviceInfo xsdkDeviceInfoListener =====")
    if msg == "refreshIp" then
        globalXSDKDeviceInfoManager:refreshIpAndNetWorkType()
    end
end

return XSDKDeviceInfoManager
