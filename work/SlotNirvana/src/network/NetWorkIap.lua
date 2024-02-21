----
--
-- 处理所有的iap 购买行为接口
--

local NetWorkIap = class("NetWorkIap", require "network.NetWorkBase")
NetWorkIap.m_reSendCountList = nil
----购买-----
function NetWorkIap:sendActionPurchaseInfo(successCallFun, failedCallFun, testMode)
    -- csc 新版本的内购支持端口
    if util_isSupportVersion("1.3.3") or device.platform == "mac" then
        self:sendActionPurchaseV2(successCallFun, failedCallFun, testMode)
    else
        self:sendActionGooglePurchase(successCallFun, failedCallFun)
    end
end

-- 购买 V2 版本
function NetWorkIap:sendActionPurchaseV2(successCallFun, failedCallFun, testMode)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionData = nil
    local totleCoins = globalData.userRunData.coinNum
    local order = gLobalDataManager:getStringByField(IAP_ORDER_ID, "", true)
    local receipt = gLobalDataManager:getStringByField(IAP_RECEIPT, "", true)

    actionData = GameProto_pb.PurchaseRequestV2()

    -- 保留基础字段
    actionData.udid = globalData.userRunData.userUdid
    actionData.vipLevel = globalData.userRunData.vipLevel
    actionData.vipPoint = globalData.userRunData.vipPoints
    actionData.version = self:getVersionNum()

    -- 新增orders 字段 -- 重点*** 首先它是一个 repeated 对象
    local repOrderInfo = actionData.orders -- 要先把这个对象数组获取出来
    local repOrderInfoAdd = repOrderInfo:add() -- 它返回一个加入该列表中的对象！只需要给该对象中的字段进行赋值即可。  add方法等同于给repeatd数组 不停的add对象
    -- for i = 1 ,#dataTable do
    --     data = dataTable[i]
    --     local repOrderInfoAdd = repOrderInfo:add()
    --     func (data ,repOrderInfoAdd) -- 不停的去替换里面的字段
    -- end
    local channel = nil
    -- 区分不同平台添加值
    if device.platform == "ios" or device.platform == "mac" then
        channel = 1
    else
        if MARKETSEL == GOOGLE_MARKET then
            channel = 2
            repOrderInfoAdd.skuDetails.productId = globalData.iapRunData.p_lastBuyId
            repOrderInfoAdd.skuDetails.price = globalData.iapRunData.p_lastBuyPrice
            repOrderInfoAdd.skuDetails.price_currency_code = "USD"
            repOrderInfoAdd.buyIndent.RESPONSE_CODE = "1"
            repOrderInfoAdd.buyIndent.INAPP_PURCHASE_DATA = gLobalDataManager:getStringByField(IAP_RECEIPT, "", true)
            repOrderInfoAdd.buyIndent.INAPP_DATA_SIGNATURE = gLobalDataManager:getStringByField(IAP_SIGNATURE, "", true)
        elseif MARKETSEL == AMAZON_MARKET then
            channel = 3
            repOrderInfoAdd.amazonUserId = gLobalDataManager:getStringByField(IAP_SIGNATURE, "", true)
        end
    end
    repOrderInfoAdd.channel = channel
    repOrderInfoAdd.receipt = receipt
    repOrderInfoAdd.orderId = order
    repOrderInfoAdd.price = globalData.iapRunData.p_lastBuyPrice
    repOrderInfoAdd.buyType = globalData.iapRunData.p_lastBuyType
    repOrderInfoAdd.balanceCoins = 0
    repOrderInfoAdd.balanceGems = 0
    repOrderInfoAdd.balanceCoinsNew = get_integer_string(totleCoins)
    repOrderInfoAdd.items = ""
    --暂时为空
    repOrderInfoAdd.orderTime = gLobalDataManager:getStringByField("IAP_ORDER_TIME", globalData.userRunData.p_serverTime)
    repOrderInfoAdd.extra = cjson.encode(self:getExtra())

    local bodyData = actionData:SerializeToString()

    if testMode then
        return -- 测试模式不发送
    else
        print("daozheyibule---------------")
        self:sendPurchaseDataV2(order, bodyData, successCallFun, failedCallFun)
    end
