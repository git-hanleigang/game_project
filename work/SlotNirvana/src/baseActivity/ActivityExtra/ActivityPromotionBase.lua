-- 活动促销 基类
local ActivityPromotionConfig = util_require("baseActivity.ActivityExtra.ActivityPromotionConfig")
local BaseView = util_require("base.BaseView")
local ActivityPromotionBase = class("ActivityPromotionBase", BaseView)

function ActivityPromotionBase:initUI(activity_type, data)
    self.data = data
    assert(activity_type, "ActivityPromotionBase 传入活动类型不能为空")
    self.activity_type = activity_type

    local config = ActivityPromotionConfig.config[activity_type]
    assert(config, "ActivityPromotionBase 配置不能为空")

    assert(config.promotion_ref, "ActivityPromotionBase 传入促销引用类型不能为空")
    self.promotion_ref = config.promotion_ref

    assert(config.buy_type, "ActivityPromotionBase 传入活动购买类型不能为空")
    self.buy_type = config.buy_type

    assert(config.items_num, "ActivityPromotionBase 传入促销档位数量不能为空")
    self.items_num = config.items_num

    if not self:activityIsRuning() then
        self:setVisible(false)
        if gLobalViewManager:isLobbyView() then
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
        util_afterDrawCallBack(
            function()
                if not tolua.isnull(self) then
                    self:removeFromParent()
                end
            end
        )
    end

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait then
        isAutoScale = false
    end

    if globalData.slotRunData.isPortrait then
        local source = self:getCsbForPortrlt()
        if source and string.len(source) > 0 then
            self:createCsbNode(source, isAutoScale)
            -- 竖版适配
            util_adaptLandscape(self.m_csbNode)
        else
            source = self:getCsbForLandscap()
            assert(source, "ActivityPromotionBase 横版资源缺失 " .. self.activity_type)
            -- 没有竖版资源 用横版资源替代 横版资源默认是一直有的
            self:createCsbNode(source, isAutoScale)
            util_portraitAdaptLandscape(self.m_csbNode)
        end
    else
        local source = self:getCsbForLandscap()
        self:createCsbNode(source, isAutoScale)
    end

    self:readNodes()

    -- 购买中
    self.bl_onBuy = false
    -- 选中了哪一档的标记
    self.sale_index = nil
    -- 记录选中档位的数据
    self.record_data = nil
end

-- 获取横版资源
function ActivityPromotionBase:getCsbForLandscap()
    assert(false, "子类需要重写这个方法 匹配横版资源")
end

-- 获取竖版资源
function ActivityPromotionBase:getCsbForPortrlt()
    assert(false, "子类需要重写这个方法 匹配竖版资源")
end

function ActivityPromotionBase:readNodes()
    self.root = self:findChild("root")
    assert(self.root, "缺少必要节点 root")
end

function ActivityPromotionBase:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self.bl_onBuy = false
            self:setTouchEnabled(true)
            self:onPurchaseFailed()
            release_print("========hl====ActivityPromotionBase====onEnter====touchEnabled====bl_onBuy", self:getTouchEnabled(), self.bl_onBuy)
        end,
        ViewEventType.NOTIFY_ACTIVITY_PURCHASING_CLOSE
    )

    -- 活动时效监听
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == self.promotion_ref or params.name == self.activity_type then
                self:removeFromParent()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    -- 暂停关卡轮盘
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    -- 打开界面就发
    self:sendIapLog()

    self:setTouchEnabled(false)
    if self.root then
        self:commonShow(
            self.root,
            function()
                self:setTouchEnabled(true)
            end
        )
    end
end

function ActivityPromotionBase:onExit()
    --if gLobalViewManager:isLevelView() == true then
    -- 恢复关卡轮盘
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)

    if self.data and not self.data.inEntry then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
    end
    --end

    -- 移除监听
    gLobalNoticManager:removeAllObservers(self)
end

function ActivityPromotionBase:setTouchEnabled(bl_enable)
    assert(type(bl_enable) == "boolean", "ActivityPromotionBase setTouchEnabled 参数错误 " .. tostring(bl_enable))
    self.m_touchEnabled = bl_enable
