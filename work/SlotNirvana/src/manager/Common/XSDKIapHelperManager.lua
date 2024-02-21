--[[
    @desc: 新版内购接口文件
    author:csc
    time:2021-04-13 
    @return:
]]

local itemKey = "slots_casinocashlink"
local itemKeyTest = "slots_casinocashlinktest"
local XSDKIapHelperManager = class("XSDKIapHelperManager")

-- 调用的底层文件路径配置
XSDKIapHelperManager.ANDROID_JAVA_FILE = "org/cocos2dx/lua/XcyySDK/XcyySDKCommon"

XSDKIapHelperManager.IOS_OC_FILE = "XcyySDKCommon"
XSDKIapHelperManager.IOS_MAC_FILE = "XcyySDKCommonMAC"

-- 建立新版内购对外抛消息事件
GD.IapEventType = {
    IAP_RetrySuccess = "IAP_RetrySuccess", -- iOS retry 行为的补单成功
    IAP_BuyResult = "iap_buy_result", -- 购买结果
    IAP_ConsumeResult = "iap_consume_result", -- 消耗结果
    IAP_SendSplunk = "iap_sendSplunck", -- splunk打点
    IAP_PurchasingBack = "iap_purchasingback" -- purchasing 回调
}

XSDKIapHelperManager.m_instance = nil
function XSDKIapHelperManager:getInstance()
    if XSDKIapHelperManager.m_instance == nil then
        XSDKIapHelperManager.m_instance = XSDKIapHelperManager.new()
    end
    return XSDKIapHelperManager.m_instance
end

-- 构造函数
function XSDKIapHelperManager:ctor()
end

--外部接口

--拉起sdk购买 userId iapId buyType applicationUserID privatePayMentKey callback
function XSDKIapHelperManager:buyOneGoods(_buyData)
    self:pullOnBuyOneGoods(_buyData)
end

-- 向sdk发起消耗订单 --@_token:
-- android 获取receipt中的token去消耗
-- ios 获取 orderID 去消耗
function XSDKIapHelperManager:consumePurchase(_orderID, _receipt)
    self:pullOnConsumePurchase(_orderID, _receipt)
end

function XSDKIapHelperManager:onlyConsumePurchase(_orderID, _receipt)
    self:pullOnOnlyConsumePurchase(_orderID, _receipt)
end

function XSDKIapHelperManager:checkUncompleteTransactions(_callback)
    self:pullOnCheckUncompleteTransactions(_callback)
end

function XSDKIapHelperManager:checkPendingTransactions(_callback)
    self:pullOnCheckPendingTransactions(_callback)
end

function XSDKIapHelperManager:removePendingTransactions(_orderID)
    self:pullOnRemovePendingTransactions(_orderID)
end

function XSDKIapHelperManager:queryPurchases()
    self:pullOnqueryPurchases()
end

----------------------------------------付费底层新接口 BEGIN-----------------------------------
function XSDKIapHelperManager:pullOnBuyOneGoods(_buyData)
    local data = {
        itemID = _buyData.iapId,
        buyType = _buyData.buyType,
        callBack = _buyData.callBack,
        applicationUserID = _buyData.applicationUserID,
        privatePayMentKey = _buyData.privatePayMentKey
    }
    local platform = device.platform
    if platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "buyOneGoods", data)
        if not ok then
            release_print("==== lua oc error pullOnBuyOneGoods ==== : " .. tostring(ret))
            --应该抛出调用失败 并且发送打点信息
            self:triggerBuyFailed({errorCode = 2, errorMsg = "pullOnBuyOneGoods failed"})
            return ""
        else
            release_print("==== lua oc pullOnBuyOneGoods return is:" .. tostring(ret))
            return ret
        end
    elseif platform == "android" then
        local sig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local classFunctionName = "buyOneGoods"

        local _iapId = _buyData.iapId
        if util_isSupportVersion("1.7.4") then
            if DEBUG ~= 0 then
                _iapId = string.gsub(_iapId, itemKey, itemKeyTest)
            end
        end

        local androidData = {_buyData.userId, _iapId, _buyData.buyType, _buyData.callBack}
        local ok, ret = luaj.callStaticMethod(className, classFunctionName, androidData, sig)
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    end
end

function XSDKIapHelperManager:pullOnConsumePurchase(_orderID, _receipt)
    local platform = device.platform
    if platform == "ios" then
        local data = {
            orderID = _orderID
        }
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "consumePurchase", data)
        if not ok then
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        end
    elseif platform == "android" then
        local sig = "(Ljava/lang/String;)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "consumePurchase", {_receipt}, sig)
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    end
end