end
--google购买
function NetWorkIap:sendActionGooglePurchase(successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionData = nil
    local totleCoins = globalData.userRunData.coinNum
    local order = gLobalDataManager:getStringByField(IAP_ORDER_ID, "", true)
    if device.platform == "ios" then
        actionData = GameProto_pb.ApplePurchaseRequest()
        actionData.receipt = gLobalDataManager:getStringByField(IAP_RECEIPT, "", true)
        actionData.price = globalData.iapRunData.p_lastBuyPrice
    elseif device.platform == "android" or device.platform == "mac" then
        if MARKETSEL == GOOGLE_MARKET then
            actionData = GameProto_pb.GooglePurchaseRequest()
            actionData.skuDetails.productId = globalData.iapRunData.p_lastBuyId
            actionData.skuDetails.price = globalData.iapRunData.p_lastBuyPrice
            actionData.skuDetails.price_currency_code = "USD"
            actionData.buyIndent.RESPONSE_CODE = "1"
            actionData.buyIndent.INAPP_PURCHASE_DATA = gLobalDataManager:getStringByField(IAP_RECEIPT, "", true)
            actionData.buyIndent.INAPP_DATA_SIGNATURE = gLobalDataManager:getStringByField(IAP_SIGNATURE, "", true)
        elseif MARKETSEL == AMAZON_MARKET then
            actionData = GameProto_pb.AmazonPurchaseRequest()
            actionData.orderId = order
            actionData.receipt = gLobalDataManager:getStringByField(IAP_RECEIPT, "", true)
            --签名字段充当amazonUserId
            actionData.amazonUserId = gLobalDataManager:getStringByField(IAP_SIGNATURE, "", true)
            actionData.price = globalData.iapRunData.p_lastBuyPrice
        end
    else
        actionData = GameProto_pb.GooglePurchaseRequest()
        actionData.skuDetails.productId = globalData.iapRunData.p_lastBuyId
        actionData.skuDetails.price = globalData.iapRunData.p_lastBuyPrice
        actionData.skuDetails.price_currency_code = "USD"
        actionData.buyIndent.RESPONSE_CODE = "1"
        actionData.buyIndent.INAPP_PURCHASE_DATA = gLobalDataManager:getStringByField(IAP_RECEIPT, "", true)
        actionData.buyIndent.INAPP_DATA_SIGNATURE = gLobalDataManager:getStringByField(IAP_SIGNATURE, "", true)
    end
    actionData.udid = globalData.userRunData.userUdid
    actionData.balanceCoins = 0
    actionData.balanceCoinsNew = get_integer_string(totleCoins)
    actionData.balanceGems = 0
    actionData.vipLevel = globalData.userRunData.vipLevel
    actionData.vipPoint = globalData.userRunData.vipPoints
    actionData.version = self:getVersionNum()
    actionData.orderId = order

    if CC_IS_TEST_BUY then
        order = math.random(0, 999999) + os.time() + math.random(0, 9)
        actionData.orderId = get_integer_string(order) --订单号
    end
    -- tostring(socket.gettime())
    actionData.buyType = globalData.iapRunData.p_lastBuyType

    if CC_IS_OUT_SDK_BUY then
        -- 为了绕过sdk测试商城购买才改成这样的  2018.12.3 by:li
        local purchaseTestData = {}
        purchaseTestData.buff = 123 -- 随意加的信息
        actionData.buyIndent.INAPP_PURCHASE_DATA = cjson.encode(purchaseTestData)
        actionData.buyIndent.INAPP_DATA_SIGNATURE = cjson.encode(purchaseTestData)
        local orderIdTestData = {}
        local testtime = os.time()
        local str = "osTime" .. testtime
        orderIdTestData[str] = os.time()
        actionData.orderId = cjson.encode(orderIdTestData)

        order = math.random(0, 999999) + os.time() + math.random(0, 9)
        actionData.orderId = get_integer_string(order) --订单号
    end

    local extraData = {}
    if device.platform == "android" then
        local androidID = gLobalSendDataManager:getDeviceId()
        local gpsID = globalPlatformManager:getGoogleAdvertisingID()
        extraData["android_id"] = androidID
        if gpsID ~= androidID then
            extraData["gps_adid"] = gpsID
        end
        if MARKETSEL == AMAZON_MARKET then
            extraData["fire_adid"] = globalPlatformManager:getAmazonAdID()
        end
    end
    extraData["coins"] = get_integer_string(globalData.iapRunData.p_lastBuyCoin)

    --更新支付传递给服务器的log
    if gLobalSendDataManager:getLogIap().updateServerExtraData then
        gLobalSendDataManager:getLogIap():updateServerExtraData(extraData)
    end
    if device.platform == "ios" then
        if extraData["key"] == nil then
            extraData["key"] = globalData.iapRunData.p_lastBuyId
        end
        extraData["currency"] = "USD"
        extraData["idfv"] = globalPlatformManager:getIDFV()
        extraData["idfa"] = globalAdjustManager:getAdjustIDFA()
        extraData["adid"] = globalAdjustManager:getAdjustID()
    end

    extraData = self:packIapEntryInfo(extraData)

    globalData.iapRunData.iapExtraData = extraData
    actionData.extra = cjson.encode(extraData)
    local bodyData = actionData:SerializeToString()

    --测试代码
    -- gLobalSaleManager:saveUserIapOrder(order,bodyData)
    -- gLobalViewManager:removeLoadingAnima()
    -- gLobalSaleManager:checkSendUserIapOrder()
    self:sendGooglePurchaseData(order, bodyData, successCallFun, failedCallFun)
end

--订单尝试发送次数超过三次 false
function NetWorkIap:isSendIapOrder(order)
    if not self.m_reSendCountList then
        self.m_reSendCountList = {}
    end
    if not self.m_reSendCountList[order] then
        self.m_reSendCountList[order] = 0
    end
    if self.m_reSendCountList[order] >= 3 then
        self.m_reSendCountList[order] = 0
        return false
    end
    return true
end
--增加订单发送次数
function NetWorkIap:addSendIapOrderCount(order)
    if not self.m_reSendCountList then
        self.m_reSendCountList = {}
    end
    if not self.m_reSendCountList[order] then
        self.m_reSendCountList[order] = 0
    end
    self.m_reSendCountList[order] = self.m_reSendCountList[order] + 1
end
--支付核心数据拆分重复尝试3次
function NetWorkIap:sendGooglePurchaseData(order, bodyData, successCallFun, failedCallFun)
    if self:isSendIapOrder(order) == false then
        if failedCallFun ~= nil then
            failedCallFun()
        end
        return
    end
    self:addSendIapOrderCount(order)
    gLobalSaleManager:saveUserIapOrder(order, bodyData)
    local httpSender = xcyy.HttpSender:createSender()

    local url = DATA_SEND_URL -- 拼接url 地址
    if device.platform == "ios" then
        url = url .. RUI_INFO.PAY_IOS_SUCCESS
    else
        if MARKETSEL == GOOGLE_MARKET then
            url = url .. RUI_INFO.PAY_GOOGLE_SUCCESS
        elseif MARKETSEL == AMAZON_MARKET then
            url = url .. RUI_INFO.PAY_AMAZON_SUCCESS
        end
    end

    local success_call_fun = function(responseTable)
        local resData = nil
        if device.platform == "ios" then
            resData = GameProto_pb.ApplePurchaseResponse()
        else
            resData = GameProto_pb.GooglePurchaseResponse()
        end
        local responseStr = self:parseResponseData(responseTable)
        resData:ParseFromString(responseStr)

        if resData.code == 1 then
            printInfo("xcyy :GOOGLE 购买  success")
            globalData.isPurchaseCallback = true

            if resData:HasField("user") then
                globalData.syncSimpleUserInfo(resData.user)
            end

            if resData:HasField("activity") == true then
                globalData.syncActivityConfig(resData.activity)
            end

            if resData:HasField("config") == true then
                globalData.syncUserConfig(resData.config)
            end

            if resData:HasField("pig") == true then
                globalData.syncPigCoin(resData.pig)
            end

            -- if resData:HasField("mission") == true then
            --     globalData.syncMission(resData.mission)
            -- end
            if resData:HasField("dailyTask") == true then
                globalData.syncMission(resData.dailyTask)
            end
            if resData:HasField("luckySpin") == true then
                globalData.syncLuckySpin(resData.luckySpin)
            end

            -- if resData:HasField("luckySpinV2") == true then
            --     globalData.luckySpinV2:parseData(resData.luckySpinV2)
            -- end

            if resData:HasField("luckyStampV2") == true then
                globalData.syncLuckyStampData(resData.luckyStampV2, false, true)
            end
            -- 掉落卡片 --
            if resData.cardDrop ~= nil and #resData.cardDrop > 0 then
                CardSysManager:doDropCardsData(resData.cardDrop)
            end

            --广告强制刷新不需要检测是否存在
            globalData.syncAdConfig(resData.adConfig)

            if resData:HasField("fbCoins") == true then
                globalData.userRunData:setFbBindReward(resData.fbCoins)
            end

            if resData:HasField("drops") == true then
                globalData.parseDropsConfig(resData.drops)
            end

            if resData.buff ~= nil and #resData.buff > 0 then
                globalData.iapRunData:syncBuybuffItems(resData.buff)
            end
            globalData.isPurchaseCallback = false
            if successCallFun ~= nil then
                local result = nil
                if resResultsData:HasField("result") then
                    result = resResultsData.result
                end
                successCallFun(result)
            end
            gLobalSaleManager:deleteUserIapOrder(order)
            gLobalSendDataManager:getLogIap():sendOrderLog("success")
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PURCHASE_SUCCESS, {result = resResultsData.result})
        else
            if resData.code == 9 then
                gLobalSaleManager:deleteUserIapOrder(order)
            end
            release_print("xcyy : GOOGLE 购买   failed")
            gLobalSendDataManager:getLogIap():sendOrderLog("failed")
            if failedCallFun ~= nil then
                failedCallFun()
            end
        end
        httpSender:release()
    end
    local faild_call_fun = function(errorCode, errorData)
        -- 根据errorCode 做处理
        release_print("dingdongchen " .. tostring(errorCode) .. "   " .. tostring(errorData))
        printInfo("dingdongchen " .. tostring(errorCode) .. "   " .. tostring(errorData))
        httpSender:release()
        printInfo("xcyy : googele 购买 failed")
        gLobalSendDataManager:getLogIap():sendOrderLog("failed")
        if errorCode and errorCode == -1 then
            self:sendGooglePurchaseData(order, bodyData, successCallFun, failedCallFun)
        elseif errorCode and errorCode == 9 then
            gLobalSaleManager:deleteUserIapOrder(order)
        elseif failedCallFun ~= nil then
            failedCallFun()
        end
    end

    local offset = self:getOffsetValue()
    local token = globalData.userRunData.loginUserData.token
    local serverTime = globalData.userRunData.p_serverTime

    httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
