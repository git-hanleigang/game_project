--
-- 发送 iap消息
-- Author:{author}
-- Date: 2019-05-16 18:13:45
-- FIX IOS 139
--弃用类型（小猪为啥还在用）
GD.LOG_IAP_ENMU = {
    --操作状态
    operationStatus = {
        sdkEsc = "sdkEsc",
        testPay = "testPay"
    },
    --类型名称
    purchaseName = {
        pigBank = "pigBank",
        pigBuff = "pigBuff",
        pigSale = "pigSale",
        pigNewUser = "pigNewUser",
        PigClanSale = "PigTeam" -- 公会小猪折扣
    }
}
-- local ActivityManager = require("common.ActivityManager")
local NetworkLog = require "network.NetworkLog"
local LogIap = class("LogIap", NetworkLog)

--游戏内活动列表
local GameActivityList = {
    Activity_Bingo = "Bingo",
    Activity_Quest = "Quest",
    Activity_Picks = "Picks",
    Activity_Snake = "Snake",
    Activity_Blast = "Blast",
    Activity_CoinPusher = "CoinPusher",
    Activity_Redecor = "Redecor"
}
--table
LogIap.m_purchaseInfo = nil --支付相关
LogIap.m_goodsInfo = nil --订单相关
LogIap.m_entryInfo = nil --入口相关
LogIap.m_userInfo = nil --用户数据相关
LogIap.m_orderInfo = nil --订单数据
LogIap.m_itemList = nil --道具buff列表
--特殊参数
LogIap.m_paySessionId = nil --支付唯一标识
LogIap.m_totalCoins = nil --本次购买获得的金币
LogIap.m_totalGems = nil --本次购买获得的钻石
LogIap.m_sdkCode = nil --sdk返回的状态
LogIap.m_buDan = nil --是否为补单信息
LogIap.m_entryData = nil --购买入口信息，客户端发给服务器用
function LogIap:ctor()
    NetworkLog.ctor(self)
    self:resetLogData()
    --活动总入口发送日志的缓存列表（活动总入口会打开初始化所有开放活动的日志，导致最后付费的日志替换成新的）
    self.entranceLogMap = {}
    self:clearEntranceLogMap()
end
function LogIap:sendLogMessage(...)
    local args = {...}
    --TODO 在这里组织你感兴趣的数据
    NetworkLog.sendLogData(self)
end

function LogIap:setOpenIapLogInfo(view)
    if view ~= nil then
        local info = self.entranceLogMap[view]
        if info ~= nil then
            self:openIapLogInfo(info[1], info[2], info[3], info[4], nil)
        end
    end
end

function LogIap:getGoodsInfo()
    return self.m_goodsInfo
end

function LogIap:getPurchaseInfo()
    return self.m_purchaseInfo
end

function LogIap:clearEntranceLogMap()
    self.m_entryInfo = {}
end

--打开支付界面 bHasSessinID是否已经创建SessionID
function LogIap:openIapLogInfo(goodsInfo, purchaseInfo, operationType, bHasSessinID, view)
    if not goodsInfo then
        return
    end
    if view ~= nil and view.__cname == "EntrancePageCell" then
        self.entranceLogMap[view] = {goodsInfo, purchaseInfo, operationType, bHasSessinID}
        return
    end
    if not bHasSessinID then
        self:createPaySessionId(goodsInfo.goodsTheme)
    end

    self:setPayGoodsInfo(goodsInfo)
    self:setPurchaseInfo(purchaseInfo)
    if operationType then
        self:sendUiLog(operationType)
    else
        self:sendUiLog("open")
    end
end

--关闭支付界面
function LogIap:closeIapLogInfo(operationType)
    --屏蔽不要关闭打点
    -- if operationType then
    --       self:sendUiLog(operationType)
    -- else
    --       self:sendUiLog("close")
    -- end