end

function ActivityPromotionBase:getTouchEnabled()
    return self.m_touchEnabled
end
-- 弹窗弹出就发
function ActivityPromotionBase:sendIapLog()
    local activity_data = self:getActivityData()
    if not activity_data then
        return
    end
    local config = ActivityPromotionConfig.config[self.activity_type]
    if not config then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    goodsInfo.goodsTheme = self.promotion_ref

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "limitBuy"
    purchaseInfo.purchaseName = config.purchaseNameTitle

    local purStatus = self:getLogPurchaseStatus()
    if not purStatus then
        return
    end
    purchaseInfo.purchaseStatus = purStatus
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

function ActivityPromotionBase:getActivityData()
    local activity_data = G_GetActivityDataByRef(self.activity_type)
    if activity_data == nil or activity_data:isRunning() == false then
        return
    end
    return activity_data
end

-- 打点日志：类型状态 获取
function ActivityPromotionBase:getLogPurchaseStatus()
    local activity_data = self:getActivityData()
    if not activity_data then
        return
    end
    assert(activity_data.getSequence, self.activity_type .. " 数据类需要定义 getSequence 函数获取当前是第几轮")
    assert(activity_data.getCurrent, self.activity_type .. " 数据类需要定义 getCurrent 函数获取当前是第几章节")
    return activity_data:getSequence() .. "-" .. activity_data:getCurrent()
end

function ActivityPromotionBase:getSaleData()
    local saleData = G_GetActivityDataByRef(self.promotion_ref)
    if not saleData then
        return nil
    end

    -- TODO 服务器没发这个数据 前端显示需要 手动填充的数值
    --手动增加club point 道具 (高倍场点数)
    local clubPoints = saleData:getClubPoints()
    if clubPoints == nil then
        saleData:setClubPoints(0)
        local purchaseData = gLobalItemManager:getCardPurchase(nil, saleData:getPrice())
        if purchaseData then
            saleData:setClubPoints(purchaseData.p_clubPoints)
        end
    end

    return saleData
end

function ActivityPromotionBase:activityIsRuning()
    if not self:getActivityData() then
        return false
    end

    local saleData = self:getSaleData()
    if not saleData then
        return false
    end

    return true
end

function ActivityPromotionBase:getSaleList()
    local sale_data = self:getSaleData()
    if not sale_data then
        return
    end

    if not sale_data.p_items or not next(sale_data.p_items) then
        return
    end

    local sale_list = {}

    local special = {}
    local common = {}
    for i, data in ipairs(sale_data.p_items) do
        if i <= self.items_num then
            table.insert(special, data)
        else
            table.insert(common, data)
        end
    end

    -- 记录公共信息
    local base_data = {}
    base_data.p_activityId = sale_data.p_activityId -- 活动id
    base_data.p_key = sale_data.p_key -- 购买档位
    base_data.p_id = sale_data.p_id -- 档位id
    base_data.p_buyType = self.buy_type -- 购买类型
    base_data.p_price = sale_data.p_price -- 购买价格
    base_data.p_fakePrice = sale_data.p_fakePrice -- 原价
    base_data.p_discounts = sale_data.p_discounts -- 折扣
    -- TODO 三选一购买 只有购买的buff不同 奖励的金币和道具都一样 所以放在公共信息里面 如果每个选项奖励的数值都不一样 需要服务器做区分
    base_data.p_originalCoins = sale_data.p_originalCoins
    -- 奖励原始金币
    base_data.p_coins = sale_data.p_coins -- 奖励金币
    if sale_data.p_coinsV2 and sale_data.p_coinsV2 ~= toLongNumber(0) then
        base_data.p_coins = toLongNumber(sale_data.p_coinsV2) -- 奖励金币
    end
    base_data.p_items = common -- 奖励道具
    base_data.p_vipPoint = sale_data.p_vipPoint -- vip点数奖励
    base_data.p_clubPoints = sale_data.p_clubPoints -- 高倍场点数
    base_data.p_dollars = sale_data.p_dollars
    base_data.p_isDownPrice = sale_data.p_isDownPrice

    for i, data in ipairs(special) do
        local meta = clone(base_data)
        meta.p_buyId = data.p_id -- 购买的道具id或buffid
        if data.p_type and data.p_type == "Buff" then
            meta.p_expire = data.p_buffInfo.buffExpire -- 过期时间
            meta.p_buffType = data.p_buffInfo.buffType -- buff类型
        elseif data.p_type and data.p_type == "Item" then
            meta.p_icon = data.p_icon -- 奖励图标
            meta.p_num = data.p_num -- 奖励数量
        end

        -- 购买需要发给服务器的数据
        table.insert(sale_list, i, meta)
    end
    return sale_list
