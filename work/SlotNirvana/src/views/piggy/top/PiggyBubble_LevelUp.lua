--[[--
    每次小猪升档提示框
]]
local BasePiggyBubble = util_require("views.piggy.top.BasePiggyBubble")
local PiggyBubble_LevelUp = class("PiggyBubble_LevelUp", BasePiggyBubble)

function PiggyBubble_LevelUp:initDatas()
    PiggyBubble_LevelUp.super.initDatas(self)
    self:setName("PiggyBubble_LevelUp")
end

function PiggyBubble_LevelUp:initCsbNodes()
    self.m_btnBuy = self:findChild("btn_buy")
    self.m_btnFree = self:findChild("btn_free")
    -- 降档
    self.m_nodeWasPrice = self:findChild("node_was")
    self.m_lbWasPrice = self:findChild("lb_was")
    self.m_spWasLine = self:findChild("sp_was")
    local wasLineSize = self.m_spWasLine:getContentSize()
    self.m_spWasLineHeight = wasLineSize.height
end

function PiggyBubble_LevelUp:getAutoCloseTime()
    return globalData.constantData.PIG_SHOW_TIME or 5
end

function PiggyBubble_LevelUp:getCsbName()
    if globalData.slotRunData.isMachinePortrait then
        return "PigBankTip/PigTipNodePortiart.csb"
    end
    return "PigBankTip/PigTipNode.csb"
end

function PiggyBubble_LevelUp:initUI()
    PiggyBubble_LevelUp.super.initUI(self)
    self:initCoins()
end

function PiggyBubble_LevelUp:initCoins()
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    if not data then
        return
    end

    local saleRate = G_GetMgr(G_REF.PiggyBank):getPiggySaleRate()
    if saleRate and saleRate > 0 then
        self.m_totalCoins = data.p_coins + data.p_coins * saleRate / 100
    else
        self.m_totalCoins = data.p_coins
    end

    self.m_vipPoint = data.p_vipPoint

    self.m_sp_coins = self:findChild("m_sp_coins")
    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_totalCoins))

    util_alignCenter(
        {
            {
                node = self.m_sp_coins,
                scale = 0.6
            },
            {
                node = self.m_lb_coins,
                scale = 0.4,
                alignX = 10
            }
        }
    )

    -- self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_totalCoins))
    -- self:updateLabelSize({label = self.m_lb_coins, scale = 0.4}, 310)
    -- local width = math.min(310, self.m_lb_coins:getContentSize().width) * 0.5
    -- local posx, posy = self.m_lb_coins:getPosition()
    -- self.m_sp_coins:setPosition(posx - width - 35, posy)

    -- 按钮显示价格
    local LanguageKey = "PiggyBubble_LevelUp:btn_buy"
    local refStr = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "BREAK FOR $%s"
    local str = string.format(refStr, data.p_price or 0)
    self:setButtonLabelContent("btn_buy", str)

    if data:isFree() then
        self.m_btnFree:setVisible(true)
        self.m_btnBuy:setVisible(false)
    else
        self.m_btnFree:setVisible(false)
        self.m_btnBuy:setVisible(true)
        -- 升降档
        if data:isLevelDown() then
            self.m_nodeWasPrice:setVisible(true)
            local wasPrice = data:getValuePrice()
            self.m_lbWasPrice:setString("WAS $" .. wasPrice)
            local lbWasPriceSize = self.m_lbWasPrice:getContentSize()
            self.m_spWasLine:setContentSize(cc.size(lbWasPriceSize.width + 10, self.m_spWasLineHeight))
        else
            self.m_nodeWasPrice:setVisible(false)
        end
    end

    data:setPriceData(tonumber(data.p_valuePrice))

    self:updateBtnBuck()
end

function PiggyBubble_LevelUp:updateBtnBuck()
    local buyType = BUY_TYPE.PIGGYBANK_TYPE  
    self:setBtnBuckVisible(self:findChild("btn_buy"), buyType)
end

function PiggyBubble_LevelUp:clickFunc(sender)
    local name = sender:getName()

    self:clearAutoCloseTimer()
    if self:isGoodWheelReconnect() then
        -- 小猪转盘不累加，需要直接进入小猪主界面把上一次的轮盘消耗掉
        G_GetMgr(G_REF.PiggyBank):showMainLayer()
        self:closeUI()
        return
    end
    if name == "btn_buy" then
        self:buyPiggy()
    elseif name == "btn_free" then
        self:buyFree()
    end
end

function PiggyBubble_LevelUp:isGoodWheelReconnect()
    local data = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getRunningData()
    if data and data:checkIsReconnectPop() then
        return true
    end
    return false
end

