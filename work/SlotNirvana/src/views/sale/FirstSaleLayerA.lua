--[[
    A组首充
]]
local FirstSaleLayerA = class("FirstSaleLayerA", BaseLayer)

function FirstSaleLayerA:initDatas(_params, _data)
    self.m_saleData = _data
    self.p_params = _params or {}
    self.m_triggerPosition = self.p_params.pos or "Stroe"
    self.m_saleData:setBuyPosition(self.m_triggerPosition)
    -- 是否需要弹出广告
    self.m_closePlayAds = self.p_params.playAds or false

    local csbTheme = "Promotion/FirstCommonSale_normal"
    if globalData.constantData.FIRST_COMMON_SALE_SPECIAL_THEME then
        csbTheme = "Promotion/FirstCommonSale_special"
    end 
    self:setPortraitCsbName(csbTheme .. "/Activity/csb/FirstTimeSale_shu.csb")
    self:setLandscapeCsbName(csbTheme .. "/Activity/csb/FirstTimeSale.csb")
    self.m_csbTheme = csbTheme

    self:setPauseSlotsEnabled(true)
end

function FirstSaleLayerA:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    self.m_nodeAdsBubble = self:findChild("node_qipao")
    self.m_node_spine = self:findChild("Node_spine")

    -- self.m_nodeTime = self:findChild("sp_time_bottom")
    -- self.m_lb_time = self:findChild("txt_time")
    self.m_nodeTime = self:findChild("node_time")
    if globalData.constantData.FIRST_COMMON_SALE_HIDE_TIME then
        self.m_nodeTime:setVisible(false)
    end
    self.m_lb_time = self:findChild("lb_time")

    self.m_sp_coin = self:findChild("sp_coin")
    self.m_lb_coin = self:findChild("txt_coin")
    -- self.m_label_oldprice = self:findChild("txt_coin2")
    -- self.m_label_newprice = self:findChild("txt_coin1")
    -- self.m_lb_decs = self:findChild("txt_purchase_desc")
    -- self.m_sp_scribe = self:findChild("sp_scribe")
    -- self.m_txt_promo_desc = self:findChild("txt_promo_desc")

    self.m_title_1 = self:findChild("sp_title2")
    self.m_title_1:setVisible(false)

    self.m_node_promo = self:findChild("node_promo")
    self.m_lb_promo = self:findChild("lb_promo")
end

function FirstSaleLayerA:initView()
    self:initFirstView()
    self:initBubbleNode()
    -- self:initSpine()
end

function FirstSaleLayerA:initFirstView()
    local LanguageKey = "FirstSaleLayer:FirstSalePrice"
    local refStr = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "ONLY $ "
    self:setButtonLabelContent("btn_buy", refStr .. self.m_saleData.p_price)
    -- self.m_label_newprice:setString("$" .. self.m_saleData.p_initDollars)
    -- self.m_label_oldprice:setString("$" .. self.m_saleData.p_dollars)

    self.m_lb_coin:setString(util_formatMoneyStr(self.m_saleData.p_coins))
    self:updateLabelSize({label = self.m_lb_coin, sx = self.m_lb_coin:getScaleX(), sy = self.m_lb_coin:getScaleY()}, 650)


    local uiList = {
        {node = self.m_sp_coin},
        {node = self.m_lb_coin, alignX = 8}
    }
    util_alignCenter(uiList)

    --新首冲增加道具奖励
    local nodeReward = self:findChild("node_reward")
    local showItems = self:getShowSaleDataItems()
    if #showItems > 0 and not G_GetMgr(G_REF.FirstCommonSale):getIsFirst() then
        local itemParent = self:findChild("node_item")
        itemParent:removeAllChildren()
        local itemNode = gLobalItemManager:addPropNodeList(showItems, ITEM_SIZE_TYPE.TOP)
        itemParent:addChild(itemNode)
        nodeReward:setVisible(true)
    else
        nodeReward:setVisible(false)
    end

    if self.m_saleData.p_price == self.m_saleData.p_dollars then
        self.m_node_promo:setVisible(false)
    else
        -- local dis = math.floor((1 - tonumber(self.m_saleData.p_price)/tonumber(self.m_saleData.p_dollars)) * 100)
        -- self.m_lb_promo:setString("-" .. dis .. "%")
        self.m_lb_promo:setString("$" .. self.m_saleData.p_dollars)
    end

    -- 判断当前是否是没钱促销的情况下
    if self.m_saleData:isNoCoins() then
        self.m_nodeTime:setVisible(false)
        if self:isShownAsPortrait() then
            -- self.m_label_oldprice:setPositionY(self.m_label_oldprice:getPositionY() + 40)
            -- self.m_label_newprice:setPositionY(self.m_label_newprice:getPositionY() + 40)
            -- self.m_lb_decs:setPositionY(self.m_lb_decs:getPositionY() + 40)
            -- self.m_txt_promo_desc:setPositionY(self.m_txt_promo_desc:getPositionY() + 40)
        end
    else
        local firstCommSaleData = G_GetMgr(G_REF.FirstCommonSale):getData()
        self.m_lb_time:setString(util_count_down_str(firstCommSaleData:getLeftTime()))
        schedule(
            self,
            function()
                firstCommSaleData = G_GetMgr(G_REF.FirstCommonSale):getData()
                if firstCommSaleData then
                    self.m_lb_time:setString(util_count_down_str(firstCommSaleData:getLeftTime()))
                    if firstCommSaleData:getLeftTime() <= 0 then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FIRST_SALE_BUYSUCCESS)
                        self:closeUI()
                    end
                else
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FIRST_SALE_BUYSUCCESS)
                    self:closeUI()
                end
            end,
            0.5
        )
    end

    self:updateBtnBuck()
