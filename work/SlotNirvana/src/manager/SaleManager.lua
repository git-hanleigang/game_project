--[[
    @desc: 游戏内的销售管理类，
    time:2019-04-15 16:23:33
]]
-- FIX IOS 139
local IAPExtraData = util_require("data.baseDatas.IAPExtraData")
local SaleManager = class("SaleManager")
SaleManager.m_instance = nil

SaleManager.m_buySuccessCallFun = nil
SaleManager.m_buyFailedCallFun = nil

SaleManager.m_levelUpCount = nil
SaleManager.m_preVipLevel = nil
SaleManager.m_preVipPoints = nil

SaleManager.m_orderList = nil --支付订单列表
SaleManager.m_sendOrderList = nil
--已发送支付订单列表

function SaleManager:getInstance()
    if SaleManager.m_instance == nil then
        SaleManager.m_instance = SaleManager.new()
    end
    return SaleManager.m_instance
end
-- 构造函数
function SaleManager:ctor()
    self.m_buySuccessCallFun = nil
    self.m_buyFailedCallFun = nil
    self.m_levelUpCount = 0
    self:registerObservers()
end

function SaleManager:startPurchase(buyType, iapId, buyPrice, totleCoin, discounts, successFun, failedFun)
    gLobalViewManager:addLoadingAnima()
    globalData.skipForeGround = true
    
    self.m_buySuccessCallFun = successFun
    self.m_buyFailedCallFun = failedFun

    gLobalIAPManager:resetLogStep()
    gLobalIAPManager:sendBuglyLog("SaleManager||purchaseGoods||start")
    if util_isSupportVersion("1.3.3") or device.platform == "mac" then
        self.m_skip = false
        gLobalIAPManager:setCallbackFunc(successFun, failedFun)
        -- 先检索一下当前购买项是否没有被消耗掉
        if gLobalIAPManager:checkHasUnConsumePurchase(iapId, buyType) then
            --....
        else
            if self.m_skip == false then
                --订单信息
                local extraData = IAPExtraData:create()
                extraData:createIAPExtraData(buyType, iapId, buyPrice, totleCoin, discounts, globalData.iapRunData.p_activityId, globalData.iapRunData.p_contentId)
                local data = {
                    vippoint = self.m_buyVipPoints,
                    buff = self.m_extraBuff
                }
                extraData:setExtraData(data)
                gLobalIAPManager:createIapConfig(buyType, iapId, extraData)
            end
            self.m_buyVipPoints = nil
            self.m_extraBuff = nil
            -- 调用SDK 购买
            gLobalIAPManager:buyGoods(iapId, buyType)
        end
    else
        gLobalIAPManager:sendBuglyLog("SaleManager||old purchase||")
        --补单信息
        local IapInfoData = {}
        IapInfoData.p_lastBuyId = iapId
        IapInfoData.p_lastBuyCoin = totleCoin
        IapInfoData.p_lastBuyType = buyType
        IapInfoData.p_lastBuyPrice = buyPrice
        IapInfoData.p_discounts = discounts
        IapInfoData.p_activityId = globalData.iapRunData.p_activityId
        IapInfoData.p_contentId = globalData.iapRunData.p_contentId
        IapInfoData.p_flowerType = globalData.iapRunData.p_flowerType
        self:saveIapInfoData(IapInfoData)

        --调用购买sdk
        if CC_IS_TEST_BUY then
            gLobalSendDataManager:getLogIap():sendUiLog(LOG_ENUM_TYPE.PaymentAction_skip, LOG_IAP_ENMU.operationStatus.testPay)
            gLobalNoticManager:postNotification(GlobalEvent.IAP_BuyResult, {buyType, true})
        else
            gLobalSendDataManager:getLogIap():sendUiLog(LOG_ENUM_TYPE.PaymentAction_skip)
            xcyy.GameBridgeLua:onBuyClick(iapId, buyType)
        end
    end

    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_buy)

        -- 七日新用户打点
        if globalData.userRunData:isNewUser(7) then
            local _count = gLobalDataManager:getNumberByField("SevPurchaseLevelClick", 0)
            _count = _count + 1
            if _count >= 4 and globalData.userRunData.levelNum > 40 then
                local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SevPurchaseLevelClick)
                actionData.data.params = json.encode({})
                gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
            end
            gLobalDataManager:setNumberByField("SevPurchaseLevelClick", _count)
        end
    end    
end

