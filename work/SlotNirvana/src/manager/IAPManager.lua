--应用内支付管理
-- FIX IOS 139
local XSDKIapHelperManager = util_require("manager.Common.XSDKIapHelperManager")
local IAPConfig = util_require("data.baseDatas.IAPConfig")
local IAPManager = class("IAPManager")

IAPManager.m_curIapConfig = nil --当前支付信息
IAPManager.m_failConfigList = nil --未成功列表

IAPManager.m_reConnectIndex = nil --当前补单序列索引
IAPManager.m_reConnectConfig = nil --当前补单信息
IAPManager.m_reConnectList = nil --补单列表

IAPManager.m_currIapOrderId = nil --当前的订单id

IAPManager.m_instance = nil
IAPManager.m_buySuccessCallFun = nil
IAPManager.m_buyFailedCallFun = nil

-- 测试代码
IAPManager.m_testBuySuccess = gLobalDataManager:getBoolByField("iap_testBuySuccess", false)
IAPManager.m_testSkipServer = gLobalDataManager:getBoolByField("iap_testSkipServer", false)

IAPManager.m_testReSkipServer = gLobalDataManager:getBoolByField("iap_testReSkipServer", false) --补单是否跳过服务器
IAPManager.m_testReBuySuccess = gLobalDataManager:getBoolByField("iap_testReBuySuccess", false) -- 补单是否能过验证

IAPManager.m_schdulePending = nil
IAPManager.m_pendingState = nil -- 当前是否处在 purchasing 状态下
IAPManager.m_bStart = false -- 当前订单系统是否开启
IAPManager.m_checkTime = 3 * 60 -- 检测间隔时间
IAPManager.m_checkFaildTimes = 5 -- 由于google 延迟失败的订单需要10分钟才能被消耗掉，所以这块做个处理
IAPManager.m_lastCheckPurchasingTime = gLobalDataManager:getNumberByField("iap_checkpurchasing_time", 0) -- 上次检测 purchasing 状态的时间
IAPManager.m_checkSuppleTimes = 1 -- 需要补上的检测次数

IAPManager.m_bCheckOk = false -- log打印
IAPManager.m_iLogStep = 1
IAPManager.m_bSdkPullOnCallback = false -- 判断当前是否有SDK拉起返回

IAPManager.m_homebackCheckTimeList = {2, 3, 5} -- home 返回检测时间点 一共5s
IAPManager.m_homebackDelayIndex = 1 -- 时间下标

IAPManager.m_bRetryPayment = false --用来标识当前是 retry行为的补单

-- -101:查询应用内商品详情失败,没有商品
-- -102:当前商品id在后台没有配置
-- -103:消耗商品失败
-- -104:准备进行消耗订单失败
-- -105:商品购买成功,但是收据回传lua过程中失败
-- -106:服务器验证失败
-- -107:补单商品获取成功,收据回传lua过程中失败
-- -108:purchasing商品获取成功,回传lua 过程中失败
-- -109:ios付费完成后发现没有标识符
IAPManager.ErrorCode = {
    SkuDetailsList_Nil = "-101",
    Product_NoExistList = "-102",
    Consume_Failed = "-103",
    Ready_ConsumeFailed = "-104",
    BuySuccess_CallBackFailed = "-105",
    Server_VerifyFailed = "-106",
    ReCheckOrder_CallBackFailed = "-107",
    ReCheckPendingOrder_CallBackFailed = "-108",
    IosPurchased_NoApplicationID = "-109",
    Google_NoBilling = "-110"
}

-- 自定义的弹窗错误标识位key值 用来规范弹窗
IAPManager.customErrorTag = {
    E_GP_DISCONNECTED = "gp_disconnected",
    E_GP_UNSUPPORT = "gp_unsupport",
    E_GP_ORDEROWNED = "gp_orderowned",
    E_GP_PAYMENTFAILED = "gp_paymentfailed",
    E_IOS_PAYMENTFAILED = "ios_paymentfailed",
    E_IOS_UNSUPPORT = "ios_unsupport",
    E_IOS_DISCONNECTED = "ios_disconnected",
    E_SERVERVERIFY_FAILED = "server_verifyfailed", -- 服务器验证失败
    E_SERVERVERIFY_FAILEDREMOVE = "server_verifyfailedRemove", -- 服务器验证失败删除数据
    E_IOS_SUCCESSRETRY = "ios_successRetry" --ios 端补单后置 , 订单后面成功了，需要告知用户进行重试
}

IAPManager.paymentResTable = {
    [IAPManager.customErrorTag.E_GP_DISCONNECTED] = {context = "Disconnected from Google Play!\nPlease check your network connection and try again.", contact = false, retry = false}, -- 网络丢失
    [IAPManager.customErrorTag.E_GP_UNSUPPORT] = {context = "Not supportive to pay with Google Play! Please check your Google Play account and try again.", contact = false, retry = false}, -- 不支持内购
    [IAPManager.customErrorTag.E_GP_ORDEROWNED] = {context = "Your purchase was successful!\nWe are processing your order.\nPlease wait for loading to your account.", contact = false, retry = false}, -- 订单已经拥有,可能是没消耗或者消耗失败
    [IAPManager.customErrorTag.E_GP_PAYMENTFAILED] = {context = "Please check your Google Play account and try again! Need Help? Contact us now!", contact = true, retry = false}, -- 错误导致购买失败
    [IAPManager.customErrorTag.E_IOS_PAYMENTFAILED] = {context = "Please check your Apple account and try again. Need Help? Contact us now!", contact = true, retry = false}, -- 错误导致购买失败
    [IAPManager.customErrorTag.E_IOS_UNSUPPORT] = {context = "Not supportive to pay with App Store! Please check your Apple account and try again.", contact = false, retry = false}, -- 不支持内购
    [IAPManager.customErrorTag.E_IOS_DISCONNECTED] = {
        context = "The connection to App Store has timed out! Under failed charges, please check your network connection and try to purchase again.",
        contact = false,
        retry = false
    }, -- 连接 itunes store 失败返回
    [IAPManager.customErrorTag.E_IOS_SUCCESSRETRY] = {
        context = "Lost connection to the App store. Items failed to be delivered. Please hit the 'RETRY' to purchase the item again.\nYou won't be double charged.",
        contact = false,
        retry = true
    }, -- 没有标识符的成功订单，需要走补单
    [IAPManager.customErrorTag.E_SERVERVERIFY_FAILED] = {
        context = "Your purchase could not be completed. Please try to purchase the item and verify again. You won't be double charged.",
        contact = false,
        retry = false
    }, -- 服务器验证失败
    [IAPManager.customErrorTag.E_SERVERVERIFY_FAILEDREMOVE] = {
        context = "Sorry, payment successful but there was a problem with your order.\nPlease contact us with receipt information.",
        contact = true,
        retry = false
    } -- 服务器验证失败，需要删除本地记录
}

-- 购买状态存盘
IAPManager.PurchaseState = {
    PURCHASED = "PURCHASED",
    PURCHASING = "PURCHASING"
}

-- 建立新版内购对外抛消息事件
-- GD.IapEventType = {
--     IAP_RetrySuccess = "IAP_RetrySuccess" -- iOS retry 行为的补单成功
-- }
--单例
function IAPManager:getInstance()
    if IAPManager.m_instance == nil then
        IAPManager.m_instance = IAPManager.new()
    end
    return IAPManager.m_instance
end
--构造函数
function IAPManager:ctor()
    self:initData()
    self:registerObservers()
    self:initSendFlag()
end
--初始化数据
function IAPManager:initData()
    self.m_curIapConfig = nil --当前支付信息
    self.m_failConfigList = {} --未成功列表
    self.m_reConnectIndex = 1 --当前补单序列索引
    self.m_reConnectConfig = nil --当前补单信息
    self.m_reConnectList = {} --补单列表
    self.m_buySuccessCallFun = nil
    self.m_buyFailedCallFun = nil

    if DEBUG ~= 2 then
        self:testSetButton(false, false, false, false)
    end
end
--清除数据
function IAPManager:clearData()
    self.m_curIapConfig = nil --当前支付信息
    -- self.m_failConfigList = {}              --未成功列表
    self.m_reConnectIndex = 1 --当前补单序列索引
    self.m_reConnectConfig = nil --当前补单信息
    self.m_reConnectList = {} --补单列表

    gLobalDataManager:setStringByField(IAP_RECEIPT, "")
    gLobalDataManager:setStringByField(IAP_SIGNATURE, "")
    gLobalDataManager:setStringByField(IAP_ORDER_ID, "")
end

------------------------------- 基础代码 START
--注册事件
function IAPManager:registerObservers()
    if util_isSupportVersion("1.3.3") or device.platform == "mac" then
        ---只有新版本才注册这个回调
        -- 为了跟 SaleManager 区分开 不互相冲突
        -- SaleManager 需要先兼容老版本,保留。
        -- 这个方法 仅仅是为了监听 *** 正常 *** 消耗成功后的回调用的.. 之前的购买成功后转移到新的函数中去
        -- 补单成功消耗不会发送监听这个回调
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                local isSuccess = params[1]
                local errorCode = params[2]
                if globalData.m_isLogin then
                    gLobalViewManager:removeLoadingAnima()
                    if isSuccess == true then
                        -- 如果消耗成功调用消耗完毕代码
                        self:recvConsumeCallback(isSuccess, self.m_currIapOrderId)
                    else
                        -- 如果正常购买导致消耗失败了 。 订单不需要删掉，下次进入会重新进行补单判断
                        self:clearCurIapConfig()
                        -- 消耗失败需要停掉定时器
                        self:stopCheckPendingSchdule()
                        if errorCode then
                            release_print("----csc Log sdk 返回消耗失败 --- error = " .. errorCode)
                            print("----csc Log sdk 返回消耗失败 --- error = " .. errorCode)
                            self:sendIapLog(LOG_ENUM_TYPE.PaymentAction_consume, LOG_ENUM_TYPE.PaymentAction_consumeFailed, errorCode)
                        end
                    end
                end
            end,
            GlobalEvent.IAP_ConsumeResult
        )

        -- 这个方法只接收SDK 端返回的失败情况
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                local errorCode = params[1]
                local errorMessage = params[2]
                release_print("----csc sdk 返回购买失败 --- error = " .. errorCode .. " errorMessage = " .. tostring(errorMessage))
                print("----csc sdk 返回购买失败 --- error = " .. errorCode)
                -- 之前的 ios 判断全都不要了 2020年11月04日20:54:31
                -- 这里应该走正常的购买失败回调
                self:normalBuyResultFailed(errorCode, errorMessage)
            end,
            GlobalEvent.IAP_BuyResult
        )

        -- 重新触发补单流程
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                self:stopCheckPendingSchdule()
                self:iapQueryPurchases()
            end,
            IapEventType.IAP_PurchasingBack
        )

        -- Splunk打点
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                self:sendBuglyLog(params)
            end,
            IapEventType.IAP_SendSplunk
        )
    end
end

function IAPManager:setCallbackFunc(successFun, failedFun)
    self.m_buySuccessCallFun = function(...)
        if not successFun then
            return
        end

        local params = ...
        performWithDelay(display.getRunningScene(), function()
            successFun(params)
        end, 0)
    end
    self.m_buyFailedCallFun = function(...)
        if not failedFun then
            return
        end

        local params = ...
        performWithDelay(display.getRunningScene(), function()
            failedFun(params)
        end, 0)
    end
end

-- 关闭 二次付费 确认弹板
function IAPManager:checkClosePayConfirmLayer()
    local mgr = G_GetMgr(G_REF.PaymentConfirm)
    if not mgr then
        return
    end

    mgr:checkClosePayConfirmLayer()
end

-- 移除 二次付费 确认弹板 所加的蒙版
function IAPManager:checkRemovePayConfirmLayerMask()
    local mgr = G_GetMgr(G_REF.PaymentConfirm)
    if not mgr then
        return
    end

    mgr:checkRemovePayConfirmLayerMask()
end

------------------------------- 基础代码 END
function IAPManager:getIapSDK()
    if util_isSupportVersion("1.7.0", "android") and (MARKETSEL == GOOGLE_MARKET) then
        return XSDKIapHelperManager:getInstance()
    else
        return globalPlatformManager
    end
