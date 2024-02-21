local BaseThemeSale = class("BaseThemeSale", util_require("base.BaseView"))
function BaseThemeSale:initUI(data)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    local csbName = self:getCsbName(data)
    local path = "Activity/" .. csbName .. "SaleLayer.csb"
    self:createCsbNode(path, isAutoScale)
    if globalData.slotRunData.isPortrait == true then
        util_csbScale(self.m_csbNode, 0.65)
    end
    self:initView(data)
    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(
            root,
            function()
            end
        )
    else
        self:runCsbAction("show")
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
end

--子类重写
function BaseThemeSale:getCsbName(data)
    local csbName = "BaseTheme"
    return csbName
end
--子类重写 宽度变化
function BaseThemeSale:updateCoins(coins, maxLen)
    self.m_lb_coins:setString(util_getFromatMoneyStr(coins))
    self:updateLabelSize({label = self.m_lb_coins}, maxLen)
    local width = math.min(588, self.m_lb_coins:getContentSize().width) * 0.5
    local posx, posy = self.m_lb_coins:getPosition()
    self.m_sp_coins:setPosition(posx - width - 60, posy)
end

function BaseThemeSale:initView(data)
    self.m_lb_original = self:findChild("m_lb_original")
    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_lb_price = self:findChild("m_lb_price")
    self.m_lb_more = self:findChild("m_lb_more")
    self.m_lb_vipPoint = self:findChild("m_lb_vipPoint")
    self.m_sp_coins = self:findChild("m_sp_coins")
    self.m_sp_original = self:findChild("sp_original")

    -- for i=1,#globalData.saleRunData.p_saleTheme do
    --     local themeData = globalData.saleRunData.p_saleTheme[i]
    --     if data.activityId == themeData.p_activityId then
    --         self.m_saleData = themeData
    --         break
    --     end
    -- end

    if not self.m_saleData then
        self:closeUI()
        return
    end

    self:updateCoins(self.m_saleData.p_coins, 588)
    self.m_lb_original:setString("WAS " .. util_getFromatMoneyStr(self.m_saleData.p_originalCoins))
    self.m_lb_price:setString("$" .. self.m_saleData.p_price)
    self.m_lb_more:setString("+" .. self.m_saleData.p_discounts .. "%")
    self.m_lb_vipPoint:setString("+ " .. util_getFromatMoneyStr(self.m_saleData.p_vipPoint) .. " VIP POINTS")
end

function BaseThemeSale:buySale()
    if self.isClose then
        return
    end
    local rate = 0
    if self.m_saleData.p_discounts > 0 then
        rate = self.m_saleData.p_discounts
    end
    gLobalSaleManager:purchaseActivityGoods(
        self.m_saleData.p_activityId,
        self.m_saleData.p_id,
        BUY_TYPE.THEME_TYPE,
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
        function()
            self:buyFailed()
        end
    )
end

function BaseThemeSale:buySuccess()
    --购买成功提示界面
    local levelUpNum = gLobalSaleManager:getLevelUpNum()
    local view = util_createView("GameModule.Shop.BuyTip")
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_buy", DotUrlType.UrlName, false)
    end
    view:initBuyTip(BUY_TYPE.THEME_TYPE, self.m_saleData, self.m_saleData.p_originalCoins, levelUpNum)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    self:closeUI()
end

function BaseThemeSale:buyFailed()
    -- self:closeUI()
    self:findChild("btn_buy"):setTouchEnabled(true)
end

function BaseThemeSale:onKeyBack()
    self:closeUI(true)
end

function BaseThemeSale:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- 尝试重新连接 network
    if name == "btn_buy" then
        sender:setTouchEnabled(false)
        self:buySale()
    elseif name == "btn_close" then
        self:closeUI(true)
    end
end
function BaseThemeSale:onEnter()
    local goodsInfo = {}
    goodsInfo.goodsTheme = self:getCsbName() .. "SaleLayer"
    goodsInfo.goodsId = self.m_saleData.p_key
    goodsInfo.goodsPrice = self.m_saleData.p_price
    goodsInfo.discount = self.m_saleData.p_discounts
    goodsInfo.totalCoins = self.m_saleData.p_coins
    -- themeSale
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "limitBuy"
    purchaseInfo.purchaseName = "themeSale"
    purchaseInfo.purchaseStatus = self:getCsbName() .. "Sale"
    local themeData = G_GetActivityDataByRef(ACTIVITY_REF.Theme)
    if themeData and #themeData == 1 then
        local strEndTime = themeData[1].p_end or ""
        purchaseInfo.purchaseStatus = self:getCsbName() .. strEndTime
    end
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end
function BaseThemeSale:closeUI(isLog)
    if self.isClose then
        return
    end
    self.isClose = true

    local callBack = function()
        if isLog then
            gLobalSendDataManager:getLogIap():closeIapLogInfo()
        end
        self:removeFromParent()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end
    local root = self:findChild("root")
    if root then
        self:commonHide(
            root,
            function()
                callBack()
            end
        )
    else
        self:runCsbAction(
            "over",
            false,
            function()
                callBack()
            end,
            60
        )
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
end

return BaseThemeSale