-- --
-- @parma storeType购买类型 iapId  totleCoin(例如小猪银行需要传入)
--[[
    @desc: 购买信息
    time:2019-04-15 16:44:18
	--@buyType:     购买类型
	--@iapId:       购买项id ， 后台注册的key值
	--@buyPrice:    购买价格
	--@totleCoin:   购买的总金币数
	--@buyRase:
	--@successFun:
	--@failedFun:
    @return:
]]
function SaleManager:purchaseGoods(buyType, iapId, buyPrice, totleCoin, discounts, successFun, failedFun, _type)
    --1. 点击购买 不论是否购买成功
    globalAdjustManager:sendAdjustEventId("8w841c")

    self:resetVipInfo()
    -- 断网检查,网络未连接则直接失败
    if gLobalSendDataManager:checkShowNetworkDialog() == true then
        if failedFun then
            failedFun()
        end
        return false
    end

    -- 购买索引、 iapid不能为nil
    if iapId == nil then
        gLobalViewManager:removeLoadingAnima()
        return false
    end

    -- 保存last buy 信息
    globalData.iapRunData.p_lastBuyId = iapId
    globalData.iapRunData.p_lastBuyCoin = totleCoin
    globalData.iapRunData.p_lastBuyType = buyType
    globalData.iapRunData.p_lastBuyPrice = buyPrice
    globalData.iapRunData.p_discounts = discounts

    -- 使用代币
    local buckMgr = G_GetMgr(G_REF.ShopBuck)
    if buckMgr and buckMgr:canBuyByBuck(buyType, buyPrice) then
        local view = buckMgr:showConfirmLayer(buyPrice, buyPrice,
            function()
                local logIap = gLobalSendDataManager:getLogIap()
                -- 点击yes

                -- 服务器需要的额外打点
                local extraData = self:packServerExtraData()

                -- 创建代币的订单Id，此订单不用记录到本地数据中，因为使用代币付费不存在补单
                local orderId = buckMgr:createBuckOrderId()
                gLobalSendDataManager:getLogIap():createOrder(orderId)
                

                buckMgr:useBuckToBuy(orderId, buyType, extraData, buyPrice, successFun, failedFun)
                logIap:sendUiLog(LOG_ENUM_TYPE.PaymentAction_buckConfirm_buck, LOG_ENUM_TYPE.PaymentAction_buck_success)
                -- globalData.iapRunData.p_activityId = nil
                -- globalData.iapRunData.p_contentId = nil
            end,
            function()
                -- 点击no
                gLobalSendDataManager:getLogIap():sendUiLog(LOG_ENUM_TYPE.PaymentAction_buckConfirm_cancel, LOG_ENUM_TYPE.PaymentAction_buck_cancel)  
                self:startPurchase(buyType, iapId, buyPrice, totleCoin, discounts, successFun, failedFun, _type)  
            end,
            function()
                -- 点击x
                gLobalSendDataManager:getLogIap():sendUiLog(LOG_ENUM_TYPE.PaymentAction_buckConfirm_close, LOG_ENUM_TYPE.PaymentAction_buck_cancel)  
                if failedFun then
                    failedFun()
                end
                globalData.iapRunData.p_activityId = nil
                globalData.iapRunData.p_contentId = nil
            end
        )
        if view then
            gLobalSendDataManager:getLogIap():setPurchaseBuckInfo({tokenStatus = "ytoken"})
        else
            gLobalSendDataManager:getLogIap():setPurchaseBuckInfo({tokenStatus = "ntoken"})
            self:startPurchase(buyType, iapId, buyPrice, totleCoin, discounts, successFun, failedFun, _type)
        end   
    else
        gLobalSendDataManager:getLogIap():setPurchaseBuckInfo({tokenStatus = "ntoken"})
        self:startPurchase(buyType, iapId, buyPrice, totleCoin, discounts, successFun, failedFun, _type)
    end
    
    return true
end

--促销活动 - 购买
function SaleManager:purchaseActivityGoods(activityId, contentId, buyType, iapId, buyPrice, totleCoin, discounts, successFun, failedFun)
    globalData.iapRunData.p_activityId = activityId
    globalData.iapRunData.p_contentId = contentId

    local success_call_fun = function()
        if successFun ~= nil then
            successFun()
        end
    end

    -- 有选择buff的促销需要再这里把buff存起来
    if util_isSupportVersion("1.3.3") or device.platform == "mac" then
        if buyType == BUY_TYPE.DINNERLAND_SALE then
            -- 餐厅促销
            local dinnerLandData = G_GetActivityDataByRef(ACTIVITY_REF.DinnerLand)
            if dinnerLandData then
                local buff = dinnerLandData:getBuyBuff()
                self.m_extraBuff = buff
            end
        end
    end
    local buyData = G_GetActivityDataById(activityId)
    if buyData then
        --添加道具log
        local itemList = gLobalItemManager:checkAddLocalItemList(buyData, buyData.p_items)
        gLobalSendDataManager:getLogIap():setItemList(itemList)
    end
    local ret = self:purchaseGoods(buyType, iapId, buyPrice, totleCoin, discounts, success_call_fun, failedFun)
    if not ret then
        globalData.iapRunData.p_activityId = nil
        globalData.iapRunData.p_contentId = nil
    end
end

-- csc 新增一个传入vip点数的接口
function SaleManager:setBuyVippoint(vippoint)
    self.m_buyVipPoints = vippoint
end

function SaleManager:setSkipCreateNewIap(state)
    self.m_skip = state
end

function SaleManager:getLevelUpNum()
    return self.m_levelUpCount
end

--购买前保留vip升级信息
function SaleManager:resetVipInfo()
    self.m_levelUpCount = 0
    self.m_preVipLevel = globalData.userRunData.vipLevel
    self.m_preVipPoints = globalData.userRunData.vipPoints
end

