-- Created by jfwang on 2019-05-05.
-- 多档促销
--

local TryPayView = class("TryPayView", util_require("base.BaseView"))
TryPayView.maxCount = 3

function TryPayView:initUI(callback)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self.m_callback = callback
    local csbName = "TryPay/TryPayLayer.csb"

    local promotion = G_GetActivityDataByRef(ACTIVITY_REF.AttemptSale) or {}
    if not promotion then
        return
    end
    self.m_saleMultiple = promotion:getSalesData()

    self:createCsbNode(csbName, isAutoScale)
    if isAutoScale and globalData.slotRunData.isPortrait == true then
        util_csbScale(self.m_csbNode, 0.56)
    end

    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(
            root,
            function()
                if self.isClose then
                    return
                end
                self:runCsbAction("idle", false)
            end
        )
    else
        self:runCsbAction(
            "show",
            false,
            function()
                if self.isClose then
                    return
                end
                self:runCsbAction("idle", false)
            end,
            60
        )
    end

    self:initView()
end

function TryPayView:initView()
    local data = self.m_saleMultiple
    if data and #data >= self.maxCount then
        for i = 1, self.maxCount do
            self:initViewData(i, data[i])
        end
    end
    -- self:initLuckyStampNode()
end
function TryPayView:initLuckyStampNode(callback)
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if not data then
        if callback then
            callback()
        end
        return
    end
    local tipNode = G_GetMgr(G_REF.LuckyStamp):createLuckyStampTip(nil, true, false)
    if tipNode then
        self:addChild(tipNode)
        tipNode:setPosition(display.cx, 60)
    end
end
function TryPayView:initViewData(index, data)
    local m_lb_original = self:findChild("m_lb_original" .. "_" .. index)
    local m_lb_coins = self:findChild("m_lb_coins" .. "_" .. index)
    local m_lb_price = self:findChild("m_lb_price" .. "_" .. index)
    local m_lb_more = self:findChild("m_lb_more" .. "_" .. index)
    local m_lb_vipPoint = self:findChild("m_lb_vipPoint" .. "_" .. index)
    local m_node_pb = self:findChild("node_pb_" .. index)

    m_lb_original:setString("WAS " .. util_getFromatMoneyStr(data.p_originalCoins))
    m_lb_coins:setString(util_getFromatMoneyStr(data.p_coins))
    self:updateLabelSize({label = m_lb_coins}, 588)

    m_lb_price:setString("$" .. data.p_price)
    if data.p_discounts ~= -1 then
        m_lb_more:setString("+" .. data.p_discounts .. "%")
    end
    self:createCellPBNode(m_node_pb, index, data)
    -- m_lb_vipPoint:setString("+ "..util_getFromatMoneyStr(data.p_vipPoint).." VIP POINTS")
end

function TryPayView:createCellPBNode(node, index, data)
    local pbNode =
        util_createView(
        "views.TryPay.TryPayNode",
        index,
        data,
        function(index, data)
            self:pbCallBack(index, data)
        end
    )
    node:addChild(pbNode)
end

function TryPayView:pbCallBack(index, data)
    if not self.m_tips then
        self.m_tips = self:createShopTips(index, data)
    end
    self:showTips(index)
end

function TryPayView:showTips(index)
    -- self.m_tips
    local baseNode = self:findChild("node")
    local parentNode = self:findChild("node_" .. index)
    local m_node_pb = self:findChild("node_pb_" .. index)
    local pos = cc.pAdd(cc.p(parentNode:getPosition()), cc.p(m_node_pb:getPosition()))
    self.m_tips:setPosition(cc.pAdd(pos, cc.p(70, -40)))
    if not self.m_maskUI then
        self.m_maskUI = util_newMaskLayer("test")
        baseNode:addChild(self.m_maskUI, 1)
        self.m_maskUI:setPosition(-display.cx, -display.cy)
        self.m_maskUI:setOpacity(170)
    end
    self.m_maskUI:setScale(5)
    self.m_maskUI:setVisible(true)

    if not self.m_maskSpthen then
        if index == 3 then
            self.m_maskSpthen = util_createSprite("TryPay/other/detial2.png")
            baseNode:addChild(self.m_maskSpthen, 1)
            self.m_maskSpthen:setPosition(cc.pAdd(pos, cc.p(0, -93)))
        else
            self.m_maskSpthen = util_createSprite("TryPay/other/detial1.png")
            baseNode:addChild(self.m_maskSpthen, 1)
            self.m_maskSpthen:setPosition(cc.pAdd(pos, cc.p(0, -93)))
        end
    end