end
------------------------------- 调用SDK 进行购买 START
function IAPManager:buyGoods(iapId, buyType)
    --调用购买sdk
    if CC_IS_TEST_BUY then
        -- gLobalNoticManager:postNotification(GlobalEvent.IAP_BuyResult,{tonumber(2)})
        -- gLobalNoticManager:postNotification(GlobalEvent.IAP_BuyResult,{tonumber(-2),"itunes connect falied"})
        gLobalSendDataManager:getLogIap():sendUiLog(LOG_ENUM_TYPE.PaymentAction_skip, LOG_IAP_ENMU.operationStatus.testPay)
        -- 组装一组随机数据
        local order = "GPA." .. math.random(0, 9999) .. "-" .. math.random(0, 9999) .. "-" .. math.random(0, 99999) .. "-" .. socket.gettime()
        local sSignature = math.random(0, 9999999999999)

        local function aa(len)
            function random(n, m)
                math.randomseed(os.clock() * math.random(1000000, 90000000) + math.random(1000000, 90000000))
                return math.random(n, m)
            end
            local rt = ""
            for i = 1, len, 1 do
                rt = rt .. string.char(random(97, 122))
            end
            return rt
        end
        local sReceipt = aa(50)
        -- local sPurchaseStatus = "PURCHASED"
        local sPurchaseStatus = self.PurchaseState.PURCHASED
        local tableaa = {
            sOrderId = order,
            sSignature = sSignature,
            sReceipt = sReceipt,
            sPurchaseStatus = sPurchaseStatus,
            sApplicationUserID = globalData.userRunData.uid .. "_" .. buyType .. "_" .. os.time(),
            privatePayMentKey = "test_" .. buyType .. "sApplicationUserID"
            -- sApplicationUserID = "empty",
        }
        local jsondata = cjson.encode(tableaa)
        -- local resultInfo = "{\"sOrderId\":\"GPA.3364-8747-9286-75106\",\"sSignature\":\"1234567890\",\"sReceipt\":{\"purchaseToken\":\"nbbdhkagjlioihceabjlkjbj.AO-J1OwUf7Zy_Ob7gU5iObmBfzidXlb0LnvZ83s3vHNRj5yhZUtqZSD6VM9PTjTAhwq2DmG5WPEiUA5kNbM-bthzIoznMzPmcC9o3zN_MLLIJOQgCEW5N3qiva-w59xcP8gjUhB4EGYtbSzU8QkH4LzA44dc6CJpDA\"},\"transationID\":\"test_token--------\"}"
        local resultInfo = jsondata
        self:buyGoodsCallBack(resultInfo)
    else
        gLobalSendDataManager:getLogIap():sendUiLog(LOG_ENUM_TYPE.PaymentAction_skip)
        local applicationUserID = self.m_curIapConfig.ID
        local privatePayMentKey = iapId .. "_" .. buyType .. "_" .. applicationUserID

        self.m_bSdkPullOnCallback = true
        if util_isSupportVersion("1.7.0", "android") and (MARKETSEL == GOOGLE_MARKET )then
            local buyOneGoodsData = {
                userId = globalData.userRunData.uid,
                iapId = iapId,
                buyType = buyType,
                applicationUserID = applicationUserID,
                privatePayMentKey = privatePayMentKey,
                callBack = handler(self, self.buyGoodsCallBack)
            }

            self:getIapSDK():buyOneGoods(buyOneGoodsData)
        else
            self:sendBuglyLog("buyGoods||globalPlatformManager:buyGoods||productID:" .. iapId .. "||buytype:" .. buyType)
            local function callback(resultInfo)
                self:buyGoodsCallBack(resultInfo)
            end
            self:getIapSDK():buyGoods(iapId, buyType, applicationUserID, privatePayMentKey, handler(self, self.buyGoodsCallBack), callback)
        end
    end
end

-- 接收SDK购买完毕回调 进行数据处理
function IAPManager:buyGoodsCallBack(resultInfo)
    self:sendBuglyLog("buyGoodsCallBack||onEnter")
    self.m_bSdkPullOnCallback = false
    if resultInfo then
        release_print("---- csc resultInfo = " .. resultInfo)
        print("---- csc resultInfo = " .. resultInfo)
        local content = cjson.decode(resultInfo)
        local sReceipt = content["sReceipt"]
        local purchaseStatus = content["sPurchaseStatus"]
        local sUid = content["sUid"]
        local sBuyType = content["sBuyType"]

        if self.m_currIapOrderId and self.m_currIapOrderId == content["sOrderId"] then
            self:sendBuglyLog("buyGoodsCallBack||m_currIapOrderId repeated inFunction orderid = "..content["sOrderId"])
            return
        end

        -- 之前需要再 oc 或者c++ 端存储的转移到lua中存盘到本地文件
        gLobalDataManager:setStringByField(IAP_ORDER_ID, content["sOrderId"])
        gLobalDataManager:setStringByField(IAP_SIGNATURE, content["sSignature"])
        gLobalDataManager:setStringByField(IAP_RECEIPT, sReceipt)

        release_print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sOrderId = " .. content["sOrderId"])
        release_print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sSignature = " .. content["sSignature"])
        release_print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sReceipt = " .. sReceipt)
        release_print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sPurchaseStatus = " .. purchaseStatus)
        release_print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sUid = " .. tostring(sUid))
        release_print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sBuyType = " .. tostring(sBuyType))

        print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sOrderId = " .. content["sOrderId"])
        print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sSignature = " .. content["sSignature"])
        print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sReceipt = " .. sReceipt)
        print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sPurchaseStatus = " .. purchaseStatus)
        print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sUid = " .. tostring(sUid))
        print("----csc buyGoodsCallBack 玩家付费完毕 详细信息 sBuyType = " .. tostring(sBuyType))

        self:sendBuglyLog("buyGoodsCallBack||resultInfo not nil")
        -- 需要对ios 进行针对性判断
        if device.platform == "ios" then
            local sApplicationUserID = content["sApplicationUserID"]
            release_print("----csc 开始检查这笔订单的唯一标识符 ID = " .. sApplicationUserID)
            print("----csc 开始检查这笔订单的唯一标识符 ID = " .. sApplicationUserID)
            if sApplicationUserID == "empty" then
                self:sendBuglyLog("buyGoodsCallBack||sApplicationUserID nil")
                local iapConfig = self:checkIapConfigByKeyValue("orderID", content["sOrderId"])
                if iapConfig then
                    release_print("----csc 当前订单 ID 标识符为空，但是 orderID 在本地已经存储过,进行 判断是否可以走正常流程去消耗这笔订单")
                    print("----csc 当前订单 ID 标识符为空，但是 orderID 在本地已经存储过,进行 判断是否可以走正常流程去消耗这笔订单")
                    if iapConfig.skipBuyGoodsCheck == true then
                        release_print("----csc 可以直接走正常流程去 发送数据给服务器")
                        print("----csc 可以直接走正常流程去 发送数据给服务器")
                        iapConfig.skipBuyGoodsCheck = false
                        self.m_curIapConfig = iapConfig
                        self:addIapConfig(self.m_curIapConfig, true) -- 重新写入数据
                        self:sendBuglyLog("buyGoodsCallBack||sApplicationUserID nil but iapConfig check ok")
                    end
                else
                    release_print("----csc 当前订单 ID 为空,认为这笔成功交易有问题,需要弹出弹板让玩家重新购买一次或者进行补单流程")
                    print("----csc 当前订单 ID 为空,认为这笔成功交易有问题,需要弹出弹板让玩家重新购买一次或者进行补单流程")
                    -- 需要更新一下收据信息
                    self.m_curIapConfig.skipBuyGoodsCheck = true
                    self.m_curIapConfig:updateReceipt(content["sOrderId"], content["sSignature"], sReceipt)
                    self.m_curIapConfig:updatePurchaseStatus(purchaseStatus)
                    self:addIapConfig(self.m_curIapConfig, true) -- 重新写入数据

                    gLobalViewManager:removeLoadingAnima()
                    -- 弹窗处理
                    self:customPushViewControl(nil, self.customErrorTag.E_IOS_SUCCESSRETRY)
                    -- 打点
                    self:sendIapLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_ENUM_TYPE.PaymentAction_success, self.customErrorTag.E_IOS_SUCCESSRETRY)
                    self:sendBuglyLog("buyGoodsCallBack||purchasingRetryBuyGoods")
                    return
                end
            else
                -- 开始查询当前这笔订单信息
                local iapConfig = self:checkIapConfigByKeyValue("ID", sApplicationUserID)
                if iapConfig then
                    release_print("----csc 当前查找到了这笔订单 赋值出来替换掉当前的购买的订单信息 继续进行购买完成")
                    print("----csc 当前查找到了这笔订单 赋值出来替换掉当前的购买的订单信息 继续进行购买完成")
                    self.m_curIapConfig = iapConfig
                    self:sendBuglyLog("buyGoodsCallBack||ios check iapConfig ok")
                end
            end
        end

        -- 更新数据
        self:sendBuglyLog("buyGoodsCallBack||updateReceipt and updatePurchaseStatus")
        self.m_currIapOrderId = content["sOrderId"]
        self.m_curIapConfig:updateReceipt(content["sOrderId"], content["sSignature"], sReceipt)
        self.m_curIapConfig:updatePurchaseStatus(purchaseStatus)
        self:addIapConfig(self.m_curIapConfig, true) -- 重新写入数据

        -- 一旦有购买成功 都要重置下定时器
        self:stopCheckPendingSchdule()

        -- csc 2021-11-15 新增,如果触发购买成功了，需要重置掉定时器
        self:stopCheckHomeBackPurchaseSchedule()
        if purchaseStatus == self.PurchaseState.PURCHASED then
            self:sendBuglyLog("buyGoodsCallBack||sendBuyDataToServer")
            self:sendBuyDataToServer()
        elseif purchaseStatus == self.PurchaseState.PURCHASING then
            self:sendBuglyLog("buyGoodsCallBack||openCheckPendingSchdule")
            self:stopCheckPendingSchdule()
            self:openCheckPendingSchdule(true)
        end
    end
    self:sendBuglyLog("buyGoodsCallBack||end")
end

-- 将购买的数据发送给服务器进行校验
function IAPManager:sendBuyDataToServer()
    ---发送服务器同步消息
    local order = gLobalDataManager:getStringByField(IAP_ORDER_ID, "", true)
    -- if device.platform == "android" then
    --     if MARKETSEL == AMAZON_MARKET then
    --         order = "A:" .. tostring(globalData.userRunData.uid) .. ":" .. tostring(os.time()) .. tostring(math.random(100, 999))
    --         gLobalDataManager:setStringByField(IAP_ORDER_ID, order)
    --     end
    -- end
    -- 创建订单日志 --
    gLobalSendDataManager:getLogIap():createOrder(order)
    gLobalDataManager:setStringByField("IAP_ORDER_TIME", self.m_curIapConfig.createTime)

    local _curIapOrderId = self.m_currIapOrderId or ""
    local _curIapConfig = self.m_curIapConfig or {}
    if DEBUG == 2 then
        if self.m_testSkipServer then
            if self.m_testBuySuccess then -- 绕过服务器的做法
                release_print("----csc 服务器验证通过，进行这笔订单的消耗 orderId =  " .. _curIapOrderId)
                print("----csc 服务器验证通过，进行这笔订单的消耗 orderId =  " .. _curIapOrderId)
                self:sendBuglyLog("sendBuyDataToServer|| sucess")
                self:verifySuccess()
                return
            else
                -- 服务器验证不通过 , 保留文件里的内容 清空局部变量
                release_print("----csc 服务器验证未通过，保留这笔订单 orderId =  " .. _curIapOrderId)
                print("----csc 服务器验证未通过，保留这笔订单 orderId =  " .. _curIapOrderId)
                self:sendBuglyLog("sendBuyDataToServer|| failed")
                --这里应该走服务器失败回调
                self:serverVerifyFailed()
                return
            end
            return
        end
    end

    -- if globalData.m_isLogin then
    --注册24小时内产生首次付费
    globalAdjustManager:checkTriggerNPAdjustLog(AdjustNPEventType.spend_firstly)
    gLobalSendDataManager:getNetWorkIap():sendActionPurchaseInfo(
        function(_result)
            -- 服务器验证通过，进行这笔订单的消耗
            release_print("----csc 服务器验证通过，进行这笔订单的消耗 orderId =  " .. _curIapOrderId)
            print("----csc 服务器验证通过，进行这笔订单的消耗 orderId =  " .. _curIapOrderId)
            self:sendBuglyLog("sendBuyDataToServer|| sucess")
            self:verifySuccess(_result)
        end,
        function(bHas)
            if bHas then
                release_print("----csc 当前订单已经验证过了,可能是消耗失败导致的,直接进行消耗")
                print("----csc 当前订单已经验证过了,可能是消耗失败导致的,直接进行消耗")
                self:sendBuglyLog("sendBuyDataToServer|| failed verify")
                self:onlyConsumePurchase(_curIapConfig)
            else
                -- 服务器验证不通过 , 保留文件里的内容 清空局部变量
                -- local bServerVerify = true
                self:serverVerifyFailed()
            end
        end
    )

    self:sendBuglyLog("sendBuyDataToServer||sdkCallBack success")
    -- 往服务器发送的同时打个点，确定当前调起支付成功
    release_print("----csc Log 往服务器发送的同时打个点，确定当前调起支付成功")
    print("----csc Log 往服务器发送的同时打个点，确定当前调起支付成功")
    self:sendIapLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_ENUM_TYPE.PaymentAction_success)
    -- end
end