--购买后发送日志
function SaleManager:sendPurchaseLog(buyType)
    -- adjust 打点
    if globalAdjustManager.sendAdjustEventId and globalData.iapRunData.p_lastBuyPrice then
        if tonumber(globalData.iapRunData.p_lastBuyPrice) >= 4.99 then
            globalAdjustManager:sendAdjustEventId("enir0q")
        --2. 当次购买金额大于等于4.99
        end
        if tonumber(globalData.iapRunData.p_lastBuyPrice) >= 2.99 then
            globalAdjustManager:sendAdjustEventId("p8he9d")
        --2. 当次购买金额大于等于2.99
        end
        if tonumber(globalData.iapRunData.p_lastBuyPrice) >= 1.99 then
            globalAdjustManager:sendAdjustEventId("z7gscb")
        --2. 当次购买金额大于等于1.99
        end
    end

    if globalFireBaseManager.sendFireBaseLogDirect then
        if buyType == BUY_TYPE.STORE_TYPE then -- TODO:MAQUN 钻石商城的firebase打点暂时未加
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.purchase_shop)
        elseif buyType == BUY_TYPE.PIGGYBANK_TYPE then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.purchase_pig)
        elseif buyType == BUY_TYPE.CASHBONUS_TYPE then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.purchase_wheel)
        elseif buyType == BUY_TYPE.SPECIALSALE then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.purchase_NomalSale)
        elseif buyType == BUY_TYPE.NOCOINSSPECIALSALE then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.purchase_NoCoinSale)
        elseif buyType == BUY_TYPE.THEME_TYPE then
        elseif buyType == BUY_TYPE.CHOICE_TYPE or buyType == BUY_TYPE.CHOICE_TYPE_NOVICE then
        elseif buyType == BUY_TYPE.SEVEN_DAY or BUY_TYPE.QUEST_SALE then
        elseif buyType == BUY_TYPE.SEVEN_DAY_NO_COIN then
        elseif buyType == BUY_TYPE.BOOST_TYPE then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.purchase_boost)
        elseif buyType == BUY_TYPE.LUCKY_SPIN_TYPE then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.purchase_LuckySpin)
        elseif buyType == BUY_TYPE.KEEPRECHARGE or buyType == BUY_TYPE.NOVICE_KEEPRECHARGE then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.purchase_ComboSale)
        elseif buyType == BUY_TYPE.LEVEL_DASH_TYPE then
        elseif buyType == BUY_TYPE.ATTEMPT then
        end
    end
end

--购买后更新vip信息
function SaleManager:updataVipInfo()
    self.m_levelUpCount = globalData.userRunData.vipLevel - self.m_preVipLevel
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
end

function SaleManager:purchaseFailedResetData()
    --重置为购买前的数据
    self:resetVipInfo()
end

function SaleManager:purchaseFailed()
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
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OPEN_ROBOT, "PurchaseSale")
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
end

function SaleManager:getSaleCoins(baseCoins)
    local vipData = G_GetMgr(G_REF.Vip):getData()
    local rate = vipData and vipData:getVipCoinBonusPer(globalData.userRunData.vipLevel) or 1
    local coins = baseCoins * rate
    return coins
end

--注册事件
function SaleManager:registerObservers()
    if util_isSupportVersion("1.3.3") then
        -- 新版本的玩家不会走这个回调
        return
    end

    ---购买回调
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local buyType = params[1]
            local isSuccess = params[2]
            local strMsg = params[3]

            gLobalSendDataManager:getLogIap():setSdkCode(strMsg)
            local order = gLobalDataManager:getStringByField(IAP_ORDER_ID, "", true)
            if device.platform == "android" then
                if MARKETSEL == AMAZON_MARKET then
                    order = "A:" .. tostring(globalData.userRunData.uid) .. ":" .. tostring(os.time()) .. tostring(math.random(100, 999))
                    gLobalDataManager:setStringByField(IAP_ORDER_ID, order)
                end
            end
            if CC_IS_TEST_BUY then
                order = math.random(0, 999999) + os.time() + math.random(0, 9)
                order = get_integer_string(order) --订单号
            end
            gLobalSendDataManager:getLogIap():createOrder(order)

            ---发送服务器同步消息
            if globalData.m_isLogin then
                if isSuccess == true then
                    local IapInfoData = {}
                    self:saveIapInfoData(IapInfoData)
                    --注册24小时内产生首次付费
                    globalAdjustManager:checkTriggerNPAdjustLog(AdjustNPEventType.spend_firstly)

                    gLobalSendDataManager:getNetWorkIap():sendActionPurchaseInfo(
                        function()
                            --发送消息
                            gLobalViewManager:removeLoadingAnima()

                            self:updataVipInfo()

                            self:sendPurchaseLog(buyType)

                            if self.m_buySuccessCallFun then
                                self.m_buySuccessCallFun()
                            end
                            gLobalNoticManager:postNotification("hide_vedio_icon")
                            gLobalNoticManager:postNotification("IAP_Success")

                            self:clearLocalIapInfo()
                        end,
                        function()
                            self:purchaseFailed()
                            self:purchaseFailedResetData()
                            self:clearLocalIapInfo()
                        end
                    )
                    gLobalSendDataManager:getLogIap():sendUiLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_ENUM_TYPE.PaymentAction_success)
                else
                    globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.purchase_failed)
                    self:purchaseFailed()
                    if strMsg and string.find(strMsg, "-1005") ~= nil then
                        gLobalSendDataManager:getLogIap():sendUiLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_IAP_ENMU.operationStatus.sdkEsc)
                    else
                        gLobalSendDataManager:getLogIap():sendUiLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_ENUM_TYPE.PaymentAction_failed)
                    end
                end
            end
        end,
        GlobalEvent.IAP_BuyResult
    )
end

--清理在sdk存储的支付票据信息
function SaleManager:clearLocalIapInfo()
    gLobalDataManager:setStringByField(IAP_RECEIPT, "")
    gLobalDataManager:setStringByField(IAP_SIGNATURE, "")
    gLobalDataManager:setStringByField(IAP_ORDER_ID, "")
end

function SaleManager:buySuccessCallFun()
    if self.m_buySuccessCallFun then
        self.m_buySuccessCallFun()
    end
end