end

--新的内购接口和返回数据读取 v2
function NetWorkIap:sendPurchaseDataV2(order, bodyData, successCallFun, failedCallFun)
    if self:isSendIapOrder(order) == false then
        if failedCallFun ~= nil then
            failedCallFun()
        end
        return
    end
    self:addSendIapOrderCount(order)
    gLobalSaleManager:saveUserIapOrder(order, bodyData)
    local httpSender = xcyy.HttpSender:createSender()

    local url = DATA_SEND_URL .. RUI_INFO.PAY_COMMON_SUCCESS_V2 -- 拼接url 地址
    -- if device.platform == "ios" or device.platform == "mac" then
    --     url = url .. RUI_INFO.PAY_IOS_SUCCESS_V2
    -- else
    --     if MARKETSEL == GOOGLE_MARKET then
    --         url = url .. RUI_INFO.PAY_GOOGLE_SUCCESS_V2
    --     elseif MARKETSEL == AMAZON_MARKET then
    --         url = url .. RUI_INFO.PAY_AMAZON_SUCCESS_V2
    --     end
    -- end

    local success_call_fun = function(responseTable)
        local resData = nil
        local resResults = {}
        -- 统一接口
        resData = GameProto_pb.PurchaseResponseV2()

        local responseStr = self:parseResponseData(responseTable)
        resData:ParseFromString(responseStr)

        -- 新的 protobuf 结构
        if resData.results then
            resResults = resData.results
        end

        for i = 1, #resResults do
            local resResultsData = resResults[i]
            if resResultsData.code == 1 then
                release_print("----csc sendPurchaseDataV2 购买成功")
                print("----csc sendPurchaseDataV2 购买成功")
                globalData.isPurchaseCallback = true

                -- user 跟 result 同级
                if resData:HasField("user") then
                    globalData.syncSimpleUserInfo(resData.user)
                end
                -- result数据
                self:parsePurchaseResultData(resResultsData)

                gLobalSendDataManager:getLogIap():createGoodsInfo(order, "success")

                globalData.isPurchaseCallback = false
                if successCallFun ~= nil then
                    local result = nil
                    if resResultsData:HasField("result") then
                        result = resResultsData.result
                    end
                    successCallFun(result)
                end
                gLobalSaleManager:deleteUserIapOrder(order)
                gLobalSendDataManager:getLogIap():sendOrderLog("success")
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PURCHASE_SUCCESS, {result = resResultsData.result})
            else
                local bHas = false
                if resResultsData.code == 12 then --订单验证失败
                elseif resResultsData.code == 13 then --订单已经存在
                    bHas = true
                end
                if resResultsData.code == 9 then
                    gLobalSaleManager:deleteUserIapOrder(order)
                end
                release_print("----csc sendPurchaseDataV2 购买 failed ")
                print("----csc sendPurchaseDataV2 购买 failed")
                gLobalSendDataManager:getLogIap():sendOrderLog("failed")
                if failedCallFun ~= nil then
                    failedCallFun(bHas)
                end
            end
        end
        httpSender:release()
    end
    local faild_call_fun = function(errorCode, errorData)
        -- 根据errorCode 做处理
        release_print("dingdongchen " .. tostring(errorCode) .. "   " .. tostring(errorData))
        printInfo("dingdongchen " .. tostring(errorCode) .. "   " .. tostring(errorData))
        httpSender:release()
        release_print("----csc sendPurchaseDataV2 购买 failed ")
        print("----csc sendPurchaseDataV2 购买 failed")
        gLobalSendDataManager:getLogIap():sendOrderLog("failed")
        if errorCode and errorCode == -1 then
            self:sendPurchaseDataV2(order, bodyData, successCallFun, failedCallFun)
        elseif errorCode and errorCode == 9 then
            gLobalSaleManager:deleteUserIapOrder(order)
        elseif failedCallFun ~= nil then
            failedCallFun()
        end
    end

    local offset = self:getOffsetValue()
    local token = globalData.userRunData.loginUserData.token
    local serverTime = globalData.userRunData.p_serverTime

    httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