end

function FirstSaleLayerA:updateBtnBuck()
    -- local buyType = BUY_TYPE.SPECIALSALE  
    -- self:setBtnBuckVisible(self:findChild("btn_buy"), buyType)
end

function FirstSaleLayerA:initBubbleNode()
    local isShowAdsBubble = globalData.adsRunData:isInterstitialAds()
    if isShowAdsBubble then
        if not self.m_adsBubble then
            self.m_adsBubble = util_createView("views.sale.BasicSaleAdsBubble")
            self.m_nodeAdsBubble:addChild(self.m_adsBubble)
        end
    end
end

-- function FirstSaleLayerA:initSpine()
--     local csbTheme = "Promotion/FirstCommonSale_normal"
--     if globalData.constantData.FIRST_COMMON_SALE_SPECIAL_THEME then
--         csbTheme = "Promotion/FirstCommonSale_special"
--     end 
--     self.m_spine = util_spineCreate(csbTheme .. "/Activity/spine/chaopiao", false, true)
--     self.m_node_spine:addChild(self.m_spine)
--     self.m_spine:setVisible(false)
-- end

------------新增提示功能
function FirstSaleLayerA:openBPInfoLayer()
    --常规促销默认没有道具
    local itemlist = self:getShowSaleDataItems()
    G_GetMgr(G_REF.PBInfo):showPBInfoLayer(self.m_saleData, itemlist)
end

function FirstSaleLayerA:buySale()
    if self.isClose then
        return
    end
    local rate = 0
    if self.m_saleData.p_discounts > 0 then
        rate = self.m_saleData.p_discounts
    end
    local buyType = BUY_TYPE.SPECIALSALE
    if self.m_saleData.p_duration == 0 then
        buyType = BUY_TYPE.NOCOINSSPECIALSALE
    end

    -- 只要当前是 促销首充的购买都发送这个事件 ，不区分是否为 普通 或者 没钱
    buyType = BUY_TYPE.SPECIALSALE_FIRST

    gLobalSaleManager:setBuyVippoint(self.m_saleData.p_vipPoint)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(self.m_saleData)
    gLobalSendDataManager:getLogIap():setItemList(itemList)

    gLobalSaleManager:purchaseGoods(
        buyType,
        self.m_saleData.p_key,
        self.m_saleData.p_price,
        self.m_saleData.p_coins,
        rate,
        function()
            if self.buySuccess then
                self:buySuccess()
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
            end
        end,
        function(_errorInfo)
            if self.buyFailed then
                self:buyFailed(_errorInfo)
            end
        end
    )
end

function FirstSaleLayerA:buySuccess()
    --购买成功提示界面
    self.m_isBuy = true
    local levelUpNum = gLobalSaleManager:getLevelUpNum()
    local view = util_createView("GameModule.Shop.BuyTip")
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_buy", DotUrlType.UrlName, false)
    end
    local buyType = BUY_TYPE.SPECIALSALE
    if self.m_noCoinsData then
        buyType = BUY_TYPE.NOCOINSSPECIALSALE
    end
    -- 只要当前是 促销首充的购买都发送这个事件 ，不区分是否为 普通 或者 没钱
    buyType = BUY_TYPE.SPECIALSALE_FIRST

    -- 需要删掉数据
    G_GetMgr(G_REF.FirstCommonSale):deleteFirstSaleData()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FIRST_SALE_BUYSUCCESS)

    view:initBuyTip(buyType, self.m_saleData, self.m_saleData.p_originalCoins, levelUpNum)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    G_GetMgr(G_REF.FirstCommonSale):setIsFirst()
    self:closeUI()
end

function FirstSaleLayerA:buyFailed(_errorInfo)
    local view = self:checkPopPayConfirmLayer(_errorInfo)
    if not view then
        self:findChild("btn_buy"):setTouchEnabled(true)
    end
end

function FirstSaleLayerA:checkPopPayConfirmLayer(_errorInfo)
    if not _errorInfo or not _errorInfo.bCancel then
        -- 非用户自主取消 返回
        return
    end

    local payCoins = self.m_saleData.p_coins
    local priceV = self.m_saleData.p_price
    local params = {
        coins = payCoins,
        price = priceV,
        confirmCB = function()
            if not tolua.isnull(self) then
                self:buySale()
            end
        end,
        cancelCB = function()
            if not tolua.isnull(self) then
                self:findChild("btn_buy"):setTouchEnabled(true)
            end
        end
    }

    -- 正常弹出
    if not self.m_saleData:isNoCoins() then
        params.expireAt = self.m_saleData:getExpireAt()
    end

    local view = G_GetMgr(G_REF.PaymentConfirm):showPayCfmLayer(params)
    return view