------------------------------------------------------SDK支付成功消耗商品失败补单 START
--保存支付请求信息
function SaleManager:saveIapInfoData(iapInfoData)
    if device.platform == "mac" then
        return
    end
    local jsonData = cjson.encode(iapInfoData)
    local path = device.writablePath .. globalData.userRunData.userUdid .. "IAP_INFO_DATA"
    local file = io.open(path, "wb+")
    file:write(jsonData)
    file:flush()
    file:close()
end

--读取支付请求信息
function SaleManager:readIapInfoData()
    local path = device.writablePath .. globalData.userRunData.userUdid .. "IAP_INFO_DATA"
    return util_checkJsonDecode(path)
end

--读取已完成订单开始补单操作
function SaleManager:checkSendIapInfoData(func)
    --订单信息
    local isSendData = false
    local IapPurchaseInfo = gLobalDataManager:getStringByField(IAP_RECEIPT, "", true)
    release_print("checkSendIapInfoData IapPurchaseInfo= " .. IapPurchaseInfo)
    if IapPurchaseInfo ~= "" then
        if device.platform == "android" then
            if MARKETSEL == GOOGLE_MARKET then
                local purchaseInfoData = cjson.decode(IapPurchaseInfo)
                if purchaseInfoData and purchaseInfoData.productId then
                    release_print("checkSendIapInfoData productId= " .. purchaseInfoData.productId)
                    local iapInfoData = self:readIapInfoData()
                    if iapInfoData and iapInfoData.p_lastBuyId and iapInfoData.p_lastBuyId == purchaseInfoData.productId then
                        isSendData = true
                        self:sendIapInfoData(iapInfoData, func)
                    end
                end
            elseif MARKETSEL == AMAZON_MARKET then
                local iapInfoData = self:readIapInfoData()
                if iapInfoData and iapInfoData.p_lastBuyId then
                    isSendData = true
                    self:sendIapInfoData(iapInfoData, func)
                end
            end
        elseif device.platform == "ios" then
            local iapInfoData = self:readIapInfoData()
            if iapInfoData and iapInfoData.p_lastBuyId then
                isSendData = true
                self:sendIapInfoData(iapInfoData, func)
            end
        end
    end
    --未找到支付订单
    if not isSendData then
        if func then
            func()
        end
    end
end
--补单成功重新发送支付请求
function SaleManager:sendIapInfoData(iapInfoData, func)
    release_print("sendIapInfoData")
    globalData.iapRunData.p_lastBuyId = iapInfoData.p_lastBuyId
    globalData.iapRunData.p_lastBuyCoin = iapInfoData.p_lastBuyCoin
    globalData.iapRunData.p_lastBuyType = iapInfoData.p_lastBuyType
    globalData.iapRunData.p_lastBuyPrice = iapInfoData.p_lastBuyPrice
    globalData.iapRunData.p_discounts = iapInfoData.p_discounts
    globalData.iapRunData.p_activityId = iapInfoData.p_activityId
    globalData.iapRunData.p_contentId = iapInfoData.p_contentId
    globalData.iapRunData.p_flowerType = iapInfoData.p_flowerType
    globalData.iapRunData.iapExtraData = nil

    --商店数据赋值
    if globalData.iapRunData.p_lastBuyType == BUY_TYPE.STORE_TYPE then
        local shopData = globalData.shopRunData:getShopItemDatas()
        for i = 1, #shopData do
            if shopData[i].p_key == globalData.iapRunData.p_lastBuyId then
                globalData.iapRunData.p_showData = shopData[i]
                break
            end
        end
    end
    --boostme数据赋值
    if globalData.iapRunData.p_lastBuyType == BUY_TYPE.BOOST_TYPE then
        local boostData = globalData.shopRunData.p_shopData.p_storeBoost
        for i = 1, 2 do
            if globalData.iapRunData.p_lastBuyId == boostData.p_cashBackBoosts[i].p_key then
                globalData.iapRunData.p_showData = boostData.p_cashBackBoosts[i]
                break
            end
            if globalData.iapRunData.p_lastBuyId == boostData.p_levelBurstBoosts[i].p_key then
                globalData.iapRunData.p_showData = boostData.p_cashBackBoosts[i]
                break
            end
            if globalData.iapRunData.p_lastBuyId == boostData.p_bundleBoosts[i].p_key then
                globalData.iapRunData.p_showData = boostData.p_cashBackBoosts[i]
                break
            end
        end
    end
    gLobalSendDataManager:getLogIap():setSdkCode("resetSendIapInfo")
    local order = gLobalDataManager:getStringByField(IAP_ORDER_ID, "", true)
    if MARKETSEL == AMAZON_MARKET then
        order = "A:" .. tostring(globalData.userRunData.uid) .. ":" .. tostring(os.time()) .. tostring(math.random(100, 999))
        gLobalDataManager:setStringByField(IAP_ORDER_ID, order)
    end
    gLobalSendDataManager:getLogIap():createOrder(order)
    self:resetVipInfo()

    if globalData.iapRunData.p_lastBuyType == BUY_TYPE.NOCOINSSPECIALSALE then
        gLobalViewManager:addLoadingAnima(true)
        self:requestNoCoinsSale(
            function(isOk)
                gLobalViewManager:removeLoadingAnima()
                if isOk then
                    ---发送服务器同步消息
                    gLobalSendDataManager:getNetWorkIap():sendActionPurchaseInfo(
                        function()
                            local buyData = {reBuyCoins = globalData.iapRunData.p_lastBuyCoin, reBuyType = globalData.iapRunData.p_lastBuyType, reBuyData = nil}
                            self:setBuyDataInfo(buyData, globalData.iapRunData.iapExtraData)
                            local view = util_createView("GameModule.Shop.BuyTip")
                            view:initBuyTip(buyData.reBuyType, buyData.reBuyData, tonumber(buyData.reBuyCoins), 0)
                            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                            view:setOverFunc(
                                function()
                                    if func then
                                        func()
                                    end
                                end
                            )
                            gLobalNoticManager:postNotification("hide_vedio_icon")
                        end,
                        function()
                            if func then
                                func()
                            end
                        end
                    )
                    gLobalSendDataManager:getLogIap():sendUiLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_ENUM_TYPE.PaymentAction_success)
                else
                    if func then
                        func()
                    end
                end
            end
        )
        return
    end

    ---发送服务器同步消息
    gLobalSendDataManager:getNetWorkIap():sendActionPurchaseInfo(
        function()
            if globalData.iapRunData.p_lastBuyType == BUY_TYPE.LUCKY_SPIN_TYPE then
                globalData.iapLuckySpinFunc = func
                local index = gLobalDataManager:getNumberByField("lastBuyLuckySpinID", 1)
                local shopDatas = globalData.shopRunData:getShopItemDatas()
                local data = {}
                data.buyShopData = shopDatas[index]
                data.reconnect = true
                data.buyIndex = index
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum - data.buyShopData.p_coins)
                G_GetMgr(G_REF.LuckySpin):showMainLayer(data)
                gLobalNoticManager:postNotification("hide_vedio_icon")
                return
            end

            local buyData = {reBuyCoins = globalData.iapRunData.p_lastBuyCoin, reBuyType = globalData.iapRunData.p_lastBuyType, reBuyData = nil}
            self:setBuyDataInfo(buyData, globalData.iapRunData.iapExtraData)

            if buyData and buyData.reBuyData then
                if
                    globalData.iapRunData.p_lastBuyType == BUY_TYPE.PIGGYBANK_TYPE or globalData.iapRunData.p_lastBuyType == BUY_TYPE.CASHBONUS_TYPE or
                        globalData.iapRunData.p_lastBuyType == BUY_TYPE.CASHBONUS_TYPE_NEW or globalData.iapRunData.p_lastBuyType == BUY_TYPE.PIG_CHIP or
                        globalData.iapRunData.p_lastBuyType == BUY_TYPE.PIG_TRIO_SALE
                 then
                    if func then
                        func()
                    end
                    return
                end
                local view = util_createView("GameModule.Shop.BuyTip")
                view:initBuyTip(buyData.reBuyType, buyData.reBuyData, tonumber(buyData.reBuyCoins), 0)
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                view:setOverFunc(
                    function()
                        if func then
                            func()
                        end
                    end
                )
                gLobalNoticManager:postNotification("hide_vedio_icon")
            else
                if func then
                    func()
                end
            end
        end,
        function()
            if func then
                func()
            end
        end
    )
    gLobalSendDataManager:getLogIap():sendUiLog(LOG_ENUM_TYPE.PaymentAction_back, LOG_ENUM_TYPE.PaymentAction_success)
