local BrokenSaleCell = class("BrokenSaleCell", BaseView)

function BrokenSaleCell:getCsbName()
    if self._delegate:isShownAsPortrait() then
        return "BrokenSale/csd/BrokenSale_coin_shu.csb"
    else
        return "BrokenSale/csd/BrokenSale_coin_heng.csb"
    end
end

function BrokenSaleCell:ctor(data)
    self._index = data.index
    self._delegate = data.delegate
    BrokenSaleCell.super.ctor(self)
    self:refreshUI()
end

function BrokenSaleCell:initUI(data)
    BrokenSaleCell.super.initUI(self)
    --more
    local nodeMore = self:findChild("node_more")
    local pNodeMore = cc.p(nodeMore:getPosition())
    local parent = nodeMore:getParent()
    nodeMore:removeFromParent()

    util_csbPlayForKey(self.m_csbAct, "idle", true, nil, 60)
end

--刷新UI
function BrokenSaleCell:refreshUI(data)
    if not data then
        return
    end
    self._data = data

    --当前获得金箔 金币sp位置
    local lb_coin = self:findChild("lb_coin")
    lb_coin:setString(util_getFromatMoneyStr(self._data:getCoins()))
    local width = lb_coin:getContentSize().width
    local scale = math.min(0.36,671/width*0.36)
    lb_coin:setScale(scale)
    
    --以前获得金币 line长度
    local oldCoin = self:findChild("lb_coin_delete")
    local line = self:findChild("sp_line")
    oldCoin:setString(util_getFromatMoneyStr(self._data:getOriginalCoins())):setScale(scale/0.36)
    line:setContentSize(cc.size(self:findChild("lb_coin_delete"):getContentSize().width + 8,3)):setScale(scale/0.36)
    oldCoin:setVisible(false)
    line:setVisible(false)
    --金币icon位置
    local posx = lb_coin:getPositionX()
    self:findChild("sp_coin"):setPositionX(posx - width * scale / 2 - 77/2/2):setScale(scale*5/3.6)
    --当前价钱
    self:findChild("label_1"):setString("$"..self._data:getPrice())
    --金币堆sp
    for i = 1,3 do
        self:findChild("sp_coins"..i):setVisible(i == self._index)
    end
end

function BrokenSaleCell:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "btn_pay" then
        sender:setTouchEnabled(false)
        self:buySale()
    elseif name == "btn_benefit" then
        local view = util_createView(SHOP_CODE_PATH.ShopBenefitLayer,{p_price = self._data:getPrice()})
        gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
    end
end

function BrokenSaleCell:buySale()
    self:doLog()
    gLobalSaleManager:setBuyVippoint(self._data:getVipPoint())

    local rate = 0
    if self._data._discount > 0 then
        rate = self._data._discount
    end
    local buyType = BUY_TYPE.BROKENSALE2

    gLobalSaleManager:purchaseGoods(
        buyType,
        self._data:getKey(),
        self._data:getPrice(),
        tonumber(self._data:getCoins()),
        rate,
        function()
            if not tolua.isnull(self) then
                self:buySuccess()
            end
        end,
        function(_errorInfo)
            if not tolua.isnull(self) then
                self:buyFailed(_errorInfo)
            end
        end
    )
end

function BrokenSaleCell:buySuccess()
    local levelUpNum = gLobalSaleManager:getLevelUpNum()
    local buyType = BUY_TYPE.BROKENSALE2

    local view = util_createView("GameModule.Shop.BuyTip")
    view:initBuyTip(buyType, self._data:makeDataForBuyTip(), tonumber(self._data:getCoins()), levelUpNum)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)

    self._delegate:closeLayer()
end

function BrokenSaleCell:buyFailed(_errorInfo)
    local view = self:checkPopPayConfirmLayer(_errorInfo)
    if not view then
        self:findChild("btn_pay"):setTouchEnabled(true)
    end
end

-- 检查是否弹出 二次确认弹板
function BrokenSaleCell:checkPopPayConfirmLayer(_errorInfo)
    if not _errorInfo or not _errorInfo.bCancel then
        -- 非用户自主取消 返回
        return
    end

    local data = G_GetActivityDataByRef(ACTIVITY_REF.BrokenSale)
    if not data then
        return
    end

    local saleData = data:getSaleItemByIndex(self._index)
    if not saleData then
        return
    end

    local payCoins = saleData:getCoins()
    local priceV = saleData:getPrice()
    local params = {
        coins = payCoins,
        price = priceV,
        confirmCB = function()
            self._data = saleData
            self:buySale()
        end,
        cancelCB = function()
            self:findChild("btn_pay"):setTouchEnabled(true)
        end
    }
    local view = G_GetMgr(G_REF.PaymentConfirm):showPayCfmLayer(params)
    return view
end

function BrokenSaleCell:onEnter()
    BrokenSaleCell.super.onEnter(self)
    if not self._data then
        return
    end

    self:doLog()
end

function BrokenSaleCell:doLog()
    local goodsInfo = {}
    goodsInfo.goodsTheme = "BrokenSaleCell"
    goodsInfo.goodsId = self._data._keyId
    goodsInfo.goodsPrice = self._data._price
    goodsInfo.discount = self._data._discount
    goodsInfo.totalCoins = self._data._coins
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "normalBuy"
    purchaseInfo.purchaseName = "noCoinsSpecialSale_"..tostring(self._index)
    purchaseInfo.purchaseStatus = "noCoinsSpecialSale"

    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

return BrokenSaleCell