end
--增加道具
function LogIap:addItem(itemStr)
    if not self.m_itemList then
        self.m_itemList = {}
    end
    self.m_itemList[#self.m_itemList + 1] = itemStr
end
--设置道具列表
function LogIap:setItemList(itemList)
    --修改道具
    if not itemList or #itemList == 0 then
        return
    end
    self.m_itemList = {}
    for i = 1, #itemList do
        local itemData = itemList[i]
        if itemData and itemData.getIapLogStr then
            local itemStr = itemData:getIapLogStr()
            self:addItem(itemStr)
        end
    end
end

---------------------------发送log START----------------------
--gLobalSendDataManager:getLogIap():setEnterOpen

--基础log
function LogIap:sendIapLog(messageData, logEvent)
    gL_logData:syncUserData()
    gL_logData:syncEventData(logEvent)
    local new = 0
    if globalData.userRunData:isNewUser() then
        new = 1
    end

    local newPayStatus = 1
    if globalData.hasPurchase then
        newPayStatus = 0
    end

    if not self.m_entryInfo.entryOrder then
        self.m_entryInfo.entryOrder = 1
    end
    --是否是quest关卡
    local entryStatus = "Normal"
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig and questConfig.m_IsQuestLogin then
        if questConfig:isNewUserQuest() then
            entryStatus = "NewQuest"
        else
            if questConfig:getThemeName() == "Activity_QuestIsland" then
                entryStatus = "islandQuestGame"
            else
                entryStatus = "QuestGame"
            end
        end
    end
    if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest()then
        entryStatus = "fantasyQuestGame"
    end
    self.m_entryInfo.entryStatus = entryStatus

    messageData.paySessionId = self.m_paySessionId
    messageData.actionTime = xcyy.SlotsUtil:getMilliSeconds()
    messageData.saleType = self.m_purchaseInfo.saleType
    messageData.saleName = self.m_purchaseInfo.saleName
    messageData.purchaseType = self.m_purchaseInfo.purchaseType
    messageData.purchaseName = self.m_purchaseInfo.purchaseName
    messageData.purchaseStatus = self.m_purchaseInfo.purchaseStatus
    messageData.entryType = self.m_entryInfo.entryType or "lobby"
    messageData.entryName = self.m_entryInfo.entryName
    messageData.entryOpen = self.m_entryInfo.entryOpen
    messageData.entryTheme = self.m_entryInfo.entryTheme
    messageData.entryOrder = self.m_entryInfo.entryOrder
    messageData.entryStatus = self.m_entryInfo.entryStatus
    messageData.goodsId = self.m_goodsInfo.goodsId
    messageData.goodsTheme = self.m_goodsInfo.goodsTheme
    messageData.goodsThemeUiType = self.m_goodsInfo.goodsThemeUiType
    messageData.goodsPrice = self.m_goodsInfo.goodsPrice
    messageData.discount = self.m_goodsInfo.discount
    messageData.new = new
    messageData.newPayStatus = newPayStatus
    if self.m_purchaseInfo.hotSaleIcon then
        messageData.icon = self.m_purchaseInfo.hotSaleIcon
    end
    --添加quest关卡信息
    local questInfo = self:getQuestInfo()
    messageData.questInfo = questInfo
    self:checkAddActivityData(messageData)
    self:checkAddSpinData(messageData)
    for i = 1, #self.m_itemList do
        messageData["item" .. i] = self.m_itemList[i]
    end
    --中间页修改字段
    if messageData.operationType == "openTheme" or messageData.operationType == "closeTheme" then
        messageData.entryTheme = messageData.goodsTheme
        messageData.goodsTheme = nil
    end
    -- 是否调起代币弹版
    messageData.tsts = self.m_purchaseInfo.tokenStatus
    -- 当前代币数量
    local buckMgr = G_GetMgr(G_REF.ShopBuck)
    if buckMgr then
        messageData.ut = buckMgr:getBuckNum()
    end

    self.m_entryData = {}
    self.m_entryData.pn = messageData.purchaseName
    self.m_entryData.ps = messageData.purchaseStatus

    gL_logData.p_data = messageData
    self:sendLogData()
end

function LogIap:getQuestInfo()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig then
        --解锁等级
        local unLockLevel = globalData.constantData.OPENLEVEL_NEWQUEST or 30
        local curLevel = globalData.userRunData.levelNum
        local leftTime = questConfig:getLeftTime()
        if leftTime and leftTime > 0 and questConfig.p_round and curLevel >= unLockLevel then
            local phase_idx = questConfig:getPhaseIdx()
            local stage_idx = questConfig:getStageIdx()

            local questInfo = questConfig.p_round .. "-" .. phase_idx
            if stage_idx and questConfig:getThemeName() ~= "Activity_QuestIsland" then
                questInfo = questInfo .. "-" .. stage_idx
            end
            return questInfo
        end
    end

    return nil
end

--支付相关操作
function LogIap:sendUiLog(operationType, sdkStatus)
    local messageData = {
        operationType = operationType,
        operationStatus = sdkStatus,
        orderID = self.m_orderInfo.orderID,
        totalCoins = self.m_totalCoins,
        totalGems = self.m_totalGems,
        sdkCode = self.m_sdkCode
    }
    --发送log
    self:sendIapLog(messageData, "PaymentAction")
end
--订单发送成功或失败
function LogIap:sendOrderLog(status)
    self.m_orderInfo.orderStatus = status
    local messageData = {
        orderStarTime = self.m_orderInfo.orderStarTime,
        orderID = self.m_orderInfo.orderID,
        orderStatus = self.m_orderInfo.orderStatus,
        orderCloseTime = os.time(),
        totalCoins = self.m_totalCoins,
        totalGems = self.m_totalGems,
        addCoins = self.m_userInfo.addCoins,
        addCoinsVip = self.m_userInfo.addCoinsVip,
        addCoinsActivity = self.m_userInfo.addCoinsActivity,
        addVipExp = self.m_userInfo.addVipExp,
        lastVipLevel = globalData.userRunData.vipLevel,
        lastVipExp = globalData.userRunData.vipPoints,
        lastCoins = globalData.userRunData.coinNum
    }
    --发送log
    self:sendIapLog(messageData, "PaymentOrder")
end
--设置sdk状态
function LogIap:setSdkCode(strCode)
    self.m_sdkCode = strCode
end
--创建本次购买唯一标识
function LogIap:createPaySessionId(name)
    if not name then
        name = "iap"
    end
    local randomTag = xcyy.SlotsUtil:getMilliSeconds()
    local platform = device.platform
    local id = nil
    if platform == "ios" then
        id = globalPlatformManager:getIDFV() or "ID"
    else
        id = globalPlatformManager:getAndroidID() or "ID"
    end
    self.m_paySessionId = tostring(id) .. "_" .. name .. randomTag
    self:resetLogData()
end

function LogIap:getPaySessionId()
    return self.m_paySessionId
end

--创建订单
function LogIap:createOrder(orderId)
    self.m_orderInfo.orderStarTime = os.time()
    self.m_orderInfo.orderID = orderId
end
--重置log数据
function LogIap:resetLogData()
    self.m_purchaseInfo = {} --支付相关
    self.m_goodsInfo = {} --订单相关
    self.m_userInfo = {} --用户数据相关
    self.m_orderInfo = {} --订单数据
    self.m_itemList = {}
    self.m_sdkCode = nil
    self.m_totalCoins = nil
    self.m_totalGems = nil
    self:clearPushCount()
    self:checkSaveSpinData()
end

--支付相关操作 记录操作步骤
function LogIap:sendUiLogV2(operationType, sdkStatus, step)
    local messageData = {
        operationType = operationType,
        operationStatus = sdkStatus,
        step = step
    }
    --发送log
    self:sendIapLog(messageData, "PaymentV2")
end

---------------------------发送log END----------------------
---------------------------位置信息 START----------------------
function LogIap:setEntryType(entryType)
    if entryType == "game" then
        --弃用了 通过setEntryGame处理游戏中位置
        return
    end
    if gLobalViewManager:isLevelView() then
        return
    end
    if self.m_entryInfo and self.m_entryInfo.entryType then
        self.m_lastEntryType = self.m_entryInfo.entryType
    end
    self.m_entryInfo = {} --入口相关
    self:resetLogData()
    self.m_entryInfo.entryType = entryType
end

function LogIap:getEntryType()
    return self.m_entryInfo and self.m_entryInfo.entryType
end

function LogIap:getEntryInfo()
    return self.m_entryInfo
end

--进入游戏位置
function LogIap:setEntryGame(gameName)
    if self.m_entryInfo and self.m_entryInfo.entryType then
        self.m_lastEntryType = self.m_entryInfo.entryType
    end
    self.m_entryInfo = {} --入口相关
    self:resetLogData()
    self.m_entryInfo.entryType = gameName
end
--还原上次的位置信息
function LogIap:setLastEntryType()
    if self.m_entryInfo then
        if self.m_lastEntryType then
            self.m_entryInfo.entryType = self.m_lastEntryType
        else
            self.m_entryInfo.entryType = "lobby"
        end
    end
end
--打开方式 打开的名称 indexType 类型索引 indexName名字索引
function LogIap:setEnterOpen(entryOpen, entryName, entryTheme)
    if entryOpen then
        self.m_entryInfo.entryOpen = entryOpen
    end
    if entryName then
        self.m_entryInfo.entryName = entryName
    end
    self.m_entryInfo.entryTheme = entryTheme
end
function LogIap:setEntryName(entryName)
    self.m_entryInfo.entryName = entryName
end

--打开方式 打开的名称 indexType 类型索引 indexName名字索引
function LogIap:setLCEnterOpen(entryOpen, entryName)
    if entryOpen then
        self.m_entryInfo.entryOpen = entryOpen
    end
    if entryName then
        self.m_entryInfo.entryName = entryName
    end
end

--增加计数
function LogIap:addPushCount(vType)
    if vType == self.m_lastVType then
        self.m_vTypeCount = self.m_vTypeCount + 1
    else
        self.m_lastVType = vType
        self.m_vTypeCount = 2
    end
end
--刷新计数
function LogIap:updatePushCount()
    self:setEntryOrder(self.m_vTypeCount)
end
--清空
function LogIap:clearPushCount()
    self.m_lastVType = "none"
    self.m_vTypeCount = 1
end
function LogIap:setEntryOrder(order)
    self.m_entryInfo.entryOrder = order
end
---------------------------位置信息 END----------------------
---------------------------支付信息 START----------------------
--设置商品类型信息
function LogIap:setPurchaseInfo(info)
    if not info or not self.m_purchaseInfo then
        return
    end
    if type(info) ~= "table" then
        return
    end
    --支付类型
    if info.purchaseType then
        self.m_purchaseInfo.purchaseType = info.purchaseType
    end
    --支付名称
    if info.purchaseName then
        self.m_purchaseInfo.purchaseName = info.purchaseName
    end
    --支付状态
    if info.purchaseStatus then
        self.m_purchaseInfo.purchaseStatus = info.purchaseStatus
    end
    --促销类型
    if info.saleType then
        self.m_purchaseInfo.saleType = info.saleType
    end
    --促销名字
    if info.saleName then
        self.m_purchaseInfo.saleName = info.saleName
    end
    if info.hotSaleIcon then
        self.m_purchaseInfo.hotSaleIcon = info.hotSaleIcon
    else
        self.m_purchaseInfo.hotSaleIcon = nil
    end
end

function LogIap:setPurchaseBuckInfo(info)
    if info.tokenStatus then
        self.m_purchaseInfo.tokenStatus = info.tokenStatus
    end
end
---------------------------支付信息 END----------------------
---------------------------商品信息 START----------------------
function LogIap:setPayGoodsInfo(goodsInfo)
    if not goodsInfo or not self.m_goodsInfo then
        return
    end
    if type(goodsInfo) ~= "table" then
        return
    end
    if goodsInfo.goodsTheme then
        self.m_goodsInfo.goodsTheme = goodsInfo.goodsTheme
    end
    if goodsInfo.goodsId then
        self.m_goodsInfo.goodsId = goodsInfo.goodsId
    end
    if goodsInfo.goodsPrice then
        self.m_goodsInfo.goodsPrice = goodsInfo.goodsPrice
    end
    if goodsInfo.discount then
        self.m_goodsInfo.discount = goodsInfo.discount
    end
    if goodsInfo.totalCoins then
        if iskindof(goodsInfo.totalCoins,"LongNumber") then
            self.m_totalCoins = goodsInfo.totalCoins
        else
            self.m_totalCoins = math.floor(goodsInfo.totalCoins)
        end 
    end
    if goodsInfo.totalGems then
        self.m_totalGems = math.floor(goodsInfo.totalGems)
    end
    if globalData.slotRunData.isPortrait == true then
        self.m_goodsInfo.goodsThemeUiType = "uiUpright"
    else
        self.m_goodsInfo.goodsThemeUiType = "uiHorizontal"
    end
end
---------------------------商品信息 END----------------------
---------------------------金币产出 START----------------------
function LogIap:setAddCoins(addCoins, addCoinsVip, addCoinsActivity, addVipExp)
    if addCoins then
        self.m_userInfo.addCoins = addCoins
    end
    if addCoinsVip then
        self.m_userInfo.addCoinsVip = addCoinsVip
    end
    if addCoinsActivity then
        self.m_userInfo.addCoinsActivity = addCoinsActivity
    end
    if addVipExp then
        self.m_userInfo.addVipExp = addVipExp
    end
end
---------------------------金币产出 END----------------------
---------------------------其他 START-----------------------------
--获取游戏中活动名称
function LogIap:getGameActivityName()
    local activityDatas = globalData.commonActivityData:getActivitys()

    for k, value in pairs(activityDatas) do
        local actData = value
        if actData and actData:isRunning() and actData:getRefName() and actData.p_start then
            local strStartTime = string.sub(actData.p_start, 1, 10)
            local strActivityName = self:getActivityNameForLuaCode(actData:getRefName(), true, strStartTime)
            if strActivityName then
                return strActivityName
            end
        end
    end
end

--获取活动名字列表
function LogIap:getActivityNameList()
    local nameStr
    local activityDatas = globalData.commonActivityData:getActivitys()

    for k, value in pairs(activityDatas) do
        local actData = value
        if actData and actData:isRunning() and actData:getRefName() then
            if not nameStr and actData.p_start then
                local strStartTime = string.sub(actData.p_start, 1, 10)
                nameStr = self:getActivityNameForLuaCode(actData:getRefName(), false, strStartTime)
            else
                local activityName = self:getActivityNameForLuaCode(actData:getRefName())
                if activityName then
                    nameStr = (nameStr or "") .. "|" .. activityName
                end
            end
        end
    end

    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    local isInNoviceDiscount = piggyBankData and piggyBankData:checkInNoviceDiscount()
    if isInNoviceDiscount then
        if not nameStr then
            nameStr = LOG_IAP_ENMU.purchaseName.pigNewUser
        else
            nameStr = nameStr .. "|" .. LOG_IAP_ENMU.purchaseName.pigNewUser
        end
    end

    return nameStr
end

function LogIap:getAcitvityStartTime(luaCode)
    local activityDatas = globalData.commonActivityData:getActivitys()

    for k, value in pairs(activityDatas) do
        local actData = value
        if actData and actData:isRunning() and actData:getRefName() and actData:getRefName() == luaCode then
            return table.concat(util_string_split(actData.p_start, "-"), "")
        end
    end

    return ""
end

--luaCode 程序引用名 isOnlyGame只坚持游戏中
function LogIap:getActivityNameForLuaCode(luaCode, isOnlyGame, startTime)
    if not luaCode then
        return luaCode
    end
    --添加转换过程
    -- luaCode = ActivityManager.getActivityRelativeBaseKey(luaCode)

    local gameActivityName = GameActivityList[luaCode]
    if gameActivityName then
        if gameActivityName == "Quest" then
            local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
            if questConfig and not questConfig.m_IsQuestLogin and not questConfig.m_isQuestLobby then
                return
            end
        end
        if startTime then
            gameActivityName = gameActivityName .. table.concat(util_string_split(startTime, "-"), "")
        else
            gameActivityName = gameActivityName .. self:getAcitvityStartTime(luaCode)
        end
    end
    if isOnlyGame then
        return gameActivityName
    end
    if gameActivityName then
        return gameActivityName
    else
        local _, AendPos = string.find(luaCode, "Activity_")
        local _, PendPos = string.find(luaCode, "Promotion_")
        if AendPos then
            return string.sub(luaCode, AendPos + 1, -1)
        elseif PendPos then
            return string.sub(luaCode, PendPos + 1, -1)
        else
            return luaCode
        end
    end
end

--打点补丁
function LogIap:checkAddActivityData(messageData)
    local activityDatas = globalData.commonActivityData:getActivitys()
    if table_nums(activityDatas) > 0 then
        messageData.saleType = "activity"
        messageData.saleName = self:getActivityNameList()
        if not messageData.saleName then
            messageData.saleType = "normal"
            messageData.saleName = "normal"
        end
    else
        messageData.saleType = "normal"
        messageData.saleName = "normal"
    end
end

--附加spin信息
function LogIap:checkAddSpinData(messageData)
    if not messageData then
        return
    end
    local uid = globalData.userRunData.uid or "nil"
    if not self.m_spinUserCoins then
        self.m_spinUserCoins = gLobalDataManager:getStringByField(uid .. "logIapSpinUserCoins", "0")
    end
    if not self.m_spinTotalBet then
        self.m_spinTotalBet = gLobalDataManager:getStringByField(uid .. "logIapSpinTotalBet", "0")
    end
    messageData.spin = {
        userCoins = self.m_spinUserCoins,
        bet = self.m_spinTotalBet
    }
end
--设置spin信息
function LogIap:setSpinLog(coins, totalBet)
    if type(coins) == "number" then
        self.m_spinUserCoins = string.format("%d", coins)
    else
        self.m_spinUserCoins = "" .. coins
    end

    if type(totalBet) == "number" then
        self.m_spinTotalBet = string.format("%d", totalBet)
    else
        self.m_spinTotalBet = "" .. totalBet
    end
end
--尝试保存spin信息
function LogIap:checkSaveSpinData()
    if not globalData or not globalData.userRunData or not globalData.userRunData.uid then
        return
    end
    local uid = globalData.userRunData.uid
    if self.m_spinUserCoins then
        self.m_spinUserCoins = gLobalDataManager:setStringByField(uid .. "logIapSpinUserCoins", self.m_spinUserCoins)
    end
    if self.m_spinTotalBet then
        self.m_spinTotalBet = gLobalDataManager:setStringByField(uid .. "logIapSpinTotalBet", self.m_spinTotalBet)
    end
end
---------------------------其他 END----------------------
function LogIap:createGoodsInfo()
end
--更新支付传递给服务器的log
function LogIap:updateServerExtraData(extraData)
    if not extraData then
        return
    end
    local _lastBuyType = globalData.iapRunData.p_lastBuyType or ""
    local _activityId = globalData.iapRunData.p_activityId
    local _contentId = globalData.iapRunData.p_contentId
    local _lastBuyCoin = globalData.iapRunData.p_lastBuyCoin

    if _lastBuyType == BUY_TYPE.STORE_TYPE then
        local shopData = globalData.iapRunData.p_showData
        extraData["purchaseId"] = get_integer_string(shopData.p_id)
        extraData["keyId"] = shopData.p_keyId
        extraData["key"] = shopData.p_key
        extraData["coins"] = get_integer_string(_lastBuyCoin)
        extraData["CloseStoreDiscounts"] = get_integer_string(_contentId)
        local coinsData, gemsData,hotSale = globalData.shopRunData:getShopItemDatas()
        local figer = 0
        if coinsData and coinsData[1] then
            figer = tonumber(coinsData[1].p_id) - 1
        end
        local index = tonumber(shopData.p_id) - figer
        extraData["gearIndex"] = tostring(index)
    elseif globalData.iapRunData.p_lastBuyType == BUY_TYPE.GEM_TYPE or globalData.iapRunData.p_lastBuyType == BUY_TYPE.StorePet then
        local shopData = globalData.iapRunData.p_showData
        extraData["purchaseId"] = get_integer_string(shopData.p_id)
        extraData["keyId"] = shopData.p_keyId
        extraData["key"] = shopData.p_key
        extraData["coins"] = get_integer_string(_lastBuyCoin)
        extraData["CloseStoreDiscounts"] = get_integer_string(_contentId)
    elseif _lastBuyType == BUY_TYPE.CASHBONUS_TYPE then
        local wheelData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
        extraData["name"] = wheelData.p_name
        extraData["key"] = wheelData.p_key
        extraData["coins"] = get_integer_string(_lastBuyCoin)
        extraData["jackpot"] = get_integer_string(math.ceil(G_GetMgr(G_REF.CashBonus):getJackpotData() or 0))
    elseif _lastBuyType == BUY_TYPE.CASHBONUS_TYPE_NEW then
        local wheelData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
        extraData["name"] = wheelData.p_name
        extraData["key"] = wheelData.p_key
        extraData["coins"] = get_integer_string(_lastBuyCoin)
        extraData["jackpot"] = get_integer_string(math.ceil(G_GetMgr(G_REF.CashBonus):getJackpotData() or 0))
    elseif _lastBuyType == BUY_TYPE.SPECIALSALE then
        local saleData = G_GetMgr(G_REF.SpecialSale):getRunningData()
        if saleData then
            extraData["keyId"] = saleData.p_keyId
            extraData["key"] = saleData.p_key
            extraData["coins"] = saleData.p_coins
            extraData["position"] = saleData.m_buyPosition
            extraData["saleId"] = saleData.p_id
        end
    elseif _lastBuyType == BUY_TYPE.NOCOINSSPECIALSALE then
        local saleData = G_GetActivityDataByRef(ACTIVITY_REF.NoCoinSale)
        if saleData then
            extraData["keyId"] = saleData.p_keyId
            extraData["key"] = saleData.p_key
            extraData["coins"] = saleData.p_coins
            extraData["position"] = saleData.m_buyPosition
            extraData["saleId"] = saleData.p_id
        end
    elseif _lastBuyType == BUY_TYPE.THEME_TYPE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["saleId"] = get_integer_string(_contentId)
            extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.CHOICE_TYPE or _lastBuyType == BUY_TYPE.CHOICE_TYPE_NOVICE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["saleId"] = get_integer_string(_contentId)
            extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.QUEST_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["saleId"] = get_integer_string(_contentId)
            extraData["activityId"] = get_integer_string(_activityId)
            extraData["buyPrice"] = globalData.iapRunData.p_lastBuyPrice
            local purchaseData = gLobalItemManager:getCardPurchase(nil, globalData.iapRunData.p_lastBuyPrice)
            extraData["vipPoint"] = get_integer_string(purchaseData.p_vipPoints)
        end
    elseif _lastBuyType == BUY_TYPE.SEVEN_DAY or _lastBuyType == BUY_TYPE.LUCKYCHALLENGE_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["saleId"] = get_integer_string(_contentId)
            extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.BINGO then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["saleId"] = get_integer_string(_contentId)
            extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.SEVEN_DAY_NO_COIN then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["saleId"] = get_integer_string(_contentId)
            extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.BOOST_TYPE then
        local shopData = globalData.iapRunData.p_showData
        extraData["purchaseId"] = get_integer_string(shopData.p_id)
    elseif _lastBuyType == BUY_TYPE.KEEPRECHARGE or _lastBuyType == BUY_TYPE.NOVICE_KEEPRECHARGE or _lastBuyType == BUY_TYPE.KEEPRECHARGE4 then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["saleIndex"] = get_integer_string(_contentId)
            extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.BINGO_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
            extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.RICHMAN_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        --     extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.BLAST_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        -- extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.NEWBLAST_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        -- extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.COINPUSHER_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        -- extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.WORD_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.DININGROOM_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.DINNERLAND_SALE then
        -- 餐厅促销
        if _activityId ~= nil and _contentId ~= nil then
            local dinnerLandData = G_GetActivityDataByRef(ACTIVITY_REF.DinnerLand)
            if dinnerLandData then
                local buff = dinnerLandData:getBuyBuff()
                if util_isSupportVersion("1.3.3") or device.platform == "mac" then
                    if buff == nil then
                        -- 如果当前没有拿到buff数据。证明可能是补单进入
                        local reBuff = gLobalIAPManager:getReBuySpecailSaleBuffType()
                        if reBuff then
                            buff = reBuff
                        end
                    end
                end
                extraData["buffType"] = buff
            end
        end
    elseif _lastBuyType == BUY_TYPE.BP_BUY_LV then
        if _contentId ~= nil then
            extraData["saleIndex"] = get_integer_string(_contentId)
            extraData["activityId"] = _activityId
        end
    elseif _lastBuyType == BUY_TYPE.SPECIALSALE_FIRST then
        local saleData = G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData()
        if saleData then
            extraData["keyId"] = saleData.p_keyId
            extraData["key"] = saleData.p_key
            extraData["coins"] = saleData.p_coins
            extraData["position"] = saleData.m_buyPosition
            extraData["saleId"] = saleData.p_id
        end
    elseif _lastBuyType == BUY_TYPE.BETWEENTWO_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["fruitId"] = get_integer_string(_contentId)
            extraData["activityId"] = _activityId
        end
    elseif _lastBuyType == BUY_TYPE.ARENA_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["arenaId"] = get_integer_string(_contentId)
            extraData["activityId"] = _activityId
        end
    elseif _lastBuyType == BUY_TYPE.LEVEL_RUSH_TYPE then
        local dataLevelRush = gLobalLevelRushManager:pubGetRunningGameData()
        if dataLevelRush then
            local index = dataLevelRush:getGameIndex()
            extraData["gameIndex"] = tostring(index)
            extraData["source"] = dataLevelRush:getSource()
        end
    elseif _lastBuyType == BUY_TYPE.TwoChooseOneGiftSale then
        local mgr = G_GetMgr(ACTIVITY_REF.TornadoMagicStore)
        extraData.giftIndex = mgr:getLastBuyType()
    elseif _lastBuyType == BUY_TYPE.REDECOR_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        -- extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.NEWPASS_LEVELSTORE or _lastBuyType == BUY_TYPE.TRIPLEXPASS_LEVELSTORE_NOVICE or _lastBuyType == BUY_TYPE.TRIPLEXPASS_LEVELSTORE then
        if _contentId ~= nil then
            extraData["saleIndex"] = get_integer_string(_contentId)
            extraData["activityId"] = _activityId
        end
    elseif _lastBuyType == BUY_TYPE.DIVINATION then
        if _contentId ~= nil then
            extraData["buyItems"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.POKER_RECALL_TYPE then
        local dataPokerRecall = G_GetMgr(G_REF.PokerRecall):getCurPokerGameData()
        if dataPokerRecall then
            local index = dataPokerRecall:getGameId()
            --extraData["keyId"] = saleData.p_keyId
            extraData["gameIndex"] = tostring(index)
            extraData["source"] = dataPokerRecall:getSource()
        end
    elseif _lastBuyType == BUY_TYPE.VIDEO_POKER_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.WORLDTRIP_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.DUCK_SHOT_TYPE then
        local index = G_GetMgr(ACTIVITY_REF.DuckShot):getPlayGameIndex()
        if index ~= 0 then
            extraData["gameIndex"] = tostring(index)
        end
    elseif _lastBuyType == BUY_TYPE.QUEST_SKIPSALE then
        local quest_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if quest_data then
            local stage_data = quest_data:getCurStageData()
            if stage_data then
                extraData["QuestSkipGame"] = stage_data.p_game
            end
        end
    elseif _lastBuyType == BUY_TYPE.MINI_GAME_CASHMONEY then
        local gameId = G_GetMgr(G_REF.CashMoney):getCurrentGameId()
        if gameId ~= 0 then
            extraData["gameIndex"] = tostring(gameId)
        else
            local errorMessage = "cashMoney gameIndex:" .. tostring(gameId)
            util_sendToSplunkMsg("CashMoneyGameindex", errorMessage)
        end
    elseif _lastBuyType == BUY_TYPE.PIGGY_CLICKER_PAY then
        if _activityId and _contentId then
            extraData["gameIndex"] = tostring(_contentId)
        end
    elseif _lastBuyType == BUY_TYPE.FLOWER then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["flowerType"] = _contentId
        -- extraData["activityId"] = get_integer_string(_activityId)
        end
    elseif _lastBuyType == BUY_TYPE.SCRATCHCARD then
        if _activityId and _contentId then
            local scratchCardData = G_GetMgr(ACTIVITY_REF.ScratchCards):getRunningData()
            if scratchCardData then
                extraData["gearKey"] = _contentId
            end
        end
    elseif _lastBuyType == BUY_TYPE.PINBALLGO then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["gameIndex"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.LUCKY_FISH then
        if _activityId ~= nil and _contentId ~= nil then
            if _activityId == "LUCKYFISH" then
                extraData["gameIndex"] = tostring(_contentId)
            end
        end
    elseif _lastBuyType == BUY_TYPE.PERL_LINK then
        if _activityId ~= nil and _contentId ~= nil then
            if _activityId == "PERL_LINK" then
                extraData["pearlsLinkGameIndex"] = tostring(_contentId)
                extraData["payLevel"] = _lastBuyCoin
            end
        end
    elseif _lastBuyType == BUY_TYPE.PERL_NEW_LINK then
        if _activityId ~= nil and _contentId ~= nil then
            if _activityId == "PERL_NEW_LINK" then
                extraData["pearlsLinkGameIndex"] = tostring(_contentId)
                extraData["gears"] = _lastBuyCoin
            end
        end
    elseif _lastBuyType == BUY_TYPE.NEW_COINPUSHER_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        end
    elseif (_lastBuyType == BUY_TYPE.PIPECONNECT_SALE or _lastBuyType == BUY_TYPE.PIPECONNECT_SPECIAL_SALE) then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.TEAM_RED_GIFT then
        if _contentId ~= nil then
            extraData["clanRedPackageUdids"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.SHORT_CARD_DRAW_LOW or _lastBuyType == BUY_TYPE.SHORT_CARD_DRAW_HIGH then
        -- todo 
        -- if _contentId ~= nil then
        --     extraData["clanRedPackageUdids"] = _contentId
        -- end    
    elseif _lastBuyType == BUY_TYPE.MONTHLY_CARD then
        if _contentId ~= nil then
            extraData["monthlyCardType"] = _contentId --standard 标准版  deluxe 豪华版
        end
    elseif _lastBuyType == BUY_TYPE.StoreHotSale then
        if _contentId ~= nil then
            extraData["storeHotSaleProductId"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.HOUR_DEAL_SALE then
        extraData["type"] = get_integer_string(_contentId)
    elseif _lastBuyType == BUY_TYPE.DiyComboDealSale then
        if _contentId ~= nil then
            extraData["diyComboDealSaleProductId"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.CHALLENGEPASS_UNLOCK then
        if _contentId ~= nil then
            extraData["saleIndex"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.GROWTH_FUND_UNLOCK_V3 then
        if _contentId ~= nil then
            extraData["growthFundV3Index"] = tostring(_contentId)
        end
    elseif _lastBuyType == BUY_TYPE.LUCKY_SPIN_TYPE then
        if _contentId ~= nil then
            extraData["luckySpinEnjoy"] = tostring(_contentId)
        end
    elseif _lastBuyType == BUY_TYPE.LUCKY_SPINV2_TYPE then
        if _contentId ~= nil then
            extraData["luckySpinEnjoy"] = tostring(_contentId)
        end
    elseif _lastBuyType == BUY_TYPE.FIRST_SALE_MULTI then
        if _activityId and _contentId then
            extraData["mfsLevel"] = tostring(_contentId)
        end
    elseif _lastBuyType == BUY_TYPE.DIYFEATURE_OVERSALE then
        if _activityId and _contentId then
            extraData["DIYFeatureOverSaleType"] = tostring(_contentId)
        end
    elseif _lastBuyType == BUY_TYPE.LimitedGift then
        if _contentId ~= nil then
            extraData["saleIndex"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.LEVELROADGAME then
        if _contentId ~= nil then
            extraData["levelRoadGameIndex"] = tostring(_contentId)
        end
    elseif _lastBuyType == BUY_TYPE.ZOMBIE_ARMS_SALE then
        if _contentId ~= nil then
            extraData["zombieOnslaughtSaleType"] = tostring(_contentId)
        end
    elseif _lastBuyType == BUY_TYPE.DIY_BUFFSALE then
        if _contentId ~= nil then
            extraData["DiyFeatureBuffSaleSeq"] = tostring(_contentId)
        end
    elseif _lastBuyType == BUY_TYPE.ALBUM_MORE_AWARD then
        if _contentId ~= nil then
            extraData["saleIndex"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.OUTSIDECAVE_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.BLIND_BOX_SALE then
        if _contentId ~= nil then
            extraData["saleIndex"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.JEWELMANIASALE then
        -- if _contentId ~= nil then
            local mgr = G_GetMgr(ACTIVITY_REF.JewelMania)
            local lastBuyType = mgr:getLastBuyType()
            extraData["jewelManiaSaleType"] = lastBuyType
        -- end
    elseif _lastBuyType == BUY_TYPE.DRAGON_CHALLENGE_PASS_UNLOCK then
        if _contentId ~= nil and 
         _activityId ~= nil then
            --参数多个 用p_activityId 补一个参数
            extraData["passSeq"] = _activityId
            extraData["pack"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.BROKENSALEV2 then
        if _contentId ~= nil then
           extraData["saleIndex"] = _contentId
       end
    elseif _lastBuyType == BUY_TYPE.LUCKY_CHALLENGEV2_REFRESHSALE_BUY then
        if _contentId ~= nil then
            extraData["saleIndex"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.FUNCTION_SALE_INFINITE then
        if _contentId ~= nil then
            extraData["selectIndex"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.ROUTINE_SALE then
        if _contentId ~= nil then
            extraData["index"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.EGYPT_COINPUSHER_SALE then
        if _activityId ~= nil and _contentId ~= nil then
            extraData["buyItems"] = tostring(_contentId)
        end
    elseif globalData.iapRunData.p_lastBuyType == BUY_TYPE.SIDEKICKS_LEVEL_SALE then
        if globalData.iapRunData.p_contentId ~= nil then
            extraData["sidekicksLevel"] = globalData.iapRunData.p_contentId
        end
    elseif _lastBuyType == BUY_TYPE.HOLIDAY_NEW_STORE_SALE then
        if _contentId ~= nil then
            extraData["holidaySaleKey"] = _contentId
        end
    elseif _lastBuyType == BUY_TYPE.BUCK then
        if _contentId ~= nil then
            extraData["buckIndex"] = _contentId
        end    
    elseif globalData.iapRunData.p_lastBuyType == BUY_TYPE.DIYFEATURE_SALE then
        if globalData.iapRunData.p_contentId ~= nil then
            extraData["DiyFeatureSaleItem"] = globalData.iapRunData.p_contentId
        end
    end

    --增加位置信息
    if self.m_entryInfo and self.m_entryInfo.entryType then
        extraData["entryType"] = self.m_entryInfo.entryType
    end
    --是否是quest关卡
    local entryStatus = "Normal"
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig and questConfig.m_IsQuestLogin then
        if questConfig:isNewUserQuest() then
            entryStatus = "NewQuest"
        else
            if questConfig:getThemeName() == "Activity_QuestIsland" then
                entryStatus = "islandQuestGame"
            else
                entryStatus = "QuestGame"
            end
        end
    end

    extraData["entryStatus"] = entryStatus
end

-- csc 2021-07-06 11:00:21 添加新的付费打点参数
function LogIap:setIsBuDan(bool) --设置是否是补单
    self.m_buDan = bool
end

function LogIap:getIsBuDan(bool) --设置是否是补单
    return self.m_buDan
end

function LogIap:getEntryData()
    return self.m_entryData --购买时发给服务器购买入口信息，发完之后马上清空
end

function LogIap:clearEntryData()
    self.m_entryData = nil
end

return LogIap