end
------------------------------------------------------SDK支付成功消耗商品失败补单 END

------------------------------------------------------与服务器连接中断补单 START
--活动支付订单数据
function SaleManager:getIapOrderData(orderId)
    self:readUserIapOrder()
    if self.m_orderList and #self.m_orderList > 0 and orderId then
        for i = 1, #self.m_orderList do
            local data = self.m_orderList[i]
            if data and data[1] and data[1] == orderId then
                return data, i
            end
        end
    end
end
--保存支付订单
function SaleManager:saveUserIapOrder(orderId, sendData)
    --订单已存在
    local orderData, index = self:getIapOrderData(orderId)
    if orderData then
        return
    end
    self.m_orderList[#self.m_orderList + 1] = {orderId, sendData}
    self:writeUserIapOrder()
end
--删除已完成订单
function SaleManager:deleteUserIapOrder(orderId)
    --订单不存在
    local orderData, index = self:getIapOrderData(orderId)
    if not orderData then
        return
    end
    table.remove(self.m_orderList, index)
    self:writeUserIapOrder()
end
--清空订单
function SaleManager:clearAllUserIapOrder()
    self.m_orderList = {}
    self:writeUserIapOrder()
end
--写入本地数据
function SaleManager:writeUserIapOrder()
    if device.platform == "mac" then
        return
    end
    local jsonData = cjson.encode(self.m_orderList)
    local path = device.writablePath .. globalData.userRunData.userUdid .. "IAP_ORDER_LIST"
    local file = io.open(path, "wb+")
    file:write(jsonData)
    file:flush()
    file:close()
end

--读取本地数据
function SaleManager:readUserIapOrder()
    if not self.m_orderList then
        local path = device.writablePath .. globalData.userRunData.userUdid .. "IAP_ORDER_LIST"
        self.m_orderList = util_checkJsonDecode(path)
        if not self.m_orderList then
            self.m_orderList = {}
        end
    -- local file = io.open (path,"rb+")
    -- if file then
    --     local jsonData = file:read("*all")
    --     file:close()
    --     if not jsonData or jsonData =="" then
    --         self.m_orderList = {}
    --     else
    --         self.m_orderList = cjson.decode(jsonData)
    --     end
    -- else
    --     self.m_orderList = {}
    -- end
    end
end
--读取未完成支付订单 并且发送订单
function SaleManager:checkSendUserIapOrder(func)
    --清理掉
    self:clearLocalIapInfo()
    self.m_orderList = nil
    self:readUserIapOrder()
    self:checkNextSendUserIapOrder(func)
end

--订单补偿发送
function SaleManager:checkNextSendUserIapOrder(func)
    if not self.m_sendOrderList then
        self.m_sendOrderList = {}
    end
    if self.m_orderList and #self.m_orderList > 0 then
        local orderId = nil
        local orderData = nil
        for i = 1, #self.m_orderList do
            local key = self.m_orderList[i][1]
            if key and not self.m_sendOrderList[key] then
                orderId = key
                orderData = self.m_orderList[i][2]
                self.m_sendOrderList[key] = self.m_orderList[i][2]
                break
            end
        end
        --如果不存在订单结束流程
        if not orderId or not orderData then
            self.m_orderList = {}
            --清空订单
            self:writeUserIapOrder()
            if func then
                func()
            end
            return
        end

        local actionData = nil
        if device.platform == "ios" then
            actionData = GameProto_pb.ApplePurchaseRequest()
        else
            if MARKETSEL == GOOGLE_MARKET then
                actionData = GameProto_pb.GooglePurchaseRequest()
            elseif MARKETSEL == AMAZON_MARKET then
                actionData = GameProto_pb.AmazonPurchaseRequest()
            end
        end
        actionData:ParseFromString(orderData)
        local extraData = cjson.decode(actionData.extra)
        local buyData = {reBuyCoins = extraData.coins, reBuyType = actionData.buyType, reBuyData = nil}

        --成功或者失败都执行下一步
        local function successCallFun()
            --存在购买提示数据
            if buyData and buyData.reBuyType == BUY_TYPE.LUCKY_SPIN_TYPE then
                globalData.iapLuckySpinFunc = function()
                    if self.checkNextSendUserIapOrder then
                        self:checkNextSendUserIapOrder(func)
                    end
                end
                local index = gLobalDataManager:getNumberByField("lastBuyLuckySpinID", 1)
                local shopDatas = globalData.shopRunData:getShopItemDatas()
                local data = {}
                data.buyShopData = shopDatas[index]
                data.reconnect = true
                data.buyIndex = index
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum - data.buyShopData.p_coins)
                G_GetMgr(G_REF.LuckySpin):showMainLayer(data)
            end

            if
                globalData.iapRunData.p_lastBuyType == BUY_TYPE.PIGGYBANK_TYPE or globalData.iapRunData.p_lastBuyType == BUY_TYPE.CASHBONUS_TYPE or
                    globalData.iapRunData.p_lastBuyType == BUY_TYPE.CASHBONUS_TYPE_NEW or globalData.iapRunData.p_lastBuyType == BUY_TYPE.PIG_CHIP or
                    globalData.iapRunData.p_lastBuyType == BUY_TYPE.PIG_TRIO_SALE
             then
                if self.checkNextSendUserIapOrder then
                    self:checkNextSendUserIapOrder(func)
                end
                return
            end

            if buyData and buyData.reBuyData then
                local view = util_createView("GameModule.Shop.BuyTip")
                view:initBuyTip(buyData.reBuyType, buyData.reBuyData, tonumber(buyData.reBuyCoins), 0)
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                view:setOverFunc(
                    function()
                        if self.checkNextSendUserIapOrder then
                            self:checkNextSendUserIapOrder(func)
                        end
                    end
                )
            else
                if self.checkNextSendUserIapOrder then
                    self:checkNextSendUserIapOrder(func)
                end
            end
        end
        local function failedCallFun()
            if self.checkNextSendUserIapOrder then
                self:checkNextSendUserIapOrder(func)
            end
        end

        --没钱spin先获取服务器数据在发消息
        if buyData.reBuyType == BUY_TYPE.NOCOINSSPECIALSALE then
            gLobalViewManager:addLoadingAnima(true)
            self:requestNoCoinsSale(
                function(isOk)
                    gLobalViewManager:removeLoadingAnima()
                    if isOk then
                        self:setBuyDataInfo(buyData, extraData)
                        self:resetVipInfo()
                        gLobalSendDataManager:getNetWorkIap():sendGooglePurchaseData(orderId, orderData, successCallFun, failedCallFun)
                    else
                        failedCallFun()
                    end
                end
            )
            return
        end

        self:setBuyDataInfo(buyData, extraData)
        self:resetVipInfo()
        gLobalSendDataManager:getNetWorkIap():sendGooglePurchaseData(orderId, orderData, successCallFun, failedCallFun)
    else
        if func then
            func()
        end
    end
