--[[
	Facebook 管理类
]]
--ios 123
local FacebookManager = class("FacebookManager")

FacebookManager.m_instance = nil

local FACEBOOK_EVENT_KEY = {
    "14_fb1stdayspin300",
    "14_fb1stdayspin500",
    "14_fb1stdayspin1000",
    "14_fb1stdayLevel30",
    "14_fb1stdayLevel60",
    "14_fb1stdayLevel90",
    "14_fb1stdayLevel120",
    "14_fbaccumulateupto1p99",
    "14_fbaccumulateupto2p99",
    "14_fbaccumulateupto4p99",
    "14_fbaccumulateupto9p99",
    "14_fbaccumulateupto19p99",
    "14_fbaccumulateupto29p99",
    "14_fbaccumulateupto39p99",
    "14_fbaccumulateupto49p99",
    "14_fbaccumulateupto59p99",
    "14_fbaccumulateupto69p99",
    "14_fbaccumulateupto79p99",
    "14_fbaccumulateupto89p99",
    "14_fbaccumulateupto99p99",
    "14_fbaccumulateupto110",
    "14_fbaccumulateupto120",
    "14_fbaccumulateupto130",
    "14_fbaccumulateupto140",
    "14_fbaccumulateupto150",
    "14_fbaccumulateupto160",
    "14_fbaccumulateupto170",
    "14_fbaccumulateupto180",
    "14_fbaccumulateupto190",
    "14_fbaccumulateupto200"
}

function FacebookManager:ctor()
end

function FacebookManager:getInstance()
    if FacebookManager.m_instance == nil then
        FacebookManager.m_instance = FacebookManager.new()
    end
    return FacebookManager.m_instance
end

function FacebookManager:checkSendFacebookEvent(_key)
    --是否可以发送打点日志
    if not CC_IS_PLATFORM_SENDLOG then
        return
    end

    --屏蔽普通支付打点 服务器为啥不直接删除
    if _key == "inappnum" or _key == "1stpay" or _key == "2ndpay" then
        return
    end

    --解析有价值的支付打点 使用原始数据解析
    if string.find(_key, "#") ~= nil then
        local strList = string.split(_key, "#")
        if #strList == 2 then
            -- 需要区分是否调用 fbsdk 的标准购买事件
            local eventKey = strList[1]
            local eventValue = tonumber(strList[2])
            -- if eventKey == "inappnum" then
            -- 	-- fbsdk 付费专用接口不需要事件名 -- 后台目前现在开启的是自动收集,不需要手动发送
            -- 	self:sendPurchasedEvent("",eventValue)
            -- else
            -- 当前事件在需要发送的时间列表中才发送
            if table_keyof(FACEBOOK_EVENT_KEY, eventKey) then
                self:sendCustomEvent(eventKey, eventValue)
            end
        -- end
        end
    else
        -- 无价值的事件
        if table_keyof(FACEBOOK_EVENT_KEY, _key) then
            self:sendCustomEvent(_key, 0)
        end
    end
end

function FacebookManager:sendPurchasedEvent(_key, _value)
    if device.platform == "ios" then
        if util_isSupportVersion("1.4.7") then
            local ok, ret = luaCallOCStaticMethod("AppController", "facebookPurchasedEvent", {eventName = _key, eventValue = _value})
            if not ok then
                return false
            else
                return ret
            end
        end
    end

    -- 暂时不考虑安卓
    if device.platform == "android" then
    end
end

function FacebookManager:sendCustomEvent(_key, _value)
    if device.platform == "ios" then
        if util_isSupportVersion("1.4.7") then
            local ok, ret = luaCallOCStaticMethod("AppController", "facebookSendEvent", {eventName = _key, eventValue = _value})
            if not ok then
                return false
            else
                return ret
            end
        end
    end

    -- 暂时不考虑安卓
    if device.platform == "android" then
    end
end

-- csc 统一化faceook 外部调用接口
function FacebookManager:getFbLoginStatus()
    if globalXSDKFaceBookManager and globalXSDKFaceBookManager:isUseNewXcyySDK() then
        return globalXSDKFaceBookManager:getFbLoginStatus()
    else
        return xcyy.GameBridgeLua:getFbLoginStatus()
    end
    return false
end