end

-- bl_compose 是否组合物品id 服务器的同学要求把购买的奖励物品id都发给服务器 所以这里不再是一个id 而是一个id数组组成的字符串
function ActivityPromotionBase:buySale(idx, bl_compose,_type)
    if self.bl_onBuy then
        return
    end

    local sale_list = self:getSaleList()
    if not sale_list then
        return
    end

    local sale_data = sale_list[idx]
    if not sale_data then
        return
    end

    if bl_compose == nil then
        bl_compose = false
    end

    local p_buyType = sale_data.p_buyType
    if _type ~= nil then
        p_buyType = _type
    end

    self.bl_onBuy = true
    self:setSelectSaleIndex(idx)
    self:recordSelectSaleData()
    self:sendBuyLog(idx, p_buyType)

    local p_activityId = sale_data.p_activityId
    local p_id = sale_data.p_buyId
    if bl_compose == true then
        p_id = sale_data.p_buyId .. ";" .. tostring(sale_data.p_items[1].p_id)
    end
    
    local p_key = sale_data.p_key
    local p_price = sale_data.p_price
    local p_coins = sale_data.p_coins
    local p_discounts = sale_data.p_discounts
    if sale_data.p_vipPoint then
        gLobalSaleManager:setBuyVippoint(sale_data.p_vipPoint)
    end

    gLobalSaleManager:purchaseActivityGoods(
        p_activityId,
        p_id,
        p_buyType,
        p_key,
        p_price,
        p_coins,
        p_discounts,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PROMOTION_BUY_SUCCESS, {refName = self.activity_type, saleIndex = self.sale_index})
            if not tolua.isnull(self) then
                if self.m_useSpecialEnterType then
                    gLobalSendDataManager:getLogIap():setLastEntryType()
                end
                self.bl_onBuy = false
                self:onPurchaseSuccess()
            end
        end,
        function(_errorInfo)
            if not tolua.isnull(self) then
                self.bl_onBuy = false
                if _errorInfo and _errorInfo.bCancel then
                    local showCancel = self:onPurchaseCancel(idx, bl_compose)
                    if not showCancel then
                        self:onPurchaseFailed()
                    end
                else
                    self:onPurchaseFailed()
                end
            end
        end
    )
end

function ActivityPromotionBase:isBuying()
    return self.bl_onBuy
end

function ActivityPromotionBase:setSelectSaleIndex(idx)
    self.sale_index = idx
end

function ActivityPromotionBase:getSelectSaleIndex()
    return self.sale_index
end

function ActivityPromotionBase:recordSelectSaleData()
    local idx = self:getSelectSaleIndex()
    if not idx then
        return
    end
    local sale_list = self:getSaleList()
    if not sale_list then
        return
    end

    self.record_data = clone(sale_list[idx])
end

function ActivityPromotionBase:getSelectSaleData()
    return self.record_data
end