end

function NetWorkIap:getExtra()
    local extraData = {}
    if device.platform == "android" then
        local androidID = gLobalSendDataManager:getDeviceId()
        local gpsID = globalPlatformManager:getGoogleAdvertisingID()
        extraData["android_id"] = androidID
        if gpsID ~= androidID then
            extraData["gps_adid"] = gpsID
        end
        if MARKETSEL == AMAZON_MARKET then
            extraData["fire_adid"] = globalPlatformManager:getAmazonAdID()
        end
    end
    extraData["coins"] = get_integer_string(globalData.iapRunData.p_lastBuyCoin)

    --更新支付传递给服务器的log
    if gLobalSendDataManager:getLogIap().updateServerExtraData then
        gLobalSendDataManager:getLogIap():updateServerExtraData(extraData)
    end

    if device.platform == "ios" or device.platform == "mac" then
        if extraData["key"] == nil then
            extraData["key"] = globalData.iapRunData.p_lastBuyId
        end
        extraData["currency"] = "USD"
        extraData["idfv"] = globalPlatformManager:getIDFV()
        extraData["idfa"] = globalAdjustManager:getAdjustIDFA()
        extraData["adid"] = globalAdjustManager:getAdjustID()
    end

    -- csc 2021-07-06 10:56:35 添加新打点数据
    extraData["buDan"] = "false"
    if gLobalSendDataManager:getLogIap():getIsBuDan() then
        extraData["buDan"] = "true"
    end

    extraData["paySessionId"] = gLobalSendDataManager:getLogIap().m_paySessionId
    if gLobalSendDataManager:getLogIap():getEntryData() then
        extraData["purchaseName"] = gLobalSendDataManager:getLogIap():getEntryData().pn
        extraData["purchaseStatus"] = gLobalSendDataManager:getLogIap():getEntryData().ps
    end
    -- if globalData.iapRunData.p_flowerType then
    --     extraData["flowerType"] = globalData.iapRunData.p_flowerType
    -- end
    extraData["bet"] = gLobalSendDataManager:getLogIap().m_spinTotalBet
    extraData["userCoins"] = gLobalSendDataManager:getLogIap().m_spinUserCoins
    extraData = self:packIapEntryInfo(extraData)
    globalData.iapRunData.iapExtraData = extraData
    gLobalSendDataManager:getLogIap():clearEntryData()
    gLobalSendDataManager:getLogIap():setIsBuDan(false)

    return extraData