function FacebookManager:fbLogOut()
    if globalXSDKFaceBookManager and globalXSDKFaceBookManager:isUseNewXcyySDK() then
        globalXSDKFaceBookManager:facebookLogOut()
    else
        xcyy.GameBridgeLua:fbLogOut()
    end
    -- 暂时在这里处理
    -- release_print("udidlog:reset udid!!!")
    -- 退出fb登录后，重置登陆udid
    gLobalDataManager:setStringByField("UserNewUuid", "", true)
    gLobalDataManager:setStringByField(FB_USERID, "", true)
    gLobalDataManager:setStringByField(FB_TOKEN, "", true)
end

function FacebookManager:fbLogin()
    if globalXSDKFaceBookManager and globalXSDKFaceBookManager:isUseNewXcyySDK() then
        globalXSDKFaceBookManager:facebookLogin()
    else
        xcyy.GameBridgeLua:fbLoginOrInvite()
    end
end

function FacebookManager:facebookShare(_url, _callBack)
    if globalXSDKFaceBookManager and globalXSDKFaceBookManager:isUseNewXcyySDK() then
        globalXSDKFaceBookManager:facebookShare(_url, _callBack)
    else
        globalPlatformManager:facebookShare(_url, _callBack)
    end
end

function FacebookManager:facebookSharePicture(_picturePath, _callBack)
    local platform = device.platform
    if platform == "ios" then
        if util_isSupportVersion("1.6.8") then
            local ok, ret = luaCallOCStaticMethod("XcyySDKCommon", "facebookSharePicture", {picturePath = _picturePath, callBack = _callBack})
            if not ok then
            else
            end
        end
    elseif platform == "android" then
        if util_isSupportVersion("1.6.0") then
            local sig = "(Ljava/lang/String;I)V"
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/XcyySDK/XcyySDKCommon"
            local ok, ret = luaj.callStaticMethod(className, "facebookSharePicture", {_picturePath, _callBack}, sig)
            if not ok then
                return ""
            else
                return ret
            end
        end
    end
end

function FacebookManager:getFaceBookFriendList(_callBack)
    --获取下一页好友列表
    local function checkFriendNextPage(jsonData, nextURL)
        if nextURL ~= nil then
            local httpSender = xcyy.HttpSender:createSender()
            local function success_call_fun(responsData)
                local newJsonData = util_cjsonDecode(responsData)
                if newJsonData ~= nil and newJsonData.data ~= nil then
                    for k, v in ipairs(newJsonData.data) do
                        table.insert(jsonData.friendList.data, v)
                    end
                end
                if newJsonData ~= nil and newJsonData.paging ~= nil and newJsonData.paging.next ~= nil then
                    checkFriendNextPage(jsonData, newJsonData.paging.next)
                else
                    checkFriendNextPage(jsonData, nil)
                end
                httpSender:release()
            end
            local function faild_call_fun(errorCode, errorData)
                checkFriendNextPage(jsonData, nil)
                util_sendToSplunkMsg("FBFriendError", string.format("errorCode = %d,errorMsg = %s", errorCode, errorData))
                httpSender:release()
            end
            httpSender:sendHttpMessage(HttpRequestType.GET, nextURL, "", success_call_fun, faild_call_fun)
        else
            if _callBack ~= nil then
                _callBack(cjson.encode(jsonData))
            end
        end
    end

    --检测是否有下一页
    local function checkCallBack(data)
        local jsonData = util_cjsonDecode(data)
        if jsonData and jsonData.friendList ~= nil and jsonData.friendList.data ~= nil then
            local friendList = jsonData.friendList
            --下一页
            if friendList.paging ~= nil and friendList.paging.next ~= nil then
                checkFriendNextPage(jsonData, friendList.paging.next)
            else
                if _callBack ~= nil then
                    _callBack(data)
                end
            end
        else
            if _callBack ~= nil then
                _callBack(data)
            end
        end
    end

    if globalXSDKFaceBookManager and globalXSDKFaceBookManager:isUseNewXcyySDK() then
        globalXSDKFaceBookManager:getFaceBookFriendList(checkCallBack)
    else
        globalPlatformManager:getFaceBookFriendList(checkCallBack)
    end
end

function FacebookManager:facebookAppRequest(_msgInfo,_callBack)
	globalXSDKFaceBookManager:facebookAppRequest(_msgInfo,_callBack)
end

return FacebookManager
