--[[
   购买付费轮盘弹窗
]]
local DailybonusBuyView = class("DailybonusBuyView", util_require("base.BaseView"))

DailybonusBuyView.m_buyCallFun = nil
DailybonusBuyView.m_closeCallFun = nil
DailybonusBuyView.m_getJackpotAddValue = nil

function DailybonusBuyView:initUI(buyCallFun, closeCallFun, getJackpotAddValue, coins, multipleValue, price)
    self:createCsbNode("Hourbonus_new3/DailybonusBuyLayer.csb")
    self:findChild("spinnow"):setTouchEnabled(false)
    self:findChild("close"):setTouchEnabled(false)
    self.m_buyCallFun = buyCallFun
    self.m_closeCallFun = closeCallFun
    self.m_getJackpotAddValue = getJackpotAddValue

    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    self:runCsbAction(
        "pull",
        false,
        function()
            self:runCsbAction("idle", true)
            self:findChild("spinnow"):setTouchEnabled(true)
            self:findChild("close"):setTouchEnabled(true)
        end
    )

    local jcakpotLb = self:findChild("LabelCoin")
    jcakpotLb:setString(util_formatCoins(coins, 14))
    self:updateLabelSize({label = jcakpotLb, sx = 0.7, sy = 0.7}, 575)

    local mulLb = self:findChild("LabelMulitip")
    mulLb:setString("x" .. multipleValue)

    local priceLb = self:findChild("LabelDollar")
    if priceLb then
        local key_fixed = "DailybonusBuyView:price_fixed"
        local str_pre = gLobalLanguageChangeManager:getStringByKey(key_fixed)
        priceLb:setString(str_pre .. price)
    end

    self:updateBtnBuck()
end

function DailybonusBuyView:updateBtnBuck()
    local buyType = BUY_TYPE.CASHBONUS_TYPE_NEW
    self:setBtnBuckVisible(self:findChild("spinnow"), buyType)
end

function DailybonusBuyView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "spinnow" then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.RoulettePaymentOrder2)
        end
        self:findChild("spinnow"):setTouchEnabled(false)
        self:findChild("close"):setTouchEnabled(false)
        self:buyWheelPay()
    elseif name == "close" then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.RoulettePaymentClose2)
        end
        self:findChild("spinnow"):setTouchEnabled(false)
        self:findChild("close"):setTouchEnabled(false)
        self:runCsbAction("idle", false)
        self:stopAllActions()

        gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
        self:runCsbAction(
            "stop",
            false,
            function()
                if tolua.isnull(self) then
                    return
                end
                gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusViewClose.mp3")
                if self.m_closeCallFun then
                    self.m_closeCallFun()
                end
                self:removeFromParent()
            end
        )
    end
end

function DailybonusBuyView:buyWheelPay()
    local jp_data = self.m_getJackpotAddValue()
    G_GetMgr(G_REF.CashBonus):setJackpotData(jp_data)

    local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    local buyRase = 0 ---翻倍
    local iapId = wheelPayData.p_key
    local price = wheelPayData.p_price
    local totalCoins = wheelPayData.p_value
    self.m_randomIndex = wheelPayData:getResultCoinIndex()

    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(wheelPayData)
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.CASHBONUS_TYPE_NEW,
        iapId,
        price,
        totalCoins,
        buyRase,
        function()
            if self.buySuccessCallFun then
                self:buySuccessCallFun()
            end
        end,
        function()
            if self.buyFaildCallFun then
                self:buyFaildCallFun()
            end
        end
    )
end

-- 购买成功
function DailybonusBuyView:buySuccessCallFun()
    gLobalSendDataManager:getLogIap():setAddCoins(totalCoins)
    local goodsInfo = {}
    goodsInfo.totalCoins = totalCoins
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    G_GetMgr(G_REF.CashBonus):setJackpotData(0)
    gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
    self:runCsbAction(
        "over",
        false,
        function()
            if tolua.isnull(self) then
                return
            end
            gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusViewClose.mp3")
            --走支付流程
            if self.m_buyCallFun then
                self.m_buyCallFun()
            end
            self:removeFromParent()
        end
    )
end

-- 购买失败
function DailybonusBuyView:buyFaildCallFun()
    self:findChild("spinnow"):setTouchEnabled(true)
    self:findChild("close"):setTouchEnabled(true)
    G_GetMgr(G_REF.CashBonus):setJackpotData(0)
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.Roulette_purchase_failed1)
    end
end
return DailybonusBuyView