end

function NetWorkIap:packIapEntryInfo(extraData)
    extraData = extraData or {}
    if gLobalSendDataManager:getLogIap().getEntryInfo then
        local _entryInfo = gLobalSendDataManager:getLogIap():getEntryInfo()
        extraData["entryName"] = _entryInfo.entryName
        extraData["entryOpen"] = _entryInfo.entryOpen
        extraData["entryOrder"] = _entryInfo.entryOrder
        extraData["entryStatus"] = _entryInfo.entryStatus
        extraData["entryTheme"] = _entryInfo.entryTheme
        extraData["entryType"] = _entryInfo.entryType
    end
    if gLobalSendDataManager:getLogIap().getQuestInfo then
        local questInfo = gLobalSendDataManager:getLogIap():getQuestInfo()
        extraData["questInfo"] = questInfo
    end
    return extraData
end

function NetWorkIap:parsePurchaseResultData(resResultsData)
    if resResultsData:HasField("activity") then
        globalData.syncActivityConfig(resResultsData.activity)
    end

    if resResultsData:HasField("config") then
        globalData.syncUserConfig(resResultsData.config)
    end

    if resResultsData:HasField("pig") then
        globalData.syncPigCoin(resResultsData.pig)
    end

    if resResultsData:HasField("dailyTask") then
        globalData.syncMission(resResultsData.dailyTask)
    end
    -- if resResultsData.luckySpin then
    if resResultsData:HasField("luckySpin") then
        globalData.syncLuckySpin(resResultsData.luckySpin)
    end

    -- if resResultsData:HasField("luckySpinV2") then
    --     globalData.luckySpinV2:parseData(resResultsData.luckySpinV2)
    -- end

    if resResultsData:HasField("luckyStampV2") then
        globalData.syncLuckyStampData(resResultsData.luckyStampV2, false, true)
    end
    -- 集卡排行榜
    if resResultsData.cardRank ~= nil and resResultsData:HasField("cardRank") == true then
        G_GetMgr(G_REF.CardRank):parseData(resResultsData.cardRank)
    end
    -- 掉落卡片 --
    if resResultsData.cardDrop ~= nil and #resResultsData.cardDrop > 0 then
        CardSysManager:doDropCardsData(resResultsData.cardDrop)
    end

    --广告强制刷新不需要检测是否存在
    globalData.syncAdConfig(resResultsData.adConfig)

    if resResultsData:HasField("fbCoins") then
        globalData.userRunData:setFbBindReward(resResultsData.fbCoins)
    end

    if resResultsData:HasField("channel") then
        release_print("----csc 当前 渠道id =  " .. resResultsData.channel)
    end

    -- MiniGame
    if resResultsData:HasField("miniGame") then
        gLobalMiniGameManager:parseData(resResultsData.miniGame)
    end

    if resResultsData:HasField("result") then
        if resResultsData.result ~= nil and resResultsData.result ~= "" then
            local resultData = cjson.decode(resResultsData.result)
            if resultData then
                if resultData.returnPassUnlocked and resultData.returnPassUnlocked == true then
                    local data = G_GetMgr(G_REF.Return):getRunningData()
                    if data and data:isPassUnlocked() == false then
                        data:setPassUnlocked(true)
                    end
                end
            end
        end
    end   

    if resResultsData:HasField("extend") then
        local extend = util_cjsonDecode(resResultsData.extend)
        if extend.fourBirthdayDraw then
            G_GetMgr(ACTIVITY_REF.dayDraw4B):parseWheelData(extend.fourBirthdayDraw)
        end
    end

    if resResultsData.buff ~= nil and #resResultsData.buff > 0 then
        globalData.iapRunData:syncBuybuffItems(resResultsData.buff)
    end    
end

return NetWorkIap
