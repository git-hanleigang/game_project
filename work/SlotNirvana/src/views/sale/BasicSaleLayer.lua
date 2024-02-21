local saleConfig = util_require("data.baseDatas.SaleItemConfig")
local BasicSaleLayer = class("BasicSaleLayer", BaseLayer)
-- FIX IOS 139 3

function BasicSaleLayer:initDatas()
    self.m_isVipLevel = nil
    self.m_miniGameUsd = 0 -- 常规促销小游戏金币价值

    self.m_noCoinsData = G_GetActivityDataByRef(ACTIVITY_REF.NoCoinSale)

    self:setPortraitCsbName("Sale_A/BaiscSaleLayer.csb")
    self:setLandscapeCsbName("Sale/BaiscSaleLayer.csb")

    self:setPauseSlotsEnabled(true)
end

function BasicSaleLayer:initUI(data)
    local triggerPosition = "Stroe"
    --服务器打点没什么大用还的留着、
    if data and data.pos then
        triggerPosition = data.pos
    end

    self.m_triggerPosition = triggerPosition

    --暂时没用 标识vip升级时候弹出的促销
    if data and data.isVipLevel then
        self.m_isVipLevel = true
    end

    --没钱弹出的非限制促销
    if self.m_noCoinsData then
        self.m_noCoinsData:setBuyPosition(triggerPosition)
        self.m_saleData = self.m_noCoinsData
        self.m_miniGameUsd = self.m_noCoinsData:getMiniGameUsd()
    else
        local commSaleData = G_GetMgr(G_REF.SpecialSale):getRunningData()
        if commSaleData then
            commSaleData:setBuyPosition(triggerPosition)
            self.m_saleData = clone(commSaleData)
            self.m_miniGameUsd = commSaleData:getMiniGameUsd()
        end
    end

    if not self.m_saleData then
        self.m_isShowActionEnabled = false
        self.m_isHideActionEnabled = false
        self:closeUI()
        self:setVisible(false)
        return
    end

    BasicSaleLayer.super.initUI(self)

    -- 是否需要弹出广告
    self.m_closePlayAds = false
    if data and data.playAds then
        self.m_closePlayAds = data.playAds
    end

    if not self.m_noCoinsData then
        globalData.slotRunData:checkViewAutoClick(self)
    end

    self:setExtendData("BasicSaleLayer")
end

function BasicSaleLayer:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    self.m_lb_original = self:findChild("m_lb_original")
    self.sp_original_delete = self:findChild("sp_original_delete")
    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_nodeTime = self:findChild("node_daojishi")
    self.m_lb_time = self:findChild("m_lb_time")
    self.m_lb_more = self:findChild("m_lb_more")
    self.m_lb_originalWas = self:findChild("m_lb_originalWas")
end

function BasicSaleLayer:initView()
    self:initCommonView()
end