end
function TryPayView:hideTips(index)
    if self.m_maskUI then
        self.m_maskUI:setVisible(false)
    end
    if self.m_maskSpthen then
        self.m_maskSpthen:removeFromParent()
        self.m_maskSpthen = nil
    end
end
--提示信息
function TryPayView:createShopTips(index, saleData)
    local view = util_createView("views.TryPay.TryPayTip", saleData, 1, nil, true)
    local baseNode = self:findChild("node")
    baseNode:addChild(view, 2)
    view:setCallFunc(
        function()
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self.m_tips = nil
            self:hideTips(index)
        end
    )
    if globalData.slotRunData.isPortrait == true then
        view:setScale(1.2)
        view.m_rootNode:setPositionX(130)
        view:findChild("bg"):setPositionX(-360)
    end
    return view
end

--获取数据
function TryPayView:getSaleData(index)
    if index > 0 and index <= self.maxCount then
        local data = self.m_saleMultiple
        if data and #data >= self.maxCount then
            return data[index]
        end
    end

    return nil
end

function TryPayView:buySale(index)
    local m_saleData = self:getSaleData(index)
    if m_saleData == nil then
        return
    end
    local rate = 0
    if m_saleData.p_discounts > 0 then
        rate = m_saleData.p_discounts
    end
    local goodsInfo = {}
    goodsInfo.goodsId = m_saleData.p_key
    goodsInfo.goodsPrice = m_saleData.p_price
    goodsInfo.discount = m_saleData.p_discounts
    goodsInfo.totalCoins = m_saleData.p_coins
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)

    local purchaseInfo = {}
    purchaseInfo.purchaseStatus = "site" .. index
    gLobalSendDataManager:getLogIap():setPurchaseInfo(purchaseInfo)

    self:findChild("btn_buy" .. "_" .. index):setTouchEnabled(false)
    self.m_clickBtnName = "btn_buy" .. "_" .. index
    gLobalSaleManager:purchaseActivityGoods(
        m_saleData.p_activityId,
        m_saleData.p_id,
        BUY_TYPE.ATTEMPT,
        m_saleData.p_key,
        m_saleData.p_price,
        m_saleData.p_coins,
        rate,
        function()
            if self.buySuccess ~= nil then
                self:buySuccess(index)
            end
        end,
        function()
            if self.buyFailed ~= nil then
                self:buyFailed(index)
            end
        end
    )
end

--购买成功提示界面
function TryPayView:buySuccess(index)
    local m_saleData = self:getSaleData(index)
    if m_saleData == nil then
        return
    end

    self.m_callback = nil

    local levelUpNum = gLobalSaleManager:getLevelUpNum()
    local view = util_createView("GameModule.Shop.BuyTip")
    if gLobalSendDataManager.getLogPopub then
        if not self.m_clickBtnName then
            self.m_clickBtnName = "loseBtn"
        end
        gLobalSendDataManager:getLogPopub():addNodeDot(view, self.m_clickBtnName, DotUrlType.UrlName, false)
    end
    view:initBuyTip(BUY_TYPE.ATTEMPT, m_saleData, m_saleData.p_originalCoins, levelUpNum)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    self:closeUI()
end

function TryPayView:buyFailed(index)
    self:findChild("btn_buy" .. "_" .. index):setTouchEnabled(true)
end

function TryPayView:onKeyBack()
    self:closeUI(true)
end

function TryPayView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- 尝试重新连接 network
    if name == "btn_buy_1" then
        self:buySale(1)
    elseif name == "btn_buy_2" then
        self:buySale(2)
    elseif name == "btn_buy_3" then
        self:buySale(3)
    elseif name == "btn_close" then
        self:closeUI(true)
    end
end
function TryPayView:onEnter()
    local goodsInfo = {}
    goodsInfo.goodsTheme = "TryPayView"
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "normalBuy"
    purchaseInfo.purchaseName = "attempSale"
    purchaseInfo.purchaseStatus = "noSelect"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end
function TryPayView:closeUI(isLog)
    if self.isClose then
        return
    end
    self.isClose = true
    local callBack = function()
        if isLog then
            gLobalSendDataManager:getLogIap():closeIapLogInfo()
        end
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)

        if self.m_callback then
            self.m_callback()
        end
        self:removeFromParent()

        -- gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
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
end

return TryPayView