-- 购买时发送
function ActivityPromotionBase:sendBuyLog(idx, buyType)
    local activity_data = self:getActivityData()
    if not activity_data then
        return
    end
    local config = ActivityPromotionConfig.config[self.activity_type]
    if not config then
        return
    end

    local sale_list = self:getSaleList()
    if not sale_list or not sale_list[idx] then
        return
    end

    local sale_data = sale_list[idx]
    if not sale_data then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    goodsInfo.goodsTheme = self.promotion_ref
    goodsInfo.goodsId = sale_data.p_key
    goodsInfo.goodsPrice = sale_data.p_price
    goodsInfo.discount = sale_data.p_discounts
    goodsInfo.totalCoins = sale_data.p_coins

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "limitBuy"
    purchaseInfo.purchaseName = config.purchaseNameTitle .. idx

    assert(activity_data.getSequence, self.activity_type .. " 数据类需要定义 getSequence 函数获取当前是第几轮")
    assert(activity_data.getCurrent, self.activity_type .. " 数据类需要定义 getCurrent 函数获取当前是第几章节")

    local purStatus = self:getLogPurchaseStatus()
    if not purStatus then
        return
    end
    purchaseInfo.purchaseStatus = purStatus
    self.m_useSpecialEnterType = false
    if self:getExtendData() == "Promotion_Word" then
        self.m_useSpecialEnterType = true
        gLobalSendDataManager:getLogIap():setEntryType("Word")
    elseif self:getExtendData() == "Promotion_CoinPusher" then
        self.m_useSpecialEnterType = true
        gLobalSendDataManager:getLogIap():setEntryType("Pusher")
    elseif self:getExtendData() == "Promotion_Blast" then
        self.m_useSpecialEnterType = true
        if buyType == BUY_TYPE.NEWBLAST_SALE then
            gLobalSendDataManager:getLogIap():setEntryType("NewBlast")
        else
            gLobalSendDataManager:getLogIap():setEntryType("Blast")
        end
    elseif self:getExtendData() == "Promotion_NewCoinPusher" then
        self.m_useSpecialEnterType = true
        gLobalSendDataManager:getLogIap():setEntryType("NewPusher")
    elseif self:getExtendData() == "Promotion_EgyptCoinPusher" then
        self.m_useSpecialEnterType = true
        gLobalSendDataManager:getLogIap():setEntryType("EgyptPusher")
    end
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, true, nil)
end

function ActivityPromotionBase:onPurchaseSuccess()
    assert("子类继承的方法 购买成功的处理逻辑")
end

function ActivityPromotionBase:onPurchaseFailed()
    assert("子类继承的方法 购买失败的处理逻辑")
end

function ActivityPromotionBase:onPurchaseCancel(idx, bl_compose)
    if self.bl_onBuy then
        return
    end

    local promotion_data = self:getSaleData()
    if not promotion_data then
        return
    end

    local sale_list = self:getSaleList()
    if not sale_list then
        return
    end

    local sale_data = sale_list[idx]
    if not sale_data then
        return
    end

    local p_price = sale_data.p_price
    local p_coins = sale_data.p_coins
    local p_endTime = promotion_data:getExpireAt()
    local params = {
        coins = p_coins,
        price = p_price,
        actRefName = self.promotion_ref,
        expireAt = p_endTime,
        confirmCB = function()
            if not tolua.isnull(self) then
                self:buySale(idx, bl_compose)
            end
        end,
        cancelCB = function()
            if not tolua.isnull(self) then
                self:onPurchaseFailed()
            end
        end
    }
    local view = G_GetMgr(G_REF.PaymentConfirm):showPayCfmLayer(params)
    if not view then
        if not tolua.isnull(self) then
            self:onPurchaseFailed()
        end
    end
    return true
end

function ActivityPromotionBase:closeUI(bl_showNext)
    if tolua.isnull(self) then
        return
    end

    if self.bl_onBuy then
        return
    end

    self:setTouchEnabled(false)

    local endCall = function()
        if gLobalViewManager:isLobbyView() then
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
    end
    if bl_showNext == nil then
        bl_showNext = true
    end
    if self.root then
        self:commonHide(
            self.root,
            function()
                if bl_showNext and endCall then
                    endCall()
                end
                self:removeFromParent()
            end
        )
    else
        if bl_showNext and endCall then
            endCall()
        end
        self:removeFromParent()
    end
end

function ActivityPromotionBase:closeUIAndStopPops()
    self:closeUI(false)
end

return ActivityPromotionBase