function BasicSaleLayer:initCommonView()
    self.m_lb_original:setString(util_getFromatMoneyStr(self.m_saleData.p_originalCoins))
    self.m_lb_original:setVisible(false)
    -- 按钮显示价格
    -- self.m_lb_price:setString("ONLY $" .. self.m_saleData.p_price)
    local LanguageKey = "BasicSaleLayer:btn_buy"
    local refStr = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "ONLY $%s"
    local str = string.format(refStr, self.m_saleData.p_price or 0)
    self:setButtonLabelContent("btn_buy", str)

    self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_saleData.p_coins))

    self:adaptDelelteLine()

    local spCoin = self:findChild("sp_coin")
    local UIList = {}
    local limitWidth = 0
    if globalData.slotRunData.isPortrait == true then
        UIList[#UIList + 1] = {node = spCoin, scale = 1.12, anchor = cc.p(0.5, 0.5)}
        UIList[#UIList + 1] = {node = self.m_lb_coins, scale = 0.89, anchor = cc.p(0.5, 0.5), alignX = 1}
        limitWidth = 700
    else
        UIList[#UIList + 1] = {node = spCoin, scale = 1.17, anchor = cc.p(0.5, 0.5)}
        UIList[#UIList + 1] = {node = self.m_lb_coins, scale = 0.97, anchor = cc.p(0.5, 0.5), alignX = 1}
        limitWidth = 780
    end
    util_alignCenter(UIList, nil, limitWidth)

    local image_coinsBg = self:findChild("image_coinsBg")
    if self.m_saleData.p_discounts <= 0 then
        -- 没有折扣
        image_coinsBg:setVisible(false)
        local originalNode = self:findChild("node_wasCoinNum")
        if originalNode then
            originalNode:setVisible(false)
        end
    else
        -- 有折扣
        self.m_lb_more:setString("+" .. self.m_saleData.p_discounts .. "%")
        self:updateLabelSize({label = self.m_lb_more, sx = 1.1, sy = 1.1}, 100)
    end
    local timeLine = self:findChild("sp_time_line")
    if timeLine then
        timeLine:setVisible(false)
    end

    if self.m_noCoinsData and self.m_noCoinsData.p_duration == 0 then
        self.m_nodeTime:setVisible(false)
        if timeLine then
            timeLine:setVisible(true)
        end
        local Image_4 = self:findChild("Image_4")
        if Image_4 then
            Image_4:setVisible(false)
        end
    else
        local commSaleData = G_GetMgr(G_REF.SpecialSale):getRunningData()
        if commSaleData then
            if commSaleData:getLeftTime() <= 0 then
                self.m_nodeTime:setVisible(false)
                if timeLine then
                    timeLine:setVisible(true)
                end
            end

            self.m_lb_time:setString(util_count_down_str(commSaleData:getLeftTime()))
            schedule(
                self,
                function()
                    local commSaleData = G_GetMgr(G_REF.SpecialSale):getRunningData()
                    if commSaleData then
                        self.m_lb_time:setString(util_count_down_str(commSaleData:getLeftTime()))
                        if commSaleData:getLeftTime() <= 0 then
                            self:closeUI()
                        end
                    else
                        self:closeUI()
                    end
                end,
                0.5
            )
        end
    end

    -- 常规促销 小游戏
    self:initLuckyChooseUI()

    -- self:updateBtnBuck()
end

function BasicSaleLayer:updateBtnBuck()
    local buyType = BUY_TYPE.SPECIALSALE  
    self:setBtnBuckVisible(self:findChild("btn_buy"), buyType, nil, {{node = self:findChild("btn_buy"):getChildByName("ef_zi"):getChildByName("label_1"), addX = 20}})
end

-- 常规促销 小游戏
function BasicSaleLayer:initLuckyChooseUI()
    local nodeLuckyChoose = self:findChild("node_luckyChoose")
    if tolua.isnull(nodeLuckyChoose) then
        return
    end

    nodeLuckyChoose:setVisible(false)
    if tonumber(self.m_miniGameUsd) <= 0 then
        return
    end

    nodeLuckyChoose:setVisible(true)
    local lbMoney = self:findChild("lb_money")
    lbMoney:setString("$" .. self.m_miniGameUsd)
    self:updateLabelSize({label = lbMoney, sx = 1, sy = 1}, 38)

    -- 给manager设置小游戏最高奖励的 金币价值
    local luckyChooseManager = util_require("manager/System/LuckyChooseManager"):getInstance()
    luckyChooseManager:setMaxRewardCoinsPrice(self.m_miniGameUsd)
end

-- 根据文字适配红色删除线
function BasicSaleLayer:adaptDelelteLine()
    -- local textSize = self.m_lb_original:getContentSize()
    -- local textPos = cc.p(self.m_lb_original:getPosition())
    -- local wasSize = self.m_lb_originalWas:getContentSize()
    -- self.m_lb_originalWas:setPositionX(textPos.x - textSize.width / 2 - 10 - wasSize.width / 2)
    -- local size = self.sp_original_delete:getContentSize()
    -- self.sp_original_delete:setContentSize({width = textSize.width, height = size.height})
    -- self.sp_original_delete:setPositionX(textPos.x)
    self.sp_original_delete:setVisible(false)
    self:findChild("m_lb_originalWas"):setVisible(false)
end

------------新增提示功能
function BasicSaleLayer:initBPInfoNode()
    --常规促销默认没有道具
    local itemlist = {}
    --商品附带道具
    if self.m_saleData.p_items ~= nil and #self.m_saleData.p_items > 0 then
        for i = 1, #self.m_saleData.p_items do
            itemlist[#itemlist + 1] = self.m_saleData.p_items[i]
        end
    end

    G_GetMgr(G_REF.PBInfo):showPBInfoLayer(self.m_saleData, itemlist)
end

function BasicSaleLayer:buySale()
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
            if not tolua.isnull(self) then
                self:buySuccess()
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
            end
        end,
        function(_errorInfo)
            if not tolua.isnull(self) then
                -- 检查 是否是玩家主动取消并去弹出 挽留弹板
                local view = self:checkPopPayConfirmLayer(_errorInfo)
                if not view then
                    -- 没有弹出二次确认弹板 真正失败所做的事
                    self:buyFailed()
                end
            end
        end
    )
end

function BasicSaleLayer:buySuccess()
    local toDayTime = util_getymd_format()
    gLobalDataManager:setStringByField("ToDayFristBuySale", toDayTime)
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

    view:initBuyTip(buyType, self.m_saleData, self.m_saleData.p_originalCoins, levelUpNum)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)

    self:closeUI()
end

function BasicSaleLayer:buyFailed()
    self:findChild("btn_buy"):setTouchEnabled(true)
end


-- 检查是否弹出 二次确认弹板
function BasicSaleLayer:checkPopPayConfirmLayer(_errorInfo)
    if not _errorInfo or not _errorInfo.bCancel then
        -- 非用户自主取消 返回
        return
    end
    local params = {
        coins = self.m_saleData.p_coins, --弹板需要显示的金币数量
        price = self.m_saleData.p_price, --弹板需要显示的价格
        confirmCB = function()
            -- 确认按钮点击 重新发起支付
            if not tolua.isnull(self) then
                self:buySale(true)
            end
        end,
        cancelCB = function()
            -- 取消按钮点击，真正支付失败
            if not tolua.isnull(self) then
                self:buyFailed()
            end
        end
    }
    local view = G_GetMgr(G_REF.PaymentConfirm):showPayCfmLayer(params)
    return view
end

function BasicSaleLayer:onKeyBack()
    if self:isShowing() or self:isHiding() then
        return
    end
    self:closeUI(true)
end

function BasicSaleLayer:clickFunc(sender)
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
        self:initBPInfoNode()
    end
end

function BasicSaleLayer:onEnter()
    BasicSaleLayer.super.onEnter(self)

    self:updateBtnBuck()

    if not self.m_saleData then
        return
    end

    local goodsInfo = {}
    goodsInfo.goodsTheme = "BasicSaleLayer"
    goodsInfo.goodsId = self.m_saleData.p_key
    goodsInfo.goodsPrice = self.m_saleData.p_price
    goodsInfo.discount = self.m_saleData.p_discounts
    goodsInfo.totalCoins = self.m_saleData.p_coins
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "normalBuy"
    if self.m_saleData.p_duration == 0 then
        purchaseInfo.purchaseName = "noCoinsSpecialSale"
        purchaseInfo.purchaseStatus = self.m_saleData.p_discounts
    else
        purchaseInfo.purchaseName = "normalSale"
        local lastToDayTimeStr = gLobalDataManager:getStringByField("ToDayFristBuySale", "")
        local toDayTime = util_getymd_format()
        if lastToDayTimeStr == toDayTime then
            purchaseInfo.purchaseStatus = "normal"
        else
            purchaseInfo.purchaseStatus = "dayFrist"
        end
    end

    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

function BasicSaleLayer:playIdle()
    if util_csbActionExists(self.m_csbAct, "idle") then
        self:runCsbAction("idle", true, nil, 60)
    end
end

function BasicSaleLayer:showActionCallback()
    self:playIdle()
    BasicSaleLayer.super.showActionCallback(self)
end

function BasicSaleLayer:closeUI(isLog, resultData)
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
                --弹窗逻辑执行下一个事件
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                if triggerPosition ~= "Login" then
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end
            end
        else
            --弹窗逻辑执行下一个事件
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            if triggerPosition ~= "Login" then
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        end
        G_DelActivityDataByRef(ACTIVITY_REF.NoCoinSale)

        if not self.m_isBuy then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYTIP_CLOSE)
        end
    end

    BasicSaleLayer.super.closeUI(self, callBack)
end

function BasicSaleLayer:registerListener()
    BasicSaleLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(
        self,
        function()
            if not tolua.isnull(self) then
                self:buyFailed()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_PURCHASING_CLOSE
    )
end

return BasicSaleLayer