end
------------------------------------------------------与服务器连接中断补单 END
--购买成功弹窗需要的数据
function SaleManager:setBuyDataInfo(buyData, extraData)
    if buyData.reBuyType == BUY_TYPE.STORE_TYPE then
        local shopCoinData = globalData.shopRunData:getShopItemDatas()
        for i = 1, #shopCoinData do
            if get_integer_string(shopCoinData[i].p_id) == extraData.purchaseId then
                buyData.reBuyData = clone(shopCoinData[i])
            end
        end
    elseif buyData.reBuyType == BUY_TYPE.GEM_TYPE then
        local _, shopGemData = globalData.shopRunData:getShopItemDatas()
        for i = 1, #shopGemData do
            if get_integer_string(shopGemData[i].p_id) == extraData.purchaseId then
                buyData.reBuyData = clone(shopGemData[i])
            end
        end
    elseif buyData.reBuyType == BUY_TYPE.NOCOINSSPECIALSALE then
        buyData.reBuyData = G_GetActivityDataByRef(ACTIVITY_REF.NoCoinSale)
    elseif buyData.reBuyType == BUY_TYPE.THEME_TYPE then
        -- for i = 1, #globalData.saleRunData.p_saleTheme do
        --     local saleData = globalData.saleRunData.p_saleTheme[i]
        --     if get_integer_string(saleData.p_id) == extraData.saleId and get_integer_string(saleData.p_activityId) == extraData.activityId then
        --         buyData.reBuyData = saleData
        --     end
        -- end
    elseif buyData.reBuyType == BUY_TYPE.SEVEN_DAY or buyData.reBuyType == BUY_TYPE.SEVEN_DAY_NO_COIN then
        -- local saleDatas = globalData.saleRunData:getActivitysByType(ACTIVITY_TYPE.SEVENDAY)
        local saleDatas = globalData.GameConfig:getActivityConfigs(ACTIVITY_TYPE.SEVENDAY)
        for key, value in pairs(saleDatas) do
            local saleData = value
            if get_integer_string(saleData.p_id) == extraData.saleId and get_integer_string(saleData.p_activityId) == extraData.activityId then
                buyData.reBuyData = saleData
            end
        end
    elseif buyData.reBuyType == BUY_TYPE.BOOST_TYPE then
        local boostData = globalData.shopRunData.p_shopData.p_storeBoost
        for i = 1, #boostData.p_cashBackBoosts do
            if extraData.purchaseId == get_integer_string(boostData.p_cashBackBoosts[i].p_id) then
                buyData.reBuyData = boostData.p_cashBackBoosts[i]
            end
        end
        for i = 1, #boostData.p_levelBurstBoosts do
            if extraData.purchaseId == get_integer_string(boostData.p_levelBurstBoosts[i].p_id) then
                buyData.reBuyData = boostData.p_levelBurstBoosts[i]
            end
        end
        for i = 1, #boostData.p_bundleBoosts do
            if extraData.purchaseId == get_integer_string(boostData.p_bundleBoosts[i].p_id) then
                buyData.reBuyData = boostData.p_bundleBoosts[i]
            end
        end
    elseif buyData.reBuyType == BUY_TYPE.BETWEENTWO_SALE then
        local manage = G_GetMgr(ACTIVITY_REF.BetweenTwo)
        if manage then
            buyData.reBuyData = manage:getSaleData()
        end
    elseif buyData.reBuyType == BUY_TYPE.TopSale then
        local manage = G_GetMgr(ACTIVITY_REF.Promotion_TopSale)
        if manage then
            buyData.reBuyData = manage:getData() 
        end
    end

    -- 新增加的补单弹窗
    if util_isSupportVersion("1.3.3") or device.platform == "mac" then
        -- 新版补单才会走调用到这块代码
        if
            buyData.reBuyType == BUY_TYPE.RICHMAN_SALE or 
            buyData.reBuyType == BUY_TYPE.BLAST_SALE or 
            buyData.reBuyType == BUY_TYPE.BINGO_SALE or 
            buyData.reBuyType == BUY_TYPE.LUCKYCHALLENGE_SALE or
            buyData.reBuyType == BUY_TYPE.PIGGYBANK_TYPE or
            buyData.reBuyType == BUY_TYPE.CASHBONUS_TYPE or
            buyData.reBuyType == BUY_TYPE.CASHBONUS_TYPE_NEW or
            buyData.reBuyType == BUY_TYPE.QUEST_SKIPSALE or
            buyData.reBuyType == BUY_TYPE.DINNERLAND_SALE or
            buyData.reBuyType == BUY_TYPE.KEEPRECHARGE or
            buyData.reBuyType == BUY_TYPE.NOVICE_KEEPRECHARGE or
            buyData.reBuyType == BUY_TYPE.CHOICE_TYPE or
            buyData.reBuyType == BUY_TYPE.CHOICE_TYPE_NOVICE or
            buyData.reBuyType == BUY_TYPE.QUEST_SALE or
            buyData.reBuyType == BUY_TYPE.COINPUSHER_SALE or
            buyData.reBuyType == BUY_TYPE.SPECIALSALE or
            buyData.reBuyType == BUY_TYPE.SPECIALSALE_FIRST or
            buyData.reBuyType == BUY_TYPE.NEW_COINPUSHER_SALE or
            buyData.reBuyType == BUY_TYPE.PIPECONNECT_SALE or
            buyData.reBuyType == BUY_TYPE.PIPECONNECT_SPECIAL_SALE or
            buyData.reBuyType == BUY_TYPE.SHORT_CARD_DRAW_LOW or
            buyData.reBuyType == BUY_TYPE.SHORT_CARD_DRAW_HIGH or 
            buyData.reBuyType == BUY_TYPE.GROWTH_FUND_UNLOCK_V3 or 
            buyData.reBuyType == BUY_TYPE.RETURN_PASS or
            buyData.reBuyType == BUY_TYPE.BIRTHDAY_SALE or 
            buyData.reBuyType == BUY_TYPE.PIG_CHIP or
            buyData.reBuyType == BUY_TYPE.PIG_TRIO_SALE or 
            buyData.reBuyType == BUY_TYPE.EGYPT_COINPUSHER_SALE
         then
            buyData.reBuyData = {}
            buyData.reBuyData.p_items = {}
            buyData.reBuyData.p_price = extraData.buyPrice
            buyData.reBuyData.p_vipPoint = extraData.vipPoint
            buyData.reBuyData.p_coins = buyData.reBuyCoins
        end
    else
        -- 一些老的补单接口 被重新修改过的 ，需要做新老判断
        if buyData.reBuyType == BUY_TYPE.CASHBONUS_TYPE then
            local wheelData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
        elseif buyData.reBuyType == BUY_TYPE.CHOICE_TYPE or buyData.reBuyType == BUY_TYPE.CHOICE_TYPE_NOVICE then
            local multiSale = {}
            local multipeData = G_GetMgr(ACTIVITY_REF.MultiSale):getRunningData()
            if multipeData then
                multiSale = multipeData:getSalesData()
            end

            for i = 1, #multiSale do
                local saleData = multiSale[i]
                if get_integer_string(saleData.p_id) == extraData.saleId and get_integer_string(saleData.p_activityId) == extraData.activityId then
                    buyData.reBuyData = saleData
                end
            end
        elseif buyData.reBuyType == BUY_TYPE.QUEST_SALE then
            -- local saleDatas = globalData.saleRunData:getActivitysByType(ACTIVITY_TYPE.SEVENDAY)
            local saleDatas = globalData.GameConfig:getActivityConfigs(ACTIVITY_TYPE.SEVENDAY)
            for key, value in pairs(saleDatas) do
                local saleData = value
                if get_integer_string(saleData.p_id) == extraData.saleId and get_integer_string(saleData.p_activityId) == extraData.activityId then
                    buyData.reBuyData = saleData
                end
            end
        elseif buyData.reBuyType == BUY_TYPE.PIGGYBANK_TYPE then
            buyData.reBuyData = G_GetMgr(G_REF.PiggyBank):getData()
        elseif buyData.reBuyType == BUY_TYPE.SPECIALSALE then
            buyData.reBuyData = G_GetMgr(G_REF.SpecialSale):getRunningData()
        elseif buyData.reBuyType == BUY_TYPE.SPECIALSALE_FIRST then
            buyData.reBuyData = G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData()
        end
    end
