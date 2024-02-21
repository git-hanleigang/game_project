local XSDKFaceBookManager = class("XSDKFaceBookManager")

local OPEN_VERSION = "1.5.8"

if device.platform == "ios" then
    OPEN_VERSION = "1.6.6"
end

XSDKFaceBookManager.m_instance = nil
function XSDKFaceBookManager:getInstance()
    if XSDKFaceBookManager.m_instance == nil then
        XSDKFaceBookManager.m_instance = XSDKFaceBookManager.new()
    end
    return XSDKFaceBookManager.m_instance
end
-- 构造函数
function XSDKFaceBookManager:ctor()
end

-- lua 层代码
-- 是否启用当前模块新接口
function XSDKFaceBookManager:isUseNewXcyySDK()
    if util_isSupportVersion(OPEN_VERSION) then
        return true
    end
    return false
end

-- 对外暴露接口
function XSDKFaceBookManager:facebookLogin()
    self:pullOnFacebookLogin()
end

function XSDKFaceBookManager:getFbLoginStatus()
    return self:pullOnGetFaceBookStatus()
end

function XSDKFaceBookManager:facebookLogOut()
    self:pullOnFacebookLogOut()
end

function XSDKFaceBookManager:sendCustomEvent(_key, _value)
    self:pullOnSendCustomEvent(_key, _value)
end

function XSDKFaceBookManager:sendPurchasedEvent(_key, _value)
    self:pullOnSendPurchasedEvent(_key, _value)
end

function XSDKFaceBookManager:getFaceBookFriendList(_callBack)
    if _callBack ~= nil then
        self:pullOnGetFaceBookFriendList(_callBack)
    end
end

function XSDKFaceBookManager:facebookShare(_url, _callBack)
    self:pullOnFacebookShare(_url, _callBack)
end

--内部接口
function XSDKFaceBookManager:pullOnFacebookLogin()
    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyySDK/XcyySDKCommon"
        local ok, ret = luaj.callStaticMethod(className, "facebookLogin")
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("XcyySDKCommon", "facebookLogin")
        if not ok then
            return ""
        else
            return ret
        end
    end
end

