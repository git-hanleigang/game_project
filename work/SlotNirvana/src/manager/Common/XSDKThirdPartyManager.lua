--[[
    @desc: 第三方sdk 接口
    author:csc
    time:2022-02-23 15:48:48
    
    AIHELP、Adjust
]]
local XSDKThirdPartyManager = class("XSDKThirdPartyManager")

-- 调用的底层文件路径配置
XSDKThirdPartyManager.ANDROID_JAVA_FILE = "org/cocos2dx/lua/XcyySDK/XcyySDKCommon"
XSDKThirdPartyManager.IOS_OC_FILE = "XcyySDKCommon"

local OPEN_VERSION = "1.6.3"

if device.platform == "ios" then
    OPEN_VERSION = "1.7.1"
end

XSDKThirdPartyManager.m_instance = nil
function XSDKThirdPartyManager:getInstance()
    if XSDKThirdPartyManager.m_instance == nil then
        XSDKThirdPartyManager.m_instance = XSDKThirdPartyManager.new()
    end
    return XSDKThirdPartyManager.m_instance
end
-- 构造函数
function XSDKThirdPartyManager:ctor()
end

-- 是否启用当前模块新接口
function XSDKThirdPartyManager:isUseNewXcyySDK()
    if util_isSupportVersion(OPEN_VERSION) then
        return true
    end
    return false
end

-- 对外暴露接口
function XSDKThirdPartyManager:openAIHelpFAQ(_data)
    self:pullOnOpenAIHelpFAQ(_data)
end

function XSDKThirdPartyManager:openAIHelpRobot(_data)
    self:pullOnOpenAIHelpRobot(_data)
end

function XSDKThirdPartyManager:startCheckAIHelpNewMessage(_udid)
    self:pullOnStartCheckAIHelpNewMessage(_udid)
end

------------------------------------------------ 底层交互接口 ------------------------------------------------
function XSDKThirdPartyManager:pullOnOpenAIHelpFAQ(data)
    if device.platform == "android" then
        -- 新版需求 aihelp默认需要的三个字段 udid name tag ，其他的数据封装到自定义字段中
        local userUdid = data.userId
        local userName = data.userName
        local userTag = data.userTag

        local userJsonData = cjson.encode(data.userJsonData)
        local sig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "openFAQ", {userUdid, userName, userTag, userJsonData}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local userJsonData = cjson.encode(data.userJsonData)
        data.userJsonData = userJsonData
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "openFAQ", data)
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

function XSDKThirdPartyManager:pullOnOpenAIHelpRobot(data)
    if device.platform == "android" then
        -- 新版需求 aihelp默认需要的三个字段 udid name tag ，其他的数据封装到自定义字段中
        local userUdid = data.userId
        local userName = data.userName
        local userTag = data.userTag

        local userJsonData = cjson.encode(data.userJsonData)
        local sig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "openRobot", {userUdid, userName, userTag, userJsonData}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local userJsonData = cjson.encode(data.userJsonData)
        data.userJsonData = userJsonData
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "openRobot", data)
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
function XSDKThirdPartyManager:pullOnStartCheckAIHelpNewMessage(_udid)
    local userUdid = _udid
    if device.platform == "android" then
        local sig = "(Ljava/lang/String;)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "startCheckAIHelpNewMessage", {userUdid}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "startCheckAIHelpNewMessage", {userUdid = userUdid})
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

--外部接口
GD.XSDKThirdPartyAIHelpNewMessage = function(jsonData)
    release_print("------------------------------XSDKThirdPartyAIHelpNewMessage start")
    release_print(" jsonData = " .. jsonData)
    local data = cjson.decode(jsonData)
    local messageCount = data["messageCount"]
    util_afterDrawCallBack(
        function()
            -- 新版本 aihelp 返回的是消息数量
            globalData.newMessageNums = tonumber(messageCount)
            if globalData.newMessageNums == 0 then
                globalData.newMessageNums = nil
            end
            if globalData.newMessageNums and globalData.newMessageNums >= 1 then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHECK_NEWMESSAGE)
            end
        end
    )

    release_print("------------------------------XSDKThirdPartyAIHelpNewMessage end")
end

return XSDKThirdPartyManager