function PiggyBubble_LevelUp:buyPiggy()
    if self.isClose then
        return
    end
    if self.m_isOpenPiggy then
        return
    end
    self.m_isOpenPiggy = true
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    if not piggyBankData then
        return
    end
    piggyBankData:setRewardCoin(self.m_totalCoins)

    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(piggyBankData)
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.PIGGYBANK_TYPE,
        piggyBankData.p_productKey,
        piggyBankData.p_price,
        self.m_totalCoins,
        0,
        function()
            if not tolua.isnull(self) then
                self:buySuccess()
            end
        end,
        function(_errorInfo)
            if not tolua.isnull(self) then
                -- 检查 是否是玩家主动取消并去弹出 挽留弹板
                local view = self:checkPopPayConfirmLayer(_errorInfo)
                if not view then
                    -- 没有弹出二次确认弹板 真正失败所做的事
                    self:buyFail()
                end                
            end
        end
    )
end

function PiggyBubble_LevelUp:buySuccess()
    G_GetMgr(G_REF.PiggyBank):showMainLayer({type = "collect", totalCoins = self.m_totalCoins, vipPoint = self.m_vipPoint})
    self:closeUI()
end

-- 支付失败
function PiggyBubble_LevelUp:buyFail()
    if not tolua.isnull(self) then
        self.m_isOpenPiggy = false
        self:closeUI()
    end 
end

-- 检查是否弹出 二次确认弹板
function PiggyBubble_LevelUp:checkPopPayConfirmLayer(_errorInfo)
    if not _errorInfo or not _errorInfo.bCancel then
        -- 非用户自主取消 返回
        return
    end
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    if not piggyBankData then
        return
    end
    local params = {
        coins = self.m_totalCoins, --弹板需要显示的金币数量
        price = piggyBankData.p_price, --弹板需要显示的价格
        confirmCB = function()
            -- 确认按钮点击 重新发起支付
            if not tolua.isnull(self) then
                self:buyPiggy(true)
            end
        end,
        cancelCB = function()
            -- 取消按钮点击，真正支付失败
            if not tolua.isnull(self) then
                self:buyFail()
            end
        end
    }
    local view = G_GetMgr(G_REF.PaymentConfirm):showPayCfmLayer(params)
    return view
end

function PiggyBubble_LevelUp:buyFree()
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    if not piggyBankData then
        return
    end
    piggyBankData:setRewardCoin(self.m_totalCoins)

    G_GetMgr(G_REF.PiggyBank):buyFree()
end

function PiggyBubble_LevelUp:buyFreeCallBack()
    G_GetMgr(G_REF.PiggyBank):showMainLayer({type = "collect", totalCoins = self.m_totalCoins, vipPoint = self.m_vipPoint, isFree = true})
    self:closeUI()
end

function PiggyBubble_LevelUp:onEnter()
    PiggyBubble_LevelUp.super.onEnter(self)

    self:setIapLog()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_CLOSE_PIG_TIPS
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params then
                self:buyFreeCallBack(params.isSuc)
            end
        end,
        ViewEventType.PIGGY_BANK_BUY_FREE
    )
    gLobalNoticManager:addObserver(
        self,
        function()
            if not tolua.isnull(self) then
                self:buyFail()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_PURCHASING_CLOSE
    )
end

function PiggyBubble_LevelUp:setIapLog()
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    if not piggyBankData then
        return
    end
    local upperRate = 0
    local bOnCommonSale = false
    local bClanSaleData = false
    local pigCoins = G_GetMgr(ACTIVITY_REF.PigCoins):getRunningData()
    if pigCoins then
        upperRate = pigCoins:getPiggyCommonSaleParam()
        bOnCommonSale = pigCoins:beingOnPiggyCommonSale()
    else
        local clanSaleData = G_GetMgr(ACTIVITY_REF.PigClanSale):getRunningData() -- 公会小猪折扣
        if clanSaleData and clanSaleData:isRunning() then
            bClanSaleData = true
            upperRate = clanSaleData:getDiscount()
        end
    end
    local goodsInfo = {}
    goodsInfo.goodsTheme = "PiggyBubble_LevelUp"
    goodsInfo.goodsId = piggyBankData.p_productKey
    goodsInfo.goodsPrice = piggyBankData.p_price
    goodsInfo.discount = upperRate
    goodsInfo.totalCoins = self.m_totalCoins

    local purchaseInfo = {}
    purchaseInfo.purchaseType = "pig"
    if bOnCommonSale then
        purchaseInfo.purchaseName = LOG_IAP_ENMU.purchaseName.pigSale --
        purchaseInfo.purchaseStatus = upperRate
    elseif bClanSaleData then
        purchaseInfo.purchaseName = LOG_IAP_ENMU.purchaseName.PigClanSale -- 公会小猪折扣
        purchaseInfo.purchaseStatus = upperRate
    else
        purchaseInfo.purchaseName = LOG_IAP_ENMU.purchaseName.pigBank --
        purchaseInfo.purchaseStatus = "normal"
    end
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

function PiggyBubble_LevelUp:closeUI(_over)
    PiggyBubble_LevelUp.super.closeUI(self, _over)
end

return PiggyBubble_LevelUp