-- 购买验证成功 --
function IAPManager:verifySuccess(_result)
    -- 发送消息去消耗当前商品
    self:sendBuglyLog("verifySuccess|| start ")
    local iapConfig = self:checkIapConfigByKeyValue("orderID", self.m_currIapOrderId)
    if iapConfig then
        -- 通知前端去弹板 等原先的成功购买回调
        gLobalViewManager:removeLoadingAnima()
        gLobalSaleManager:updataVipInfo()

        local buyType = iapConfig.buyType
        self:iapCosumeAsync(iapConfig)

        self:clearCurIapConfig()
        gLobalSaleManager:sendPurchaseLog(buyType)

        if self.m_buySuccessCallFun then
            self.m_buySuccessCallFun(_result)
        end
        self:checkClosePayConfirmLayer()
        self.m_buyFailedCallFun = nil

        gLobalNoticManager:postNotification("hide_vedio_icon")
        gLobalNoticManager:postNotification("IAP_Success")

        gLobalSaleManager:clearLocalIapInfo()

        -- 正常购买成功发送打点
        release_print("----csc Log 正常购买成功发送打点")
        print("----csc Log 正常购买成功发送打点")
        self:sendBuglyLog("verifySuccess||PaymentAction_buySuccess")
        self:sendIapLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_ENUM_TYPE.PaymentAction_buySuccess)
    else
        -- 通知前端去弹板 等原先的成功购买回调
        gLobalViewManager:removeLoadingAnima()
        self:sendBuglyLog("verifySuccess||iapconfig = nil remove loading")
    end
    self:sendBuglyLog("verifySuccess||end")
end

-- 验证购买失败 --
function IAPManager:failedHandle()
    gLobalViewManager:removeLoadingAnima()
    gLobalSaleManager:purchaseFailedResetData()
    gLobalSaleManager:clearLocalIapInfo()
end

-- 正常购买SDK 回调失败
function IAPManager:normalBuyResultFailed(errorCode, errorMessage)
    self:sendBuglyLog("normalBuyResultFailed||start")
    self.m_bSdkPullOnCallback = false
    -- log 部分
    release_print("----csc Log 正常购买失败 发送打点日志 errorCode = " .. errorCode)
    print("----csc Log 正常购买失败 发送打点日志 errorCode = " .. errorCode)
    globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.purchase_failed)
    self:sendIapLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_ENUM_TYPE.PaymentAction_failed, errorCode)
    self:sendBuglyLog("normalBuyResultFailed||PaymentAction_failed")

    -- 弹窗处理
    self:customPushViewControl(errorCode, nil, errorMessage)

    self:failedHandle()

    self:sendBuglyLog("normalBuyResultFailed||end")

    -- 支付失败 移除订单信息 -- 如果是ios断网失败的情况，不删除这个订单
    if self.m_currErrorTag ~= self.customErrorTag.E_IOS_DISCONNECTED then
        if self.m_curIapConfig then
            self:removeIapConfig(self.m_curIapConfig.ID)
        end
    end
end

-- 正常购买服务器 验证失败
function IAPManager:serverVerifyFailed()
    self:sendBuglyLog("serverVerifyFailed||start")

    -- log 部分 errorcode 是我们手动定义的值
    local errorCode = self.customErrorTag.E_SERVERVERIFY_FAILED
    release_print("----csc Log 服务器验证失败 发送打点日志 errorCode = " .. errorCode)
    print("----csc Log 服务器验证失败 发送打点日志 errorCode = " .. errorCode)
    self:sendIapLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_ENUM_TYPE.PaymentAction_buyFaild, errorCode)
    self:sendBuglyLog("serverVerifyFailed||PaymentAction_buyFaild")
    self:stopCheckPendingSchdule()

    -- 这里不做弹窗处理.在失败次数添加处进行添加
    -- 更新失败次数
    if self.m_currIapOrderId then
        local iapConfig = self:checkIapConfigByKeyValue("orderID", self.m_currIapOrderId)
        if iapConfig then
            self:updateFailedCount(iapConfig)
        end
    else
        self:sendBuglyLog("verifyFailed||self.m_currIapOrderId = nil ")
    end
    self:failedHandle()

    self:sendBuglyLog("serverVerifyFailed||end")
end
------------------------------- 调用SDK 进行购买 END

------------------------------- 订单操作 START
function IAPManager:checkHasUnConsumePurchase(productID, buyType)
    release_print("----csc 检索当前要购买的 id " .. productID .. " 是否有未消耗的情况")
    print("----csc 检索当前要购买的 id " .. productID .. " 是否有未消耗的情况")
    self:sendBuglyLog("checkHasUnConsumePurchase|| start")
    if self.m_pendingState == true then
        release_print("----csc 当前这个有商品处于 purchasing 状态下.. 不允许用户继续购买其他项")
        print("----csc 当前这个有商品处于 purchasing 状态下.. 不允许用户继续购买其他项")
        self:purchasingWait()
        self:sendBuglyLog("checkHasUnConsumePurchase||purchasingWait")
        return true
    end

    local bHas = false
    local configData = self:checkIapConfigByKeyValue("productID", productID, true)
    if configData and configData.buyType == buyType then -- 这笔订单还没有被消耗掉,需要重新发送给服务器进行验证
        if configData.purchaseStatus == self.PurchaseState.PURCHASING and configData.receipt ~= nil then
            release_print("----csc 当前没有从 SDK 检测到pending状态的订单,这笔订单是 purchasing 并且 包含收据，需要删掉")
            self:removeIapConfig(configData.ID)
            return false
        end
        --     print("----csc 当前商品状态因为 PURCHASING 不允许继续发送购买 --- 弹板")
        --     gLobalSaleManager:purchaseFailedResetData()
        --     self:purchasingWait()
        -- else

        if configData.skipBuyGoodsCheck == true then
            release_print("----csc 当前商品 skipBuyGoodsCheck 直接重新发起sdk请求")
            print("----csc 当前商品 skipBuyGoodsCheck 直接重新发起sdk请求")
            self.m_curIapConfig = configData
            self.m_currIapOrderId = configData.orderID
            -- configData.skipBuyGoodsCheck = false -- 切记如果不是clone 出来的元素，这么改的话 table 里的值也会跟着变
            -- self:removeIapConfig(configData.ID)
            -- 不需要再创建订单了
            gLobalSaleManager:setSkipCreateNewIap(true)
            self:sendBuglyLog("checkHasUnConsumePurchase||skipBuyGoodsCheck||orderID:" .. configData.orderID .. "||productID:" .. configData.productID)
            return false
        end
        release_print("----csc 当前商品存在 orderID 和 receipt 证明需要被消耗，重新发送一次服务器进行验证")
        print("----csc 当前商品存在 orderID 和 receipt 证明需要被消耗，重新发送一次服务器进行验证")
        self.m_curIapConfig = configData
        self.m_currIapOrderId = configData.orderID
        gLobalDataManager:setStringByField(IAP_ORDER_ID, configData.orderID)
        gLobalDataManager:setStringByField(IAP_SIGNATURE, configData.signature)
        gLobalDataManager:setStringByField(IAP_RECEIPT, configData.receipt)
        self:sendBuglyLog("checkHasUnConsumePurchase||sendBuyDataToServer||orderID:" .. configData.orderID .. "||productID:" .. configData.productID)
        self:sendBuyDataToServer()
        -- end
        bHas = true
    end
    self:sendBuglyLog("checkHasUnConsumePurchase|| end")
    return bHas
end

--创建订单信息
function IAPManager:createIapConfig(buyType, productID, extraData)
    --创建订单
    self:clearCurIapConfig()
    self:sendBuglyLog("createIapConfig||clearCurIapConfig")
    if self.m_curIapConfig == nil then
        self.m_curIapConfig = IAPConfig:create()
        self.m_curIapConfig:createIapConfig(buyType, productID, extraData)
        --写入文件
        self:addIapConfig(self.m_curIapConfig, true)
        self:sendBuglyLog("createIapConfig||createNew IapConfig success")
    else
        self:sendBuglyLog("createIapConfig||createNew IapConfig faild")
    end
end

--清除当前订单信息
function IAPManager:clearCurIapConfig()
    if self.m_curIapConfig then
        -- self:removeIapConfig(self.m_curIapConfig.ID)
        self.m_curIapConfig = nil
    end
end

--更新失败的次数
function IAPManager:updateFailedCount(iapConfig)
    release_print("----csc 订单 --- 服务器验证不通过 ---- 失败数 + 1 ")
    print("----csc 订单 --- 服务器验证不通过 ---- 失败数 + 1 ")
    iapConfig:updateFailedCount()
    if iapConfig.failCount >= 3 then
        -- 如果同一笔订单验证失败3次，那么就要清除掉
        release_print("----csc 当前订单服务器验证失败超过三次 -- 进行删除 --- ID = " .. iapConfig.ID)
        print("----csc 当前订单服务器验证失败超过三次 -- 进行删除 --- ID = " .. iapConfig.ID)
        self:onlyConsumePurchase(iapConfig)
        self:sendBuglyLog("updateFailedCount||failed three times")
        -- 弹窗设置
        self:customPushViewControl(nil, self.customErrorTag.E_SERVERVERIFY_FAILEDREMOVE)
    else
        self:saveIapInfoFile()
        self:sendBuglyLog("updateFailedCount||failed times + 1 ==" .. iapConfig.failCount)
        -- 弹窗设置
        self:customPushViewControl(nil, self.customErrorTag.E_SERVERVERIFY_FAILED)
    end
end