end

function FirstSaleLayerA:onKeyBack()
    if self:isShowing() or self:isHiding() then
        return
    end
    
    self:closeUI(true)
end

function FirstSaleLayerA:clickFunc(sender)
    if self.m_isNotCanTouch then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()
    -- 尝试重新连接 network
    if name == "btn_buy" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        sender:setTouchEnabled(false)
        self:buySale()
    elseif name == "btn_close" then
        self:closeUI(true)
    elseif name == "btn_pb" then
        self:openBPInfoLayer()
    end
end

function FirstSaleLayerA:onEnter()
    FirstSaleLayerA.super.onEnter(self)
    if not self.m_saleData then
        return
    end

    local goodsInfo = {}
    goodsInfo.goodsTheme = "FirstSaleLayerA"
    goodsInfo.goodsId = self.m_saleData.p_key
    goodsInfo.goodsPrice = self.m_saleData.p_price
    goodsInfo.discount = self.m_saleData.p_discounts
    goodsInfo.totalCoins = self.m_saleData.p_coins
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "normalBuy"
    purchaseInfo.purchaseName = "FirstSuperSale"
    purchaseInfo.purchaseStatus = tostring(self.m_saleData.p_dollars)

    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

function FirstSaleLayerA:closeUI(isLog, resultData)
    if self.isClose then
        return
    end
    self.isClose = true
    local triggerPosition = self.m_triggerPosition

    local callBack = function()
        if isLog then
            gLobalSendDataManager:getLogIap():closeIapLogInfo()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_DELUEXECLUB_VIEWS)
        end
        -- 需要把激励视频弹窗加入到队列里
        if self.m_closePlayAds == true then
            --
            self.m_closePlayAds = false
            if not gLobalPushViewControl:isPushingView() then -- 如果之后没有弹窗了..
                if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.CloseSale) then
                    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.CloseSale)
                    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
                    gLobalAdsControl:playVideo(AdsRewardDialogType.Normal, PushViewPosType.CloseSale)
                    gLobalSendDataManager:getLogAds():createPaySessionId()
                    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.CloseSale)
                    gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
                end
            else
                if self.p_params.callback then
                    self.p_params.callback()
                else
                    -- 弹窗逻辑执行下一个事件
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                    if self.m_saleData:isNoCoins() then
                        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
                    elseif triggerPosition ~= "Login" then
                        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                    end
                end
            end
        else
            if self.p_params.callback then
                self.p_params.callback()
            else
                -- 弹窗逻辑执行下一个事件
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                if self.m_saleData:isNoCoins() then
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
                elseif triggerPosition ~= "Login" then
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end
            end
        end

        if not self.m_isBuy then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYTIP_CLOSE)
        end
    end

    FirstSaleLayerA.super.closeUI(self, callBack)
end

function FirstSaleLayerA:registerListener()
    FirstSaleLayerA.super.registerListener(self)

    gLobalNoticManager:addObserver(
        self,
        function()
            self:findChild("btn_buy"):setTouchEnabled(true)
        end,
        ViewEventType.NOTIFY_ACTIVITY_PURCHASING_CLOSE
    )
end

function FirstSaleLayerA:playShowAction()
    if globalData.constantData.FIRST_COMMON_SALE_SPECIAL_THEME then
        -- 特殊的使用通用弹板弹出动画
        self:runCsbAction("idle", true, nil, 60)
        FirstSaleLayerA.super.playShowAction(self)
        return
    end 

    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    local userDefAction = function(callFunc)
        -- self.m_spine:setVisible(true)
        -- util_spinePlay(self.m_spine, "start", false)

        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    util_setCascadeOpacityEnabledRescursion(self, true)
    FirstSaleLayerA.super.playShowAction(self, userDefAction)
end

function FirstSaleLayerA:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
    if self.m_adsBubble then
        self.m_adsBubble:playStart()
    end
end

function FirstSaleLayerA:getUnLock()
    local isf = false
    if G_GetMgr(G_REF.CardNovice) and G_GetMgr(G_REF.CardNovice):isNoviceCardSys() then
        local unLockLevel = globalData.constantData.NEW_CARD_OPEN_LEVEL or 5
        if globalData.userRunData.levelNum >= unLockLevel then
            isf = true
        end
    end
    return isf
end

-- 获取限时 道具
function FirstSaleLayerA:getShowSaleDataItems()
    local items = self.m_saleData.p_items or {}
    local showItems = {}
    for _, shopItem in ipairs(items) do
        if string.find(shopItem.p_icon, "Card") or string.find(shopItem.p_icon, "card") or string.find(shopItem.p_icon, "Rank") then
            if self:getUnLock() then
                table.insert(showItems, shopItem)
            end
        else
            table.insert(showItems, shopItem)
        end
    end

    return showItems
end

return FirstSaleLayerA