end

function SaleManager:checkVipLevelUp()
    if not self.m_preVipLevel then
        self:resetVipInfo()
        return
    end

    local subVipLv = globalData.userRunData.vipLevel - self.m_preVipLevel
    if subVipLv > 0 then
        self:resetVipInfo()
        return true
    end
end

-- 没钱Spin请求促销数据
-- function SaleManager:requestNoCoinsSale(callback)
--     local isATest = globalData.GameConfig:checkABtestGroupA("NoCoinsSaleV2")
--     --是否请求新的破产促销
--     local isRequestNewSale = false
--     local mgr = G_GetMgr(ACTIVITY_REF.BrokenSale)
--     if not mgr:isInColdCD() then --and isATest
--         isRequestNewSale = true
--     end

--     local failFunc = function()
--         if callback then
--             callback(false)
--         end
--     end

--     local succFunc = function()
--         if callback then
--             callback(true)
--         end
--     end

--     if isRequestNewSale then
--         local succFunc2 = function()
--             local _saleData = G_GetActivityDataByRef(ACTIVITY_REF.BrokenSale)
--             if not _saleData or not _saleData:isHasSale() then
--                 gLobalSendDataManager:getNetWorkFeature():sendNoCoinsSale(succFunc, failFunc)
--             else
--                 if callback then
--                     callback(true)
--                 end
--             end
--         end
--         -- 破产促销消息
--         gLobalSendDataManager:getNetWorkFeature():sendBankruptSale(succFunc2, failFunc)
--     else
--         gLobalSendDataManager:getNetWorkFeature():sendNoCoinsSale(succFunc, failFunc)
--     end
-- end