function XSDKIapHelperManager:pullOnOnlyConsumePurchase(_orderID, _receipt)
    local platform = device.platform
    if platform == "ios" then
        local data = {
            orderID = _orderID
        }
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "onlyConsumePurchase", data)
        if not ok then
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        end
    elseif platform == "android" then
        local sig = "(Ljava/lang/String;)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "onlyConsumePurchase", {_receipt}, sig)
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    end
end

-- 检测事务列表
function XSDKIapHelperManager:pullOnCheckUncompleteTransactions(_callback)
    local platform = device.platform
    if device.platform == "mac" then
        if _callback then
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
            _callback(cjson.encode(data))
        end
    end
    if platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "checkUncompleteTransactions", {callback = _callback})
        if not ok then
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        end
    elseif platform == "android" then
        local sig = "(I)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "checkUncompleteTransactions", {_callback}, sig)
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    end
end

-- 检测支付中的事物列表
function XSDKIapHelperManager:pullOnCheckPendingTransactions(_callback)
    local platform = device.platform
    if device.platform == "mac" then
        if _callback then
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
            _callback(cjson.encode(data))
        end
    end
    if platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "checkPendingTransactions", {callback = _callback})
        if not ok then
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        end
    elseif platform == "android" then
        local sig = "(I)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "checkPendingTransactions", {_callback}, sig)
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    end
end

function XSDKIapHelperManager:pullOnRemovePendingTransactions(_orderID)
    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod(self.IOS_OC_FILE, "removePendingTransactions", {orderID = _orderID})
        if not ok then
            release_print("==== lua oc error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== lua oc return is:" .. tostring(ret))
            return ret
        end
    elseif device.platform == "android" then
        local sig = "(Ljava/lang/String;)V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "removePendingTransactions", {_orderID}, sig)
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    end
end

function XSDKIapHelperManager:pullOnqueryPurchases()
    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = self.ANDROID_JAVA_FILE
        local ok, ret = luaj.callStaticMethod(className, "queryPurchases")
        if not ok then
            release_print("==== luaj error ==== : " .. tostring(ret))
            return ""
        else
            release_print("==== The JNI return is:" .. tostring(ret))
            return ret
        end
    end
end
----------------------------------------付费底层新接口 END-----------------------------------

----------------------------------------底层回调全局接口 START-----------------------------------
GD.XSDKIapConsumeCallBack = function(jsonData)
    release_print("------------------------------XSDKIapConsumeCallBack start")
    util_afterDrawCallBack(
        function()
            local data = cjson.decode(jsonData)
            if tolua.type(data) == "table" then
                local sdkCode = data["errorCode"]
                local success = data["success"]
                release_print("---- csc success =  " .. tostring(success))
                gLobalNoticManager:postNotification(IapEventType.IAP_ConsumeResult, {success, sdkCode})
            end
        end
    )

    release_print("------------------------------XSDKIapConsumeCallBack end")
end

GD.XSDKIapPaymentFaildCallback = function(jsonData)
    release_print("------------------------------XSDKIapPaymentFaildCallback start")
    release_print(" jsonData = " .. jsonData)
    util_afterDrawCallBack(
        function()
            local data = cjson.decode(jsonData)
            local errorCode = data["errorCode"]
            local errorMessage = data["errorMsg"]
            release_print("----csc sdk 返回购买失败 --- error = " .. errorCode)
            release_print("----csc sdk 返回购买失败 --- errorMessage = " .. tostring(errorMessage))

            gLobalNoticManager:postNotification(IapEventType.IAP_BuyResult, {errorCode, errorMessage})
        end
    )
    release_print("------------------------------XSDKIapPaymentFaildCallback end")
end

GD.XSDKIapPurchasingCallback = function(jsonData)
    release_print("------------------------------XSDKIapPurchasingCallback start")
    util_afterDrawCallBack(
        function()
            release_print(" ----csc iapPurchasingCallback 重新触发补单流程")
            gLobalNoticManager:postNotification(IapEventType.IAP_PurchasingBack)
        end
    )
    release_print("------------------------------XSDKIapPurchasingCallback end")
end

GD.XSDKIapPaymentStepLog = function(jsonData)
    release_print("------------------------------XSDKIapPaymentStepLog start")
    util_afterDrawCallBack(
        function()
            release_print(" jsonData = " .. jsonData)
            gLobalNoticManager:postNotification(IapEventType.IAP_SendSplunk, jsonData)
        end
    )
    release_print("------------------------------XSDKIapPaymentStepLog end")
end

-- 检测付费异常状态 amazon 专用
GD.XSDKIapPaymentGroundBack = function()
    release_print("------------------------------XSDKIapPaymentGroundBack Amazon start")
    gLobalNoticManager:postNotification(IapEventType.IAP_BuyResult, {errorCode = 1, errorMsg = "home back cancel"})
    release_print("------------------------------XSDKIapPaymentGroundBack Amazon end")
end

----------------------------------------底层回调全局接口 END-----------------------------------
return XSDKIapHelperManager