function XSDKFaceBookManager:pullOnGetFaceBookStatus()
    if device.platform == "android" then
        local sig = "()Z"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyySDK/XcyySDKCommon"
        local ok, ret = luaj.callStaticMethod(className, "getFaceBookStatus", {}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("XcyySDKCommon", "getFaceBookStatus")
        if not ok then
            return ""
        else
            return ret
        end
    end
end

function XSDKFaceBookManager:pullOnFacebookLogOut()
    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyySDK/XcyySDKCommon"
        local ok, ret = luaj.callStaticMethod(className, "facebookLogOut")
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("XcyySDKCommon", "facebookLogOut")
        if not ok then
            return ""
        else
            return ret
        end
    end
end

function XSDKFaceBookManager:pullOnSendCustomEvent(_key, _value)
    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("XcyySDKCommon", "facebookSendEvent", {eventName = _key, eventValue = _value})
        if not ok then
            return false
        else
            return ret
        end
    end
    -- 暂时不考虑安卓
    if device.platform == "android" then
    end
end

function XSDKFaceBookManager:pullOnSendPurchasedEvent(_key, _value)
    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("XcyySDKCommon", "facebookPurchasedEvent", {eventName = _key, eventValue = _value})
        if not ok then
            return false
        else
            return ret
        end
    end
    -- 暂时不考虑安卓
    if device.platform == "android" then
    end
end

-- 获取Facebook好友列表
function XSDKFaceBookManager:pullOnGetFaceBookFriendList(callBack)
    local platform = device.platform
    if platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("XcyySDKCommon", "getFriendList", {callBack = callBack})
        if not ok then
        else
        end
    elseif platform == "android" then
        local sig = "(I)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyySDK/XcyySDKCommon"
        local ok, ret = luaj.callStaticMethod(className, "getFriendList", {callBack}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end
end

function XSDKFaceBookManager:pullOnFacebookShare(_url, _callBack)
    local platform = device.platform
    if platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("XcyySDKCommon", "facebookShare", {url = _url, callback = _callBack})
        if not ok then
        else
        end
    elseif platform == "android" then
        local sig = "(Ljava/lang/String;I)V"
        local luaj = require("cocos.cocos2d.luaj")
        if util_isSupportVersion("1.6.5") then
            sig = "(ILjava/lang/String;I)V"
            local className = "org/cocos2dx/lua/XcyyUtil"
            local info = {content = _url,package = "com.facebook.katana"}
            local ok,ret = nil,nil
            if not _callBack then
                _callBack = function()
                    self.clickFb = false
                end
                if not self.clickFb then
                    ok, ret = luaj.callStaticMethod(className, "sendFuncMsg", {3,cjson.encode(info), _callBack}, sig)
                    self.clickFb = true
                end
            else
                ok, ret = luaj.callStaticMethod(className, "sendFuncMsg", {3,cjson.encode(info), _callBack}, sig)
            end
            if not ok then
                return ""
            else
                return ret
            end
        else
            local className = "org/cocos2dx/lua/XcyySDK/XcyySDKCommon"
            local ok, ret = luaj.callStaticMethod(className, "facebookShare", {_url, _callBack}, sig)
            if not ok then
                return ""
            else
                return ret
            end
        end
    end
end

GD.XSDKFacebookLoginCallBack = function(_jsonData)
    release_print("------------------------------XSDKFacebookLoginCallBack start")
    local data = cjson.decode(_jsonData)
    local state = data["state"]
    local errorMsg = data["errorMsg"]
    util_afterDrawCallBack(
        function()
            if errorMsg ~= "" and state < 0 then
                release_print("----csc XSDKFacebookLoginCallBack errorMsg :" .. tostring(errorMsg))
                --发送splunk 日志当前登录错误信息
                util_sendToSplunkMsg("FaceBookLogon", tostring(errorMsg))
            end
            release_print("----csc XSDKFacebookLoginCallBack state :" .. tostring(state))
            gLobalNoticManager:postNotification(GlobalEvent.FB_LoginStatus, {state = state, message = errorMsg})
        end
    )
    release_print("------------------------------XSDKFacebookLoginCallBack end")
end

GD.XSDKFacebookStatusCallBack = function(_jsonData)
    release_print("------------------------------XSDKFacebookStatusCallBack start")
    local data = cjson.decode(_jsonData)
    local fbtoken = data["fbtoken"]
    local fbuserid = data["fbuserid"]
    local fbname = data["fbname"]
    local fbemail = data["fbemail"]

    release_print("----csc XSDKFacebookStatusCallBack fbtoken :" .. tostring(fbtoken))
    release_print("----csc XSDKFacebookStatusCallBack fbuserid :" .. tostring(fbuserid))
    release_print("----csc XSDKFacebookStatusCallBack fbname :" .. tostring(fbname))
    release_print("----csc XSDKFacebookStatusCallBack fbemail :" .. tostring(fbemail))

    gLobalDataManager:setStringByField(FB_USERID, fbuserid)
    gLobalDataManager:setStringByField(FB_TOKEN, fbtoken)
    gLobalDataManager:setStringByField(FB_NAME, fbname)
    gLobalDataManager:setStringByField(FB_EMAIL, fbemail)

    release_print("------------------------------XSDKFacebookStatusCallBack end")
end

GD.XSDKFacebookLogoutCallBack = function(_jsonData)
    release_print("------------------------------XSDKFacebookLogoutCallBack start")

    local data = cjson.decode(_jsonData)
    local result = data["result"] > 0 and true or false
    release_print("----csc XSDKFacebookLogoutCallBack result :" .. tostring(result))
    gLobalNoticManager:postNotification(GlobalEvent.FB_LogoutStatus, result)
    if result then
        -- release_print("udidlog:reset udid!!!")
        -- -- 退出fb登录后，重置登陆udid
        -- gLobalDataManager:setStringByField("UserNewUuid", "")
        gLobalDataManager:setStringByField(FB_USERID, "")
        gLobalDataManager:setStringByField(FB_TOKEN, "")
    end
    release_print("------------------------------XSDKFacebookLogoutCallBack end")
end

return XSDKFaceBookManager