--添加支付信息
function IAPManager:addIapConfig(iapConfig, isSaveJsonData)
    -- 插入时需要检测一下当前 list 中是否已经存在该订单 ，有的话直接更新
    if self:checkIapConfigByKeyValue("ID", iapConfig:getJsonData().ID) == nil then
        release_print("----csc 产生新订单 or")
        print("----csc 生新订单")
        self.m_failConfigList[#self.m_failConfigList + 1] = iapConfig
    end
    if isSaveJsonData then
        self:saveIapInfoFile()
    end
end

--移除支付信息(支付成功或者未找到匹配项的移除)
function IAPManager:removeIapConfig(ID)
    release_print("----csc removeIapConfig 当前订单数量 = " .. #(self.m_failConfigList))
    print("----csc removeIapConfig 当前订单数量 = " .. #(self.m_failConfigList))
    self:sendBuglyLog("removeIapConfig||start  ")
    local bRemove = false
    for i = 1, #self.m_failConfigList do
        local iapConfig = self.m_failConfigList[i]
        if iapConfig.ID == ID then
            table.remove(self.m_failConfigList, i)
            bRemove = true
            break
        end
    end

    if bRemove then
        release_print("----csc 有删除订单， 需要重新写入一次订单文件")
        print("----csc 有删除订单， 需要重新写入一次订单文件")
        self:saveIapInfoFile()
        self:sendBuglyLog("removeIapConfig||remove success   ")
    end

    if #self.m_failConfigList == 0 and self.m_schdulePending then
        release_print("----csc 当前订单列表为空 --- 并且定时器开启 --- 需要关闭定时器")
        print("----csc 当前订单列表为空 --- 并且定时器开启 --- 需要关闭定时器")
        self:stopCheckPendingSchdule()
    end
    self:sendBuglyLog("removeIapConfig|| end  ")
end

-- 检索当前服务器回传的成功消耗的商品对应的 iapConfig
function IAPManager:checkIapConfigByKeyValue(key, value, checkPID)
    local currIapConfig = nil
    for i = 1, #self.m_failConfigList do
        local iapConfig = self.m_failConfigList[i]
        if iapConfig[key] and iapConfig[key] == value then
            if key == "productID" then
                release_print("----csc 检索的是 productID 需要做特殊判断")
                print("----csc 检索的是 productID 需要做特殊判断")
                if checkPID then
                    if iapConfig.orderID and iapConfig.signature and iapConfig.receipt then
                        release_print("----csc 当前是购买前producID检索情况 orderID signature receipt不为空 可以返回这个数据去赋值")
                        print("----csc 当前是购买前producID检索情况 orderID signature receipt不为空 可以返回这个数据去赋值")
                        currIapConfig = iapConfig
                        self:sendBuglyLog("checkIapConfigByKeyValue||productID||return data ProductID:" .. iapConfig.productID)
                    end
                else
                    if iapConfig.orderID == nil and iapConfig.signature == nil and iapConfig.receipt == nil then
                        release_print("----csc orderID signature receipt 都为空 可以返回这个数据去赋值")
                        print("----csc orderID signature receipt 都为空 可以返回这个数据去赋值")
                        currIapConfig = iapConfig
                        self:sendBuglyLog("checkIapConfigByKeyValue||productID||return null data ProductID:" .. iapConfig.productID .. " buytype :" .. iapConfig.buyType)
                        break
                    end
                end
            else
                currIapConfig = iapConfig
                release_print("----csc 检索到了对应 key =  " .. key .. " vaule = " .. value)
                print("----csc 检索到了对应 key =  " .. key .. " vaule = " .. value)
                self:sendBuglyLog("checkIapConfigByKeyValue||productID||return exist data ProductID:" .. iapConfig.productID)
                break
            end
        end
    end
    if currIapConfig == nil then
        if key and value then
            release_print("----csc 在队列中没有检索到对应订单 key =  " .. key .. " vaule = " .. value .. " 检查问题")
            print("----csc 在队列中没有检索到对应订单 key =  " .. key .. " vaule = " .. value .. " 检查问题")
        end
        self:sendBuglyLog("checkIapConfigByKeyValue||currIapConfig = nil")
    else
        self:sendBuglyLog("checkIapConfigByKeyValue||currIapConfig is exist ||producID:" .. currIapConfig.productID)
    end

    return currIapConfig
end

function IAPManager:checkIapConfigByKeyValueForAmazon(key, value)
    local currIapConfig = nil
    for i = 1, #self.m_failConfigList do
        local iapConfig = self.m_failConfigList[i]
        if iapConfig[key] and iapConfig[key] == value then
            if key == "productID" then
                release_print("----csc 检索的是 productID 需要做特殊判断")
                print("----csc 检索的是 productID 需要做特殊判断")
                if iapConfig.orderID and iapConfig.signature and iapConfig.receipt then
                    release_print("----csc 当前是购买前producID检索情况 orderID signature receipt不为空 可以返回这个数据去赋值")
                    print("----csc 当前是购买前producID检索情况 orderID signature receipt不为空 可以返回这个数据去赋值")
                    currIapConfig = iapConfig
                    self:sendBuglyLog("checkIapConfigByKeyValue||productID||return data ProductID:" .. iapConfig.productID)
                elseif iapConfig.orderID == nil and iapConfig.signature == nil and iapConfig.receipt == nil then
                    release_print("----csc orderID signature receipt 都为空 可以返回这个数据去赋值")
                    print("----csc orderID signature receipt 都为空 可以返回这个数据去赋值")
                    currIapConfig = iapConfig
                    self:sendBuglyLog("checkIapConfigByKeyValue||productID||return null data ProductID:" .. iapConfig.productID .. " buytype :" .. iapConfig.buyType)
                    break
                end
            end
        end
    end
    if currIapConfig == nil then
        if key and value then
            release_print("----csc 在队列中没有检索到对应订单 key =  " .. key .. " vaule = " .. value .. " 检查问题")
            print("----csc 在队列中没有检索到对应订单 key =  " .. key .. " vaule = " .. value .. " 检查问题")
        end
        self:sendBuglyLog("checkIapConfigByKeyValue||currIapConfig = nil")
    else
        self:sendBuglyLog("checkIapConfigByKeyValue||currIapConfig is exist ||producID:" .. currIapConfig.productID)
    end

    return currIapConfig
end

-- csc 2022-01-08 新增接口，用来检测 productid 以及 buytpye 完全匹配的订单
function IAPManager:checkIapConfigByProductIDAndBuyType(_productId, _buyType)
    local currIapConfig = nil
    release_print("----csc 当前开始检索 checkIapConfigByProductIDAndBuyType ")
    print("----csc 当前开始检索 checkIapConfigByProductIDAndBuyType ")
    for i = 1, #self.m_failConfigList do
        local iapConfig = self.m_failConfigList[i]
        if iapConfig["productID"] and iapConfig["productID"] == _productId then
            release_print("----csc 当前开始检索 checkIapConfigByProductIDAndBuyType productID = " .. _productId)
            print("----csc 当前开始检索 checkIapConfigByProductIDAndBuyType productID = " .. _productId)
            if iapConfig["buyType"] and iapConfig["buyType"] == _buyType then
                release_print("----csc 当前开始检索 checkIapConfigByProductIDAndBuyType 匹配到 _buyType = " .. _buyType)
                print("----csc 当前开始检索 checkIapConfigByProductIDAndBuyType 匹配到 _buyType = " .. _buyType)
                if iapConfig.orderID == nil and iapConfig.signature == nil and iapConfig.receipt == nil then
                    release_print("----csc orderID signature receipt 都为空 可以返回这个数据去赋值")
                    print("----csc orderID signature receipt 都为空 可以返回这个数据去赋值")
                    currIapConfig = iapConfig
                    self:sendBuglyLog("checkIapConfigByKeyValue||productID||return null data ProductID:" .. iapConfig.productID .. " buytype :" .. iapConfig.buyType)
                    break
                end
            end
        end
    end
    if currIapConfig == nil then
        if _productId and _buyType then
            release_print("----csc 在队列中没有检索到对应订单 productId =  " .. _productId .. " buyType = " .. _buyType .. " 检查问题")
            print("----csc 在队列中没有检索到对应订单 productId =  " .. _productId .. " buyType = " .. _buyType .. " 检查问题")
        end
        self:sendBuglyLog("checkIapConfigByProductIDAndBuyType||currIapConfig = nil")
    else
        self:sendBuglyLog("checkIapConfigByProductIDAndBuyType||currIapConfig is exist ||producID:" .. currIapConfig.productID .. " buytype : " .. currIapConfig.buyType)
    end

    return currIapConfig
end

--保存失败的支付列表
function IAPManager:saveIapInfoFile()
    -- csc 暂时允许mac写入
    if device.platform == "mac" then
        return
    end
    release_print("----csc 需要重新保存一次订单文件")
    print("----csc 需要重新保存一次订单文件")

    local configDatas = {}
    for i = 1, #self.m_failConfigList do
        configDatas[i] = self.m_failConfigList[i]:getJsonData()
    end
    local jsonData = cjson.encode(configDatas)
    local path = device.writablePath .. globalData.userRunData.uid .. "IAP_CONFIGS"
    -- local file = io.open(path, "wb+")
    -- file:write(jsonData)
    -- file:flush()
    -- file:close()
    cc.FileUtils:getInstance():writeStringToFile(jsonData, path)

    release_print("----csc 写入完毕 当前订单数 = " .. #self.m_failConfigList)
    print("----csc 写入完毕 当前订单数 = " .. #self.m_failConfigList)
    self:sendBuglyLog("saveIapInfoFile||fileList size = " .. #self.m_failConfigList)
end

--读取失败的支付列表
function IAPManager:readIapInfoFile()
    local path = device.writablePath .. globalData.userRunData.uid .. "IAP_CONFIGS"
    local configDatas = util_checkJsonDecode(path)
    if configDatas then
        configDatas = LongNumber.tbConvert(configDatas)
        self.m_failConfigList = {}
        for i = 1, #configDatas do
            local iapConfig = IAPConfig:create()
            iapConfig:parseData(configDatas[i])
            self.m_failConfigList[i] = iapConfig
            if iapConfig.orderID then
                release_print("----csc 读出的订单号 = " .. iapConfig.orderID)
                print("----csc 读出的订单号 = " .. iapConfig.orderID)
                self:sendBuglyLog("readIapInfoFiles||read orderID = " .. iapConfig.orderID)
            end
        end
    end
end

--清空失败列表
function IAPManager:clearFailList()
    self.m_failConfigList = {}
    self:saveIapInfoFile()
end

-- 解析回传的事物信息
function IAPManager:parseUncompleteTransaction(jsonData)
    self:sendBuglyLog("parseUncompleteTransaction|| start ")
    local newFailConfigList = {}

    -- 先对未完成的订单进行放置
    self:checkAllPurchasingOrder(newFailConfigList)
    for i = 1, table.nums(jsonData) do
        local orderData = jsonData[tostring(i)]
        -- release_print("----csc ddd order = "..orderData["sOrderId"])
        -- 对每一条json 数据进行匹配是否存在于当前文件里
        self:updateFailList(orderData, newFailConfigList)
        release_print("----csc 当前新的未完成订单list 数量 = " .. #newFailConfigList)
        print("----csc 当前新的未完成订单list 数量 = " .. #newFailConfigList)
    end
    -- 重新组装列表
    release_print("----csc 未完成订单处理完毕 重新写入失败列表文件")
    print("----csc 未完成订单处理完毕 重新写入失败列表文件")
    self.m_failConfigList = {}
    self.m_failConfigList = newFailConfigList
    self:saveIapInfoFile()
    self:sendBuglyLog("parseUncompleteTransaction|| end ")
end

--根据补单收据更新失败列表
function IAPManager:updateFailList(orderData, newFailConfigList)
    -- 补单情况只处理 purchased 的订单，
    local orderId = orderData["sOrderId"]
    local signature = orderData["sSignature"]
    local receipt = orderData["sReceipt"]
    local productId = orderData["sProductId"]
    local purchaseState = orderData["sPurchaseStatus"]
    local sUid = orderData["sUid"]
    local sBuyType = orderData["sBuyType"]
    --如果是 pruchaseing 转换成 purchased 的 ，需要我们手动切换状态为 purchased
    local function checkOrderExistNewList(key, value, buytype, configList)
        local bHad = false
        for i = 1, #configList do
            local iapConfig = configList[i]
            if iapConfig[key] and iapConfig[key] == value then
                if key == "productID" then
                    if buytype == iapConfig.buyType then
                        iapConfig.purchaseStatus = self.PurchaseState.PURCHASED
                        bHad = true
                        break
                    end
                else
                    iapConfig.purchaseStatus = self.PurchaseState.PURCHASED
                    bHad = true
                    break
                end
            end
        end
        -- 打印
        if bHad then
            release_print("----csc 当前订单已经存在过 newFailConfigList  中了,不允许再次添加 ")
            print("----csc 当前订单已经存在过 newFailConfigList  中了,不允许再次添加 ")
            release_print("----csc 把订单状态改成 purchased ")
            print("----csc 把订单状态改成 purchased ")
        end
        return bHad
    end

    local function updateNewFailConfigList(ID, buyType, orderId, signature, receipt, configList)
        for i = 1, #configList do
            local iapConfig = configList[i]
            if iapConfig["ID"] and iapConfig["ID"] == ID and iapConfig["buyType"] == buyType then
                release_print("----csc updateNewFailConfigList 当前订单的数据已经加入,手动更新一次")
                print("----csc updateNewFailConfigList 当前订单的数据已经加入,手动更新一次")
                iapConfig:updateReceipt(orderId, signature, receipt)
                iapConfig:updatePurchaseStatus(self.PurchaseState.PURCHASED)
                release_print("----csc updateFailList 补单操作更新后的 详细信息 sOrderId = " .. iapConfig.orderID)
                release_print("----csc updateFailList 补单操作更新后的 详细信息 sSignature = " .. iapConfig.signature)
                release_print("----csc updateFailList 补单操作更新后的 详细信息 sReceipt = " .. iapConfig.receipt)
                release_print("----csc updateFailList 补单操作更新后的 详细信息 sPurchaseStatus = " .. iapConfig.purchaseStatus)
                break
            end
        end
    end

    local configData = nil
    local checkKey = "orderID"
    local checkValue = orderId
    if MARKETSEL == AMAZON_MARKET then
        release_print("----csc 当前是 amazon 平台 因为orderID 无法作为唯一标识符，所以只通过查询productID来确认补单")
        checkKey = "productID"
        checkValue = productId
        configData = self:checkIapConfigByKeyValueForAmazon("productID", productId)
    else
        configData = self:checkIapConfigByKeyValue("orderID", orderId)
    end
    if configData then -- 如果当前订单已经存过在本地了，证明可能是服务器验证失败了，但是正常的购买已经保存过最新数据了
        -- 需要判断当前这笔订单是否已经加入过了
        if not checkOrderExistNewList(checkKey, checkValue, configData.buyType, newFailConfigList) then
            newFailConfigList[#newFailConfigList + 1] = configData
            release_print("----csc 验证orderid 在未完成队列中找到,记录到 newFailConfigList 中")
            print("----csc 验证orderid 在未完成队列中找到,记录到 newFailConfigList 中")
            self:sendBuglyLog("updateFailList|| save  newFailConfigList ")
        end
        -- csc 2022-03-23 15:54:46 这个 configData 只是中间变量，改变他没有任何意义 ，要改变 newFailConfigList 中的值才行
        -- 这个只会针对原先是 purchaseing 状态下的订单 转变成了 purchased 的补单操作
        if device.platform == "android" and MARKETSEL == GOOGLE_MARKET then
            release_print("----csc updateFailList 玩家现在的数据 详细信息 sOrderId = " .. configData.orderID)
            release_print("----csc updateFailList 玩家现在的数据 详细信息 sSignature = " .. configData.signature)
            release_print("----csc updateFailList 玩家现在的数据 详细信息 sReceipt = " .. configData.receipt)
            if configData.purchaseStatus == self.PurchaseState.PURCHASING then
                release_print("----csc 2022-03-23 验证orderid 当前订单 已经存过订单INAPP-PURCHASE-DATA 了，需要更新一下")
                updateNewFailConfigList(configData.ID, configData.buyType, orderId, signature, receipt, newFailConfigList)
            end
        end
    else
        -- 查询productID是否有存在的 因为所有没有订单号的调单，肯定都是
        release_print("----csc 验证orderid 失败 开始验证是否存在productID 相同的空订单")
        print("----csc 验证orderid 失败 开始验证是否存在productID 相同的空订单")

        -- csc 2022-01-08 新版本走新的接口
        if device.platform == "android" and MARKETSEL == GOOGLE_MARKET and util_isSupportVersion("1.6.0") then
            if not sBuyType or sBuyType == "" then
                release_print("----csc 当前符合新版本 但是补单数据中没有返回 buytype 走原来的逻辑")
                configData = self:checkIapConfigByKeyValue("productID", productId)
            else
                release_print("----csc 当前符合新版本 buytype : " .. tostring(sBuyType))
                configData = self:checkIapConfigByProductIDAndBuyType(productId, sBuyType)
            end
        else
            configData = self:checkIapConfigByKeyValue("productID", productId)
        end
        if configData then -- 如果找到有相同productID 就赋值进去
            -- 去 newFailConfigList 中检索是否存在 相同 productID 和 buytpype 的订单
            -- if not checkOrderExistNewList("productID",productId,configData.buyType,newFailConfigList) then
            release_print("----csc 找到空订单,讲订单号 收据填进去 并且更新购买状态为 PURCHASED")
            print("----csc 找到空订单,讲订单号 收据填进去 并且更新购买状态为 PURCHASED")
            -- configData:updateReceipt(orderId,signature,receipt)
            -- configData:updatePurchaseStatus(self.PurchaseState.PURCHASED)
            -- newFailConfigList[#newFailConfigList + 1] = configData
            -- else
            -- 需要去更新 newFailConfigList 里的那项订单收据
            updateNewFailConfigList(configData.ID, configData.buyType, orderId, signature, receipt, newFailConfigList)
            -- end
            self:sendBuglyLog("updateFailList|| update config state PURCHASED ")
        end
    end

    if configData then
        if MARKETSEL == AMAZON_MARKET then
            if configData.orderID == nil and configData.signature == nil and configData.receipt == nil then
                release_print("----csc 当前是 amazon 检测获取到的是空订单,需要更新一下数据")
                updateNewFailConfigList(configData.ID, configData.buyType, orderId, signature, receipt, newFailConfigList)
            end
        end
    end

    if configData == nil then
        -- 上述处理结果后还是没有找到值,将这个订单直接消耗掉
        release_print("----csc 上述处理结果后还是没有找到值,将这个订单直接消耗掉")
        print("----csc 上述处理结果后还是没有找到值,将这个订单直接消耗掉")
        self:sendBuglyLog("updateFailList|| onlyConsumePurchase ")
        self:getIapSDK():onlyConsumePurchase(orderId, receipt)
    end
end

function IAPManager:checkAllPurchasingOrder(newFailConfigList)
    release_print("----csc 补单操作之前先把所有的 purchasing 状态的订单保存起来")
    print("----csc 补单操作之前先把所有的 purchasing 状态的订单保存起来")
    for i = 1, #self.m_failConfigList do
        local iapConfig = self.m_failConfigList[i]
        if iapConfig["purchaseStatus"] == self.PurchaseState.PURCHASING then
            -- if iapConfig.orderID == nil  and iapConfig.signature == nil  and iapConfig.receipt  == nil then
            --     release_print("----csc 当前这个订单没有 订单号收据信息等,不需要存入")
            --     print("----csc 当前这个订单没有 订单号收据信息等,不需要存入")
            newFailConfigList[#newFailConfigList + 1] = clone(iapConfig)
        -- end
        end
    end
    release_print("----csc 当前  purchasing 状态的订单 数量 = " .. #newFailConfigList)
    print("----csc 当前  purchasing 状态的订单 数量 = " .. #newFailConfigList)
end
------------------------------- 订单操作 END

------------------------------- 补单逻辑 START
--请求失败收据列表
function IAPManager:requestFailReceiptList()
    self.m_bStart = true
    --读取当前当前存储的未成功的文件
    self:readIapInfoFile()
    --调用订单查询接口（事务查询）
    self:iapQueryPurchases()
    --调用查询 purchasing 状态订单接口
    self:iapQueryPurchasing()
end

--接收失败收据列表
function IAPManager:recvFailReceiptList(success, jsonData)
    if success then
        --更新失败支付列表
        release_print("----csc 解析补单数据 ")
        print("----csc 解析补单数据  ")
        if jsonData then
            if type(jsonData) == "table" then -- ios
                release_print("----csc jsonData 符合 table ")
                print("----csc jsonData 符合 table ")
                self:parseUncompleteTransaction(jsonData)
            else --可能是 android 的处理
                --....
                release_print("----csc jsonData 不符合 table ")
                print("----csc jsonData 不符合 table ")
            end
            --尝试发送补单信息
            self:checkRequestFailIapConfig()
        else
            --弹窗逻辑执行下一个事件
            -- 传入的json串有误
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        end
    else
        --完成补单流程
        -- gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)--弹窗逻辑执行下一个事件
        self:sendBuglyLog("recvFailReceiptList|| no failReceipt ")
        self:completeFailIapConfig()
    end
end
--尝试发送补单信息
function IAPManager:checkRequestFailIapConfig()
    --组装补单信息
    self.m_reConnectList = {}
    self.m_reConnectIndex = 1
    for i = 1, #self.m_failConfigList do
        local iapConfig = self.m_failConfigList[i]
        if iapConfig.purchaseStatus == self.PurchaseState.PURCHASED then
            release_print("----csc 当前补单队列创建 .. 放入 收据信息为 " .. iapConfig.receipt)
            print("----csc 当前补单队列创建 .. 放入 " .. iapConfig.receipt)
            self.m_reConnectList[#self.m_reConnectList + 1] = self.m_failConfigList[i]
        end
    end
    --执行补单步骤
    self:nextStepIapConfig()
end
--执行补单步骤
function IAPManager:nextStepIapConfig()
    release_print("----csc 开始补单！index = " .. self.m_reConnectIndex)
    print("----csc 开始补单！index = " .. self.m_reConnectIndex)
    self:sendBuglyLog("nextStepIapConfig|| start index  " .. self.m_reConnectIndex)
    if #self.m_reConnectList > 0 and #self.m_reConnectList >= self.m_reConnectIndex then
        local iapConfig = self.m_reConnectList[self.m_reConnectIndex]
        self.m_reConnectIndex = self.m_reConnectIndex + 1
        --发送补单信息
        self:requestFailIapConfig(iapConfig)
    else
        --完成补单流程
        self:completeFailIapConfig()
    end
end
--发送补单信息
function IAPManager:requestFailIapConfig(iapConfig)
    release_print("----csc  发送补单信息")
    print("----csc  发送补单信息")
    self:sendBuglyLog("requestFailIapConfig|| start ")
    self.m_reConnectConfig = iapConfig
    local extraData = self.m_reConnectConfig.extraData

    -- 后面牵扯太大，这部分先保留
    globalData.iapRunData.p_lastBuyId = self.m_reConnectConfig.extraData.iapId
    globalData.iapRunData.p_lastBuyCoin = self.m_reConnectConfig.extraData.totalCoin
    globalData.iapRunData.p_lastBuyType = self.m_reConnectConfig.extraData.buyType
    globalData.iapRunData.p_lastBuyPrice = self.m_reConnectConfig.extraData.buyPrice
    globalData.iapRunData.p_discounts = self.m_reConnectConfig.extraData.discounts
    globalData.iapRunData.p_activityId = self.m_reConnectConfig.extraData.activityId
    globalData.iapRunData.p_contentId = self.m_reConnectConfig.extraData.contentId
    globalData.iapRunData.iapExtraData = extraData

    -- 每次补单都设置一次
    gLobalDataManager:setStringByField(IAP_ORDER_ID, self.m_reConnectConfig.orderID)
    gLobalDataManager:setStringByField(IAP_SIGNATURE, self.m_reConnectConfig.signature)
    gLobalDataManager:setStringByField(IAP_RECEIPT, self.m_reConnectConfig.receipt)

    --进行补单
    --商店数据赋值
    if globalData.iapRunData.p_lastBuyType == BUY_TYPE.STORE_TYPE then
        local shopCoinData = globalData.shopRunData:getShopItemDatas()
        for i = 1, #shopCoinData do
            if shopCoinData[i].p_key == extraData.iapId then
                globalData.iapRunData.p_showData = shopCoinData[i] --只是为了获取打点数据 可以不要 装填到后续的结构 items
                break
            end
        end
    elseif globalData.iapRunData.p_lastBuyType == BUY_TYPE.GEM_TYPE then
        local _, shopGemData = globalData.shopRunData:getShopItemDatas()
        for i = 1, #shopGemData do
            if shopGemData[i].p_key == extraData.iapId then
                globalData.iapRunData.p_showData = shopGemData[i] --只是为了获取打点数据 可以不要 装填到后续的结构 items
                break
            end
        end
    elseif globalData.iapRunData.p_lastBuyType == BUY_TYPE.StorePet then
        local _, _, _, shopGemData = globalData.shopRunData:getShopItemDatas()
        for i = 1, #shopGemData do
            if shopGemData[i].p_key == extraData.iapId then
                globalData.iapRunData.p_showData = shopGemData[i] --只是为了获取打点数据 可以不要 装填到后续的结构 items
                break
            end
        end
    end
    --boostme数据赋值
    if globalData.iapRunData.p_lastBuyType == BUY_TYPE.BOOST_TYPE then
        local boostData = globalData.shopRunData.p_shopData.p_storeBoost
        for i = 1, 2 do
            if extraData.iapId == boostData.p_cashBackBoosts[i].p_key then
                globalData.iapRunData.p_showData = boostData.p_cashBackBoosts[i] --只是为了获取打点数据 可以不要 装填到后续的结构 items
                break
            end
            if extraData.iapId == boostData.p_levelBurstBoosts[i].p_key then
                globalData.iapRunData.p_showData = boostData.p_cashBackBoosts[i] --只是为了获取打点数据 可以不要 装填到后续的结构 items
                break
            end
            if extraData.iapId == boostData.p_bundleBoosts[i].p_key then
                globalData.iapRunData.p_showData = boostData.p_cashBackBoosts[i] --只是为了获取打点数据 可以不要 装填到后续的结构 items
                break
            end
        end
    end

    -- 开始补单的时候发送一次
    local order = self.m_reConnectConfig.orderID
    -- if MARKETSEL == AMAZON_MARKET then
    --     order = "A:" .. tostring(globalData.userRunData.uid) .. ":" .. tostring(os.time()) .. tostring(math.random(100, 999))
    --     gLobalDataManager:setStringByField(IAP_ORDER_ID, order)
    -- end
    gLobalSendDataManager:getLogIap():createOrder(order)
    gLobalDataManager:setStringByField("IAP_ORDER_TIME", self.m_reConnectConfig.createTime)
    gLobalSaleManager:resetVipInfo()

    gLobalSendDataManager:getLogIap():setIsBuDan(true)
    local next = nil
    -- 没钱促销处理
    next = self:resetIapUIByNoCoinsSale()
    if next then
        self:resetIapUIByNormalPurchase()
    end
    self:sendBuglyLog("requestFailIapConfig|| end ")
end
--接收补单信息
function IAPManager:recvFailIapConfig(success, bHas)
    release_print("----csc 补单 " .. tostring(success) .. " 进行下一单")
    print("----csc 补单 " .. tostring(success) .. " 进行下一单")
    if success then
        --补单成功操作
        release_print("----csc Log 补单成功 发送日志 ")
        print("----csc Log 补单成功 发送日志 ")
        self:sendIapLog(LOG_ENUM_TYPE.PaymentAction_rebuy, LOG_ENUM_TYPE.PaymentAction_reBuySuccess, "resetSendIapInfo")
        self:sendBuglyLog("recvFailIapConfig|| budan chenggong ")
    elseif bHas == nil then
        --每项补单都要发送一次结果
        release_print("----csc Log 补单失败 发送日志 ")
        print("----csc Log 补单失败 发送日志 ")
        self:sendIapLog(LOG_ENUM_TYPE.PaymentAction_rebuy, LOG_ENUM_TYPE.PaymentAction_reBuyFailed, self.customErrorTag.E_SERVERVERIFY_FAILED)
        self:sendBuglyLog("recvFailIapConfig||budan shibai ")
    end
    --执行补单步骤
    self:nextStepIapConfig()
end
--补单成功操作
function IAPManager:iapSuccessCallback()
    release_print("----csc 补单 进行订单消耗 ")
    print("----csc 补单 进行订单消耗 ")
    --调用订单消耗接口
    self:onlyConsumePurchase(self.m_reConnectConfig)
    self:sendBuglyLog("iapSuccessCallback|| onlyConsumePurchase ")
    --....
    -- csc 2022-04-19 新增iOS retry 补单操作判断
    -- 例如 pass 这类购买后没有弹窗的购买项，需要获得到 callback 才能顺利的完成解锁动画 （购买界面并没有关闭）
    -- 否则只是服务器数据上解锁了，但是前端并没有对应的动画表现，导致用户购买了两次或者多次
    -- 抛消息出去界面自行进行监听 处理
    if device.platform == "ios" then
        if self.m_bRetryPayment then
            self.m_bRetryPayment = false
            gLobalNoticManager:postNotification(IapEventType.IAP_RetrySuccess)
        end
    end
end
--完成补单流程
function IAPManager:completeFailIapConfig()
    --执行后续其他逻辑
    release_print("----csc 本次补单队列执行完毕 ！")
    print("----csc 本次补单队列执行完毕 ！")
    self:clearData()
    if not globalNoviceGuideManager:isNoobUsera() or globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.initIcons.id) then
        --不是新用户
        --新手金币指引完成
        --刷新金币
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {coins = globalData.userRunData.coinNum, isPlayEffect = false})
    end
    --清空订单信息
    -- gLobalSaleManager:clearAllUserIapOrder()
    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    --弹窗逻辑执行下一个事件

    self:sendBuglyLog("completeFailIapConfig|| budan wancheng  reset Step")
    self:resetLogStep()
end
------------------------------- 补单逻辑 END

------------------------------- Purcasing 订单逻辑 START
-- 开启定时器去检测当前订单队列
function IAPManager:openCheckPendingSchdule(oepnFrame)
    if self.m_schdulePending == nil then
        release_print("----csc  开启定时器进行 检测 是否存在pending 订单 ")
        print("----csc  开启定时器进行 检测 是否存在pending 订单 ")
        -- self:stopCheckPendingSchdule()

        -- 如果上次检测时间为0 的情况下， 直接开启 m_checkTime 时间的调度
        release_print("----csc m_lastCheckPurchasingTime =  " .. self.m_lastCheckPurchasingTime)
        if self.m_lastCheckPurchasingTime == 0 then
            release_print("----csc 开启正常调度 ")
            self.m_schdulePending =
                scheduler.scheduleGlobal(
                function()
                    self:updateCheckPendingList()
                end,
                self.m_checkTime
            )
            self.m_lastCheckPurchasingTime = os.time()
            gLobalDataManager:setNumberByField("iap_checkpurchasing_time", self.m_lastCheckPurchasingTime)

            release_print("----csc m_lastCheckPurchasingTime =  " .. self.m_lastCheckPurchasingTime)
        else
            local lastTime = os.time() - self.m_lastCheckPurchasingTime -- 间隔时间
            if lastTime > (self.m_checkTime * self.m_checkFaildTimes) then -- 如果已经超过总的检测轮次 ，直接让purchasing订单消耗掉
                release_print("----csc 当前间隔时间超过了总轮次 直接让这笔订单消耗掉")
                self.m_checkSuppleTimes = self.m_checkFaildTimes
                self:updateCheckPendingList()
            else
                -- 计算出当前 间隔时间是多少个 检测时间
                local times = lastTime / self.m_checkTime
                release_print("----csc 当前间隔时间是距离上次检测差了多少秒 = " .. lastTime)
                release_print("----csc 当前间隔时间是距离上次检测 间隔times = " .. math.floor(times))
                local newDelayTime = self.m_checkTime - lastTime
                if math.floor(times) > 0 then -- 需要把多余的次数补进去
                    self.m_checkSuppleTimes = math.floor(times)
                    -- 重新计算出下一次调度延迟时间
                    newDelayTime = lastTime - (self.m_checkTime * times)
                    release_print("----csc 要补充次数的情况下,下一次调度延迟时间 == " .. newDelayTime)
                    print("----csc 下一次调度延迟时间 == " .. newDelayTime)
                    scheduler.performWithDelayGlobal(
                        function()
                            self:delayUpdateCheckPendingList()
                        end,
                        newDelayTime
                    )
                else
                    release_print("----csc 下一次调度延迟时间 == " .. newDelayTime)
                    print("----csc 下一次调度延迟时间 == " .. newDelayTime)
                    self.m_checkSuppleTimes = 1
                    scheduler.performWithDelayGlobal(
                        function()
                            self:delayUpdateCheckPendingList()
                        end,
                        newDelayTime
                    )
                end
            end
        end

        self.m_pendingState = true
    else
        release_print("----csc 当前订单状态返回为 pending ,定时器已经开启")
        print("----csc 当前订单状态返回为 pending ,定时器已经开启")
        return
    end
end

function IAPManager:delayUpdateCheckPendingList()
    self:updateCheckPendingList()
    release_print("----csc delayUpdateCheckPendingList 重新开始正常时间purchasing 请求计时器")
    print("----csc delayUpdateCheckPendingList 重新开始正常时间purchasing 请求计时器")
    if self.m_schdulePending == nil then
        self.m_schdulePending =
            scheduler.scheduleGlobal(
            function()
                self:updateCheckPendingList()
            end,
            self.m_checkTime
        )
        self.m_lastCheckPurchasingTime = os.time()
        gLobalDataManager:setNumberByField("iap_checkpurchasing_time", self.m_lastCheckPurchasingTime)

        release_print("----csc m_lastCheckPurchasingTime =  " .. self.m_lastCheckPurchasingTime)
    end
end

-- 通过sdk 去请求当前是否存在purchasing 状态的订单
function IAPManager:getPendinglist(func)
    local bHad = false
    local callback = function(result)
        if result then
            local content = cjson.decode(result)
            local bHas = content["hasPendingOrder"]
            bHad = bHas
        end

        if bHad then
            release_print("----csc getPendinglist  > 0 可以开启调度")
            print("----csc getPendinglist  > 0 可以开启调度")
            self:sendBuglyLog("getPendinglist || purchasing list > 0")
            func()
        else
            self:stopCheckPendingSchdule()
        end
    end

    self:getIapSDK():checkPendingTransactions(callback)
end

-- 定时器去 请求当前sdk端是否存在pengding 订单 刷新数据
function IAPManager:updateCheckPendingList()
    release_print("----csc updateCheckPendingList pending")
    print("----csc updateCheckPendingList pending")
    local callback = function(result)
        if result then
            local content = cjson.decode(result)
            local bHas = content["hasPendingOrder"]
            local jsonData = content["jsonData"]
            local errorCode = content["errorCode"]
            if errorCode then
                release_print("----csc Log purchasing商品获取成功,回传lua 过程中失败 errorCode = " .. errorCode)
                print("----csc Log purchasing商品获取成功,回传lua 过程中失败 errorCode = " .. errorCode)
                self:sendIapLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_ENUM_TYPE.PaymentAction_reCheckPendingFailed, errorCode)
            else
                self:recvPendingList(bHas, jsonData)
            end
        else
            --
            release_print("----csc 当前没有获取到 pending 中的订单信息 停掉定时器")
            print("----csc 当前没有获取到 pending 中的订单信息 停掉定时器")
            self:stopCheckPendingSchdule()
        end
    end

    self:getIapSDK():checkPendingTransactions(callback)

    self.m_lastCheckPurchasingTime = os.time()
    gLobalDataManager:setNumberByField("iap_checkpurchasing_time", self.m_lastCheckPurchasingTime)

    release_print("----csc m_lastCheckPurchasingTime =  " .. self.m_lastCheckPurchasingTime)

    -- if table.nums(self.m_failConfigList) > 0  then

    -- else
    --     -- 如果当前文件列表中没有数据,
    --     release_print("----csc 当前订单列表为空 --- 需要关闭定时器")
    --     print("----csc 当前订单列表为空  --- 需要关闭定时器")
    --     self:stopCheckPendingSchdule()
    -- end
end

function IAPManager:recvPendingList(bHas, jsonData)
    if bHas then
        if jsonData then
            if type(jsonData) == "table" then
                -- 去更新pending 检测次数
                for i = 1, table.nums(jsonData) do
                    local orderData = jsonData[tostring(i)]
                    self:updatePurchasingCount(orderData)
                end
                if table.nums(self.m_failConfigList) == 0 and self.m_schdulePending then
                    release_print("----csc 当前订单列表为空 --- 需要关闭定时器")
                    print("----csc 当前订单列表为空  --- 需要关闭定时器")
                    self:stopCheckPendingSchdule()
                end
            end
        else
            -- 传入的json串有误
            release_print("----csc recvPendingList 传入的json串有误 ")
            print("----csc recvPendingList 传入的json串有误 ")
        end
    else
        release_print("----csc 当前没有获取到 pending 中的订单信息 停掉定时器 当前文件中的订单数 = " .. #self.m_failConfigList)
        print("----csc 当前没有获取到 pending 中的订单信息 停掉定时器 当前文件中的订单数 = " .. #self.m_failConfigList)
        self:stopCheckPendingSchdule()
    end
end

function IAPManager:updatePurchasingCount(orderData)
    local orderId = orderData["sOrderId"]
    local signature = orderData["sSignature"]
    local receipt = orderData["sReceipt"]
    local productId = orderData["sProductId"]
    local sUid = orderData["sUid"]
    local sBuyType = orderData["sBuyType"]
    if table.nums(self.m_failConfigList) == 0 then
        --
        release_print("----csc 异常处理 当前文件为空,但是还有purchasing状态的订单,需要消耗掉 orderId == " .. orderId)
        print("----csc 异常处理 当前文件为空,但是还有purchasing状态的订单,需要消耗掉 orderId == " .. orderId)
        self:getIapSDK():removePendingTransactions(orderId)
        return
    end

    local openFrame = false
    for i = #self.m_failConfigList, 1, -1 do
        local iapConfig = self.m_failConfigList[i]
        if iapConfig["orderID"] and iapConfig["orderID"] == orderId then
            if iapConfig.purchaseStatus == "PURCHASING" then
                iapConfig.purchasingCount = iapConfig.purchasingCount + self.m_checkSuppleTimes
                if iapConfig.purchasingCount == 1 then
                    release_print("----csc 当前订单 pengding 检测第一次 玩家等待已经超过时间 -- 弹出面板让玩家继续游戏")
                    print("----csc 当前订单 pengding 检测第一次 玩家等待已经超过时间 -- 弹出面板让玩家继续游戏")
                    self:purchasingWaitResult()
                    self:sendBuglyLog("updatePurchasingCount||purchasingWaitResult")
                end
                if iapConfig.purchasingCount >= self.m_checkFaildTimes then
                    release_print("----csc 当前订单检测 pending 状态次数超过次数限制 -- 进行消耗 并且 删除  --- ID = " .. iapConfig.ID)
                    print("----csc 当前订单检测 pending 状态次数超过次数限制 -- 进行消耗 并且 删除 --- ID = " .. iapConfig.ID)
                    self:getIapSDK():removePendingTransactions(iapConfig.orderID)
                    self:removeIapConfig(iapConfig.ID)
                    openFrame = true
                    self:sendBuglyLog("updatePurchasingCount||removePendingTransactions")
                else
                    release_print("----csc 当前订单 orderID " .. iapConfig.orderID .. " 检测 pending 状态次数  = " .. iapConfig.purchasingCount)
                    print("----csc 当前订单 orderID " .. iapConfig.orderID .. " 检测 pending 状态次数  = " .. iapConfig.purchasingCount)
                    self:saveIapInfoFile()
                    self:sendBuglyLog("updatePurchasingCount||update count = " .. iapConfig.purchasingCount)
                end
            end
        end
    end
    if openFrame then
        self:purchasingFailed()
    end
end

function IAPManager:stopCheckPendingSchdule()
    release_print("----csc stopCheckPendingSchdule ")
    self.m_pendingState = false
    self.m_lastCheckPurchasingTime = 0
    self.m_checkSuppleTimes = 1
    gLobalDataManager:setNumberByField("iap_checkpurchasing_time", self.m_lastCheckPurchasingTime)
    if self.m_schdulePending ~= nil then
        scheduler.unscheduleGlobal(self.m_schdulePending)
        self.m_schdulePending = nil
    end
end

------------------------------- Purcasing 订单逻辑 END

------------------------------- SDK调用接口 START
--调用订单查询接口（事务查询）
function IAPManager:iapQueryPurchases()
    if self.m_bStart == false then
        release_print("----csc 当前 付费文件还没有开始读取, 不进行订单查询")
        return
    end
    local _callbackFunc = function(result)
        -- 检查当前是否有未完成的队列
        self:sendBuglyLog("checkUncompleteTransactions||callback")
        if result then
            local content = cjson.decode(result)
            local bHas = content["hasOrder"]
            local jsonData = content["jsonData"]
            local errorCode = content["errorCode"]
            if errorCode then
                -- 这里需要做个转换  -- 新版本已经都转换成了 number
                if tonumber(errorCode) == -110 then
                    --弹窗逻辑执行下一个事件
                    release_print("----csc Log 当前玩家不支持Billing  errorCode = " .. errorCode)
                    print("----csc Log 当前玩家不支持Billing errorCode = " .. errorCode)
                    -- 这种地方不需要弹出设备不支持的错误码弹板，因为这里是上线检查补单.
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                else
                    release_print("----csc Log 补单商品获取成功,收据回传lua过程中失败 errorCode = " .. errorCode)
                    print("----csc Log 补单商品获取成功,收据回传lua过程中失败 errorCode = " .. errorCode)
                end
                self:sendIapLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_ENUM_TYPE.PaymentAction_reBuyFailed, errorCode)
            else
                self:recvFailReceiptList(bHas, jsonData)
            end
        else
            --弹窗逻辑执行下一个事件
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        end
    end
    -- 请求是否有补单信息
    self:getIapSDK():checkUncompleteTransactions(_callbackFunc)
end

--调用查询 purchasing 状态订单接口
function IAPManager:iapQueryPurchasing()
    if self.m_bStart == false then
        release_print("----csc 当前 付费文件还没有开始读取, 不进行订单查询")
        return
    end
    -- 请求是否有pending信息 不用提示弹窗
    self:getPendinglist(
        function()
            self:openCheckPendingSchdule(false)
        end
    )

    -- self:updateCheckPendingList()
end

--调用订单消耗接口
function IAPManager:iapCosumeAsync(iapConfig)
    release_print("----csc 开始进行消耗 订单信息 orderID " .. iapConfig:getJsonData().orderID)
    print("----csc 开始进行消耗 订单信息 orderID " .. iapConfig:getJsonData().orderID)
    self:sendBuglyLog("iapCosumeAsync|| start consumePurchase ")
    -- csc fix 2021-08-05 修复消耗添加屏蔽层5秒自动消失
    gLobalViewManager:addLoadingAnima(nil, nil, 5)
    if CC_IS_TEST_BUY then
        -- gLobalNoticManager:postNotification(GlobalEvent.IAP_ConsumeResult, {false,"-103"})
        gLobalNoticManager:postNotification(GlobalEvent.IAP_ConsumeResult, {true})
    else
        local orderId = iapConfig.orderID
        local receipt = iapConfig.receipt
        self:getIapSDK():consumePurchase(orderId, receipt)
    end
end

--调用订单消耗接口回调
function IAPManager:recvConsumeCallback(buytype, orderID)
    release_print("----csc 消耗完毕 准备移除订单 orderID = " .. orderID)
    print("----csc 消耗完毕 准备移除订单 orderID = " .. orderID)
    self:sendBuglyLog("recvConsumeCallback|| start  ")
    local iapConfig = self:checkIapConfigByKeyValue("orderID", orderID)
    --移除订单
    if iapConfig then
        self:sendBuglyLog("recvConsumeCallback|| removeIapConfig  ")
        self:removeIapConfig(iapConfig.ID)
        self.m_currIapOrderId = nil
    end
    self:sendBuglyLog("recvConsumeCallback|| end  ")
end

-- 调用订单消耗接口 --- 仅消耗
function IAPManager:onlyConsumePurchase(iapConfig)
    -- 移除遮罩
    gLobalViewManager:removeLoadingAnima()

    local orderId = iapConfig.orderID
    local receipt = iapConfig.receipt
    self:getIapSDK():onlyConsumePurchase(orderId, receipt)

    self:removeIapConfig(iapConfig.ID)
end
------------------------------- SDK调用接口 END

------------------------------- 补单界面逻辑 START
function IAPManager:resetIapUIByNoCoinsSale()
    if self.m_reConnectConfig.buyType == BUY_TYPE.NOCOINSSPECIALSALE then
        self:sendBuglyLog("resetIapUIByNoCoinsSale||start")
        gLobalViewManager:addLoadingAnima()

        local function success()
            release_print("----csc 当前补单 订单验证通过 -----")
            print("----csc 当前补单 订单验证通过 -----")
            self:sendBuglyLog("resetIapUIByNoCoinsSale||success")
            local buyData = {reBuyCoins = self.m_reConnectConfig.extraData.totalCoin, reBuyType = self.m_reConnectConfig.extraData.buyType, reBuyData = nil}
            gLobalSaleManager:setBuyDataInfo(buyData, globalData.iapRunData.iapExtraData)
            local view = util_createView("GameModule.Shop.BuyTip")
            view:initBuyTip(buyData.reBuyType, buyData.reBuyData, tonumber(buyData.reBuyCoins), 0)
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            view:setOverFunc(
                function()
                    --执行下一个补单步骤
                    self:recvFailIapConfig(true)
                end
            )
            self:iapSuccessCallback()
            gLobalNoticManager:postNotification("hide_vedio_icon")
        end

        local function failed(bHas)
            self:sendBuglyLog("resetIapUIByNoCoinsSale||failed")
            if bHas then
                release_print("----csc 当前订单已经验证过了,可能是消耗失败导致的没有删除补单信息,进行重新消耗")
                print("----csc 当前订单已经验证过了,可能是消耗失败导致的没有删除补单信息,进行重新消耗")
                self:onlyConsumePurchase(self.m_reConnectConfig)
            else
                self:updateFailedCount(self.m_reConnectConfig)
            end
            --执行下一个补单步骤
            self:recvFailIapConfig(false, bHas)
        end

        gLobalSaleManager:requestNoCoinsSale(
            function(isOk)
                gLobalViewManager:removeLoadingAnima()
                if isOk then
                    ---发送服务器同步消息
                    gLobalSendDataManager:getNetWorkIap():sendActionPurchaseInfo(
                        function()
                            success()
                        end,
                        function(bHas)
                            failed(bHas)
                        end,
                        self.m_testReSkipServer
                    )
                    -- csc test代码
                    if DEBUG == 2 then
                        if self.m_testReSkipServer then
                            if self.m_testReBuySuccess then
                                success()
                            else
                                failed(false)
                            end
                        end
                    end
                else
                    --执行下一个补单步骤
                    self:recvFailIapConfig(false)
                end
            end
        )
        return false
    end
    return true
end

function IAPManager:resetIapUIByNormalPurchase()
    ---发送服务器同步消息
    local extraData = self.m_reConnectConfig.extraData
    gLobalViewManager:addLoadingAnima()
    self:sendBuglyLog("resetIapUIByNormalPurchase||start")
    local function success()
        release_print("----csc 当前 NomalPurchase 补单 订单验证通过 -----")
        print("----csc 当前 NomalPurchase 补单 订单验证通过 -----")
        self:sendBuglyLog("resetIapUIByNormalPurchase||success")
        gLobalViewManager:removeLoadingAnima()

        if (self.m_reConnectConfig.buyType == BUY_TYPE.LUCKY_SPIN_TYPE or self.m_reConnectConfig.buyType == BUY_TYPE.LUCKY_SPINV2_TYPE) and extraData.contentId == nil  then
            globalData.iapLuckySpinFunc = function()
                self:iapSuccessCallback()
                self:recvFailIapConfig(true)
            end
            local index = gLobalDataManager:getNumberByField("lastBuyLuckySpinID", 1)
            -- TODO:MAQUN 钻石商城暂时没有luckyspin
            local shopDatas = globalData.shopRunData:getShopItemDatas()
            local m_index = 1
            for i,v in ipairs(shopDatas) do
                if v.p_price == globalData.luckySpinV2:getPrice() then
                    m_index = i
                    break
                end
            end
            local data = {}
            data.buyShopData = shopDatas[m_index]
            data.reconnect = true
            data.buyIndex = index
            data.type = globalData.luckySpinV2:getType()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum - data.buyShopData.p_coins)
            G_GetMgr(G_REF.LuckySpin):popSpinLayer(data)
            gLobalNoticManager:postNotification("hide_vedio_icon")
            return
        elseif self.m_reConnectConfig.buyType == BUY_TYPE.FIRST_SALE_MULTI then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
        end

        local buyData = {reBuyCoins = extraData.totalCoin, reBuyType = extraData.buyType, reBuyData = nil, contentId = extraData.contentId}

        -- 融合 extraData 和 globalData.iapRunData.iapExtraData
        local newExtra = self:createNewTable(extraData, globalData.iapRunData.iapExtraData)

        gLobalSaleManager:setBuyDataInfo(buyData, newExtra)
        if buyData.reBuyType == BUY_TYPE.TopSale then
            local activityData = G_GetMgr(ACTIVITY_REF.Promotion_TopSale):getRunningData()
            if activityData then
                activityData:changeToDirty()
            end
        end
        if buyData and buyData.reBuyData then
            release_print("----csc 有 reBuyData  数据 购买类型-----" .. extraData.buyType)
            print("----csc 有 reBuyData  数据 购买类型-----" .. extraData.buyType)

            if self.m_reConnectConfig.buyType == BUY_TYPE.SPECIALSALE_FIRST then
                G_GetMgr(G_REF.FirstCommonSale):deleteFirstSaleData() -- 需要删掉数据
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FIRST_SALE_BUYSUCCESS)
            end

            -- 判断下商城折扣开关
            if buyData.contentId and (buyData.reBuyType == "Store" or buyData.reBuyType == "Gem") then
                if buyData.reBuyData.p_coins and buyData.reBuyData.p_originalCoins then
                    buyData.reBuyData.p_coins = buyData.reBuyData.p_originalCoins
                elseif buyData.reBuyData.p_gems and buyData.reBuyData.p_originalGems then
                    buyData.reBuyData.p_gems = buyData.reBuyData.p_originalGems
                end
                -- 折扣活动送道具
                local couponData = G_GetMgr(ACTIVITY_REF.Coupon):getRunningData()
                if couponData and buyData.reBuyData.p_displayList then
                    local itemData = {}
                    local couponItems = couponData:getShopGifts()
                    for i,v in ipairs(buyData.reBuyData.p_displayList) do
                        local insert = true
                        for k,n in ipairs(couponItems) do
                            if v.p_id == n.p_id then
                                insert = false
                                break
                            end
                        end        
                        if insert then
                            table.insert(itemData, v)
                        end
                    end
                    buyData.reBuyData.p_displayList = itemData
                end
            end

            --需要做一个判断，防止购买后数值不对的问题
            if buyData.reBuyData.p_coins then
                release_print("----csc 有 reBuyData.p_coins-----" .. tostring(buyData.reBuyData.p_coins))
                release_print("----csc 有 reBuyCoins-----" .. tostring(buyData.reBuyCoins))
                local _coins = tonumber(buyData.reBuyData.p_coins)
                local _reBuyCoins = tonumber(buyData.reBuyCoins)
                if _coins and _reBuyCoins and _coins < _reBuyCoins then
                    buyData.reBuyData.p_coins = buyData.reBuyCoins
                end
            end
            if buyData.reBuyData.p_gems then
                if tonumber(buyData.reBuyData.p_gems) < tonumber(buyData.reBuyCoins) then
                    buyData.reBuyData.p_gems = buyData.reBuyCoins
                end
            end

            local view = util_createView("GameModule.Shop.BuyTip")
            view:initBuyTip(buyData.reBuyType, buyData.reBuyData, tonumber(buyData.reBuyCoins), 0)
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            view:setOverFunc(
                function()
                    --执行下一个补单步骤
                    self:recvFailIapConfig(true)
                end
            )
            self:iapSuccessCallback()
            gLobalNoticManager:postNotification("hide_vedio_icon")
        else
            release_print("----csc 当前找不到 弹窗数据, 但是服务器验证已经通过,可以去消耗掉")
            print("----csc 没有 reBuyData  数据 要去决定当前type是否可以直接屏蔽掉 去消耗 -----")
            --执行下一个补单步骤
            self:iapSuccessCallback()
            self:recvFailIapConfig(true)
        end
        -- 补单成功
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REPAY_IAPORDER_SUC)
    end

    local function failed(bHas)
        gLobalViewManager:removeLoadingAnima()
        self:sendBuglyLog("resetIapUIByNormalPurchase||failed")
        if bHas then
            release_print("----csc 当前订单已经验证过了,可能是消耗失败导致的没有删除补单信息,进行重新消耗")
            print("----csc 当前订单已经验证过了,可能是消耗失败导致的没有删除补单信息,进行重新消耗")
            self:onlyConsumePurchase(self.m_reConnectConfig)
        else
            self:updateFailedCount(self.m_reConnectConfig)
        end
        --执行下一个补单步骤
        self:recvFailIapConfig(false, bHas)
    end

    gLobalSendDataManager:getNetWorkIap():sendActionPurchaseInfo(
        function()
            success()
        end,
        function(bHas)
            failed(bHas)
        end,
        self.m_testReSkipServer
    )

    -- csc test代码
    if DEBUG == 2 then
        if self.m_testReSkipServer then
            if self.m_testReBuySuccess then
                success()
            else
                failed(false)
            end
        end
    end
end

-- 获取当前补单状态- 如果不是最后一单，都不允许弹出收集框
function IAPManager:getCurrRePayStatus()
    -- true 代表可以弹出后续弹框
    if self.m_reConnectIndex - 1 == #self.m_reConnectList then
        return true
    else
        return false
    end
end
------------------------------- 补单界面逻辑 END
------------------------------- 功能性代码
function IAPManager:createNewTable(tableA, tableB, ...)
    local newTable = {}
    for k, v in pairs(tableA) do
        newTable[k] = v
    end
    for k, v in pairs(tableB) do
        newTable[k] = v
    end
    return newTable
end

-- 统一的发送log方法
function IAPManager:sendIapLog(operationType, operationStatus, logCode)
    if logCode then
        gLobalSendDataManager:getLogIap():setSdkCode("code:" .. logCode)
    else
        gLobalSendDataManager:getLogIap():setSdkCode(nil)
    end
    gLobalSendDataManager:getLogIap():sendUiLog(operationType, operationStatus)
end

function IAPManager:getReBuySpecailSaleBuffType()
    if self.m_reConnectConfig then
        return self.m_reConnectConfig.extraData.buff
    end
    return nil
end

--玩家进行重试的操作 根据当前发送来的情景 进行不同的操作
function IAPManager:retryPayment(errorStr)
    if errorStr then
        self:sendBuglyLog("retryPayment | start scene = " .. errorStr)
        if errorStr == self.customErrorTag.E_IOS_SUCCESSRETRY then
            self.m_bRetryPayment = true
            -- 这种情况是ios下,玩家成功完成订单，但是找不到唯一标识符，进行特定的返回值
            self:iapQueryPurchases()
        end
        self:sendBuglyLog("retryPayment | start end")
    end
end

function IAPManager:checkSdkCallback()
    -- 需要加版本号判断
    if device.platform == "android" then
        if self.m_bSdkPullOnCallback == true then
            if util_isSupportVersion("1.3.7") then
                if MARKETSEL == AMAZON_MARKET then
                    release_print("----csc 当前是 amazon 平台 先不处理 后台返回")
                else
                    release_print("----csc 检测到当前是home键返回的情况,开启调度检测是否有订单未完成")
                    if util_isSupportVersion("1.5.7") then
                        self.m_homebackDelayIndex = 1
                        self:startCheckHomeBackPurchaseSchedule()
                    else
                        gLobalNoticManager:postNotification(GlobalEvent.IAP_BuyResult, {tonumber(1), "home back cancel"})
                    end
                end
            else
                release_print("----csc 当前是通过返回后台清理掉弹窗,没有走到正常返回,需要做处理")
                self:sendBuglyLog("checkSdkCallback || commonForeGround callback !!")
            end
            self.m_bSdkPullOnCallback = false
        end
    end
end

--[[
    @desc: home 返回游戏需要删除订单数据,但是玩家可能是因为弱网环境导致的未完成数为0，需要开启检测
    author:csc
    time:2021-11-15 17:31:34
]]
function IAPManager:startCheckHomeBackPurchaseSchedule()
    gLobalViewManager:addLoadingAnima()
    if self.m_schduleHomeBack == nil then
        local delayTime = self.m_homebackCheckTimeList[self.m_homebackDelayIndex]
        release_print("----csc startCheckHomeBackPurchaseSchedule delayTime = " .. delayTime)
        self:sendBuglyLog("checkSdkCallback||startCheckHomeBackPurchaseSchedule||delayTime:" .. delayTime)
        self.m_schduleHomeBack =
            scheduler.performWithDelayGlobal(
            function()
                release_print("----csc 检测 google 底层 queryPurchases")
                self.m_homebackDelayIndex = self.m_homebackDelayIndex + 1
                -- 需要停掉当前的定时器，并且开启下一个定时器
                self:stopCheckHomeBackPurchaseSchedule()
                if self.m_homebackDelayIndex <= #self.m_homebackCheckTimeList then
                    self:startCheckHomeBackPurchaseSchedule()
                    self:sendBuglyLog("checkSdkCallback||startCheckHomeBackPurchaseSchedule||queryPurchases")
                    self:getIapSDK():queryPurchases()
                else
                    gLobalViewManager:removeLoadingAnima()
                    self:sendBuglyLog("checkSdkCallback||startCheckHomeBackPurchaseSchedule||home back cancel")
                    release_print("----csc startCheckHomeBackPurchaseSchedule 检测已经全部走完，并没有发现有未完成的订单,发送 home back cancel")
                    gLobalNoticManager:postNotification(GlobalEvent.IAP_BuyResult, {tonumber(1), "home back cancel"})
                end
            end,
            delayTime
        )
    end
end

function IAPManager:stopCheckHomeBackPurchaseSchedule()
    release_print("----csc stopCheckHomeBackPurchaseSchedule ")
    if self.m_schduleHomeBack ~= nil then
        scheduler.unscheduleGlobal(self.m_schduleHomeBack)
        self.m_schduleHomeBack = nil
    end
end
------------------------------- 功能性代码

------------------------------- 弹板总控代码
function IAPManager:customPushViewControl(errorcode, errorStr, errorMessage) -- 1.错误代码  2.自定义字段 3.信息
    self.m_currErrorTag = nil
    -- 转换一下code type
    errorcode = tonumber(errorcode)
    local errorStr = errorStr
    -- 有明确错误码传进来的 走判断
    -- 这里如果是错误码 ios == 2 或者 android == 1 的情况认为是用户取消 不需要弹窗
    if device.platform == "ios" or device.platform == "mac" then
        if errorcode == -101 or errorcode == -102 or errorcode == -106 then
            errorStr = self.customErrorTag.E_IOS_PAYMENTFAILED
        elseif errorcode == -111 then
            errorStr = self.customErrorTag.E_IOS_UNSUPPORT
        elseif errorcode == 0 or errorcode == 7 or errorcode == -999 or errorcode == -1001 or errorcode == -1005 or errorcode == -1009 or errorcode == 4097 then
            errorStr = self.customErrorTag.E_IOS_DISCONNECTED
        elseif errorcode == 2 then
            errorStr = "user_cancel"
        end
    elseif device.platform == "android" then
        if errorcode == -3 or errorcode == -1 or errorcode == 2 then -- 连接gp 服务器失败
            errorStr = self.customErrorTag.E_GP_DISCONNECTED
        elseif errorcode == -2 or errorcode == -110 then -- 设备不支持
            errorStr = self.customErrorTag.E_GP_UNSUPPORT
        elseif errorcode == 7 then -- 商品已经拥有
            errorStr = self.customErrorTag.E_GP_ORDEROWNED
        elseif errorcode == 5 or errorcode == 6 then -- 底层问题导致的失败
            errorStr = self.customErrorTag.E_GP_PAYMENTFAILED
        elseif errorcode == 1 then
            errorStr = "user_cancel"
        end
    end

    self.m_currErrorTag = errorStr

    if errorStr == nil then -- 异常处理 如果出现了非正常错误代码,默认弹出统一的失败框
        self:purchaseFailed()
        self:sendBuglyLog("customPushViewControl|pop default purchaseFailed errorcode =" .. tostring(errorcode) .. " errorMessage is " .. tostring(errorMessage))
    elseif errorStr == "user_cancel" then
        -- 用户取消操作,什么也不用弹
        if self.m_buyFailedCallFun then
            local cbInfo = {
                errorMsg = errorStr,
                bCancel = true,
                curPayInfo = self.m_curIapConfig
            }
            self.m_buyFailedCallFun(cbInfo)
        end
        self:checkRemovePayConfirmLayerMask()
        self:sendBuglyLog("customPushViewControl|user cancel payment dont pop view errorcode = " .. errorcode .. " errorMessage is " .. tostring(errorMessage))
    else
        local dialogLayerInfo = self.paymentResTable[errorStr]
        if dialogLayerInfo then
            local btnContact = function()
                gLobalViewManager:removeLoadingAnima()
                print("发邮件")
                local bVersion = util_isSupportVersion("1.2.9")
                if device.platform == "android" then
                    bVersion = util_isSupportVersion("1.3.0")
                end
                if bVersion then
                    --通知界面去打开 aihelp
                    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OPEN_ROBOT, "PurchaseError")
                    globalPlatformManager:openAIHelpRobot("PurchaseError")
                else
                    xcyy.GameBridgeLua:sendEmail()
                end
                if self.m_buyFailedCallFun then
                    self.m_buyFailedCallFun()
                end
                self:checkRemovePayConfirmLayerMask()
            end
            local btnOk = function()
                gLobalViewManager:removeLoadingAnima()
                if dialogLayerInfo.retry == true then
                    --玩家进行了重试,根据重试的场景,进行判断
                    self:retryPayment(errorStr)
                else
                    if self.m_buyFailedCallFun then
                        self.m_buyFailedCallFun()
                    end
                    self:checkRemovePayConfirmLayerMask()
                end
            end

            local csbname = "Dialog/CustomPaymentLayer.csb"
            if dialogLayerInfo.contact == true then
                csbname = "Dialog/CustomPaymentLayer2.csb"
            end
            local dialogLayer = gLobalViewManager:showDialog(csbname, btnOk, btnContact, false, ViewZorder.ZORDER_POPUI)

            local spr_context = dialogLayer:findChild("lb_text")
            spr_context:setString(dialogLayerInfo.context)
            if dialogLayerInfo.retry == true then
                local str = gLobalLanguageChangeManager:getStringByKey("CustomPayment:retry") or "RETRY"
                dialogLayer:setButtonLabelContent("btn_ok", str)
            end
            self:sendBuglyLog("customPushViewControl|pop errorCode = " .. tostring(errorcode) .. " errorStr = " .. tostring(errorStr) .. " errorMessage is " .. tostring(errorMessage))
        else
            self:purchaseFailed()
            self:sendBuglyLog("customPushViewControl|no dialogLayerInfo pop default purchaseFailed")
        end
    end
end

function IAPManager:purchaseFailed()
    --弹出 提示界面 联系客服
    gLobalViewManager:showDialog(
        "Dialog/PurchaseFailed.csb",
        function()
            print("发邮件")
            -- gLobalTriggerManager:postNextView()
            -- gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            local bVersion = util_isSupportVersion("1.2.9")
            if device.platform == "android" then
                bVersion = util_isSupportVersion("1.3.0")
            end
            if bVersion then
                --通知界面去打开 aihelp
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OPEN_ROBOT, "PurchaseFailed")
            else
                xcyy.GameBridgeLua:sendEmail()
            end
        end,
        function()
            -- gLobalTriggerManager:postNextView()
            -- gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            print("返回充值")
        end,
        false,
        ViewZorder.ZORDER_POPUI
    )
    gLobalViewManager:removeLoadingAnima()
    if self.m_buyFailedCallFun then
        self.m_buyFailedCallFun()
    end
    self:checkRemovePayConfirmLayerMask()
end

function IAPManager:purchasingWaitResult()
    release_print("----csc 弹出等待充值结果 板子")
    print("----csc 弹出等待充值结果 板子")
    gLobalViewManager:showDialog(
        "Dialog/Purchasing2.csb",
        function()
            release_print("----csc 等待充值结果")
            print("----csc 等待充值结果")
        end,
        nil,
        false,
        ViewZorder.ZORDER_POPUI
    )
    gLobalViewManager:removeLoadingAnima()
end

function IAPManager:purchasingWait()
    release_print("----csc 弹出当前有购买项正在进行中的 板子")
    print("----csc 弹出当前有购买项正在进行中的 板子")
    gLobalViewManager:showDialog(
        "Dialog/Purchasing.csb",
        function()
            release_print("----csc 当前有购买项正在进行中")
            print("----csc 当前有购买项正在进行中")
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PURCHASING_CLOSE)
        end,
        nil,
        false,
        ViewZorder.ZORDER_POPUI
    )
    gLobalViewManager:removeLoadingAnima()
end

function IAPManager:purchasingFailed()
    --弹出 提示界面 联系客服
    release_print("----csc 弹出等待充值失败的 板子")
    print("----csc 弹弹出等待充值失败的 板子")
    gLobalViewManager:showDialog(
        "Dialog/PurchasingFailed.csb",
        function()
            print("发邮件")
            local bVersion = util_isSupportVersion("1.2.9")
            if device.platform == "android" then
                bVersion = util_isSupportVersion("1.3.0")
            end
            if bVersion then
                --通知界面去打开 aihelp
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OPEN_ROBOT, "PurchasingFailed")
            else
                xcyy.GameBridgeLua:sendEmail()
            end
        end,
        function()
        end,
        false,
        ViewZorder.ZORDER_POPUI
    )
    gLobalViewManager:removeLoadingAnima()
    if self.m_buyFailedCallFun then
        self.m_buyFailedCallFun()
    end
    self:checkRemovePayConfirmLayerMask()
end

function IAPManager:purchasingRetryBuyGoods()
    --弹出 提示界面 让玩家重新购买
    release_print("----csc 弹出购买成功 但是检测id失败的 板子")
    print("----csc 弹出购买成功 但是检测id失败的 板子")
    gLobalViewManager:showDialog(
        "Dialog/PurchaseFailed2.csb",
        function()
            printf("----csc 弹出界面")
        end,
        nil,
        false,
        ViewZorder.ZORDER_POPUI
    )
    gLobalViewManager:removeLoadingAnima()
end

function IAPManager:purchasingCheckNetworkRetry()
    --弹出 提示界面 让玩家重新购买
    release_print("----csc 弹出购买失败 检查当前网络 板子")
    print("----csc 弹出购买失败 检查当前网络 板子")
    gLobalViewManager:showDialog(
        "Dialog/PurchaseFailed3.csb",
        function()
        end,
        nil,
        false,
        ViewZorder.ZORDER_POPUI
    )
    gLobalViewManager:removeLoadingAnima()
end
------------------------------- 弹板总控代码

------------- 测试代码 按钮接口
function IAPManager:testSetButton(skip, buySuccess)
    self.m_testSkipServer = skip
    self.m_testBuySuccess = buySuccess

    gLobalDataManager:setBoolByField("iap_testBuySuccess", buySuccess)
    gLobalDataManager:setBoolByField("iap_testSkipServer", skip)
end

function IAPManager:getTestButton()
    return self.m_testSkipServer, self.m_testBuySuccess
end

function IAPManager:testSetReButton(reSkip, reBuySuccess)
    self.m_testReBuySuccess = reBuySuccess
    self.m_testReSkipServer = reSkip
    gLobalDataManager:setBoolByField("iap_testReBuySuccess", reBuySuccess)
    gLobalDataManager:setBoolByField("iap_testReSkipServer", reSkip)
end

function IAPManager:getTestReButton()
    return self.m_testReSkipServer, self.m_testReBuySuccess
end

function IAPManager:initSendFlag()
    local errorUserUdid = {}
    if next(errorUserUdid) == nil or errorUserUdid == nil then
        -- 如果不锁定某个用户的情况下,默认所有用户都发
        self.m_bCheckOk = true
        return
    end
    local currUserUdid = globalData.userRunData.userUdid
    for k, v in ipairs(errorUserUdid) do
        if v == currUserUdid then
            self.m_bCheckOk = true
            break
        end
    end
end

function IAPManager:sendBuglyLog(stepName)
    release_print("IAPManager:sendBuglyLog!")
    if self.m_bCheckOk == true then
        printf("----csc " .. stepName)
        gLobalSendDataManager:getLogIap():sendUiLogV2(LOG_ENUM_TYPE.PaymentAction_purchasing, stepName, self.m_iLogStep)
        self.m_iLogStep = self.m_iLogStep + 1
    end
end

function IAPManager:resetLogStep()
    self.m_iLogStep = 1
end
------------- 测试代码 按钮接口

return IAPManager