-- 没钱Spin请求促销数据
function SaleManager:requestNoCoinsSale(callback)
    local failFunc = function()
        if callback then
            callback(false)
        end
    end

    local succFunc = function()
        if callback then
            callback(true)
        end
    end

    gLobalSendDataManager:getNetWorkFeature():sendNoCoinsSale(succFunc, failFunc)
end

function SaleManager:packServerExtraData()
    local extraData = {}
    local logIap = gLobalSendDataManager:getLogIap()
    if logIap and logIap.getPaySessionId then
        extraData["paySessionId"] = logIap:getPaySessionId()
    end
    if logIap and logIap.getPurchaseInfo then
        local pInfo = logIap:getPurchaseInfo()
        if pInfo then
            extraData["purchaseName"] = pInfo.purchaseName
            extraData["purchaseStatus"] = pInfo.purchaseStatus
        end
    end    
    if logIap and logIap.getEntryInfo then
        local _entryInfo = logIap:getEntryInfo()
        extraData["entryName"] = _entryInfo.entryName
        extraData["entryOpen"] = _entryInfo.entryOpen
        extraData["entryOrder"] = _entryInfo.entryOrder
        extraData["entryStatus"] = _entryInfo.entryStatus
        extraData["entryTheme"] = _entryInfo.entryTheme
        extraData["entryType"] = _entryInfo.entryType
    end
    if logIap and logIap.getQuestInfo then
        local questInfo = logIap:getQuestInfo()
        extraData["questInfo"] = questInfo
    end
    extraData["bet"] = logIap.m_spinTotalBet
    extraData["userCoins"] = logIap.m_spinUserCoins
    -- globalData.userRunData.coinNum

    --更新支付传递给服务器的log
    if logIap and logIap.updateServerExtraData then
        logIap:updateServerExtraData(extraData)
    end

    return extraData
end

return SaleManager
