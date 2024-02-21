--[[
    金币面板
]]
local PBMainCoinBoardNode = class("PBMainCoinBoardNode", BaseView)

function PBMainCoinBoardNode:getCsbName()
    if globalData.slotRunData.isPortrait == true then
        return "PigBank2022/csb/main/PBCoinBoard_Portrait.csb"
    end
    return "PigBank2022/csb/main/PBCoinBoard.csb"
end

function PBMainCoinBoardNode:initDatas()
    -- 小猪网络数据
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    self.m_iprice = piggyBankData.p_price
    self.m_iCollectCoin = toLongNumber(piggyBankData.p_coins)
    self.m_vipPoint = piggyBankData.p_vipPoint

    self.m_couponRate = G_GetMgr(G_REF.PiggyBank):getCouponRate()
    self.m_couponExpireAt = piggyBankData.p_expireAt
end

function PBMainCoinBoardNode:initCsbNodes()
    self.m_node_coin = self:findChild("node_coin")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coins")
    self.m_nodeDelCoin = self:findChild("node_delCoin")
    self.m_lbDelCoin = self:findChild("lb_coins_del")
    self.m_spDelLine = self:findChild("delete_line")
    -- 小猪优惠券
    self.m_nodeCoupon = self:findChild("node_coupon")
    self.m_btnBuy = self:findChild("btn_buy")
    self.m_btnFree = self:findChild("btn_free")
    -- 降档
    self.m_nodeWasPrice = self:findChild("node_was")
    self.m_lbWasPrice = self:findChild("lb_was")
    self.m_spWasLine = self:findChild("sp_was")
    local wasLineSize = self.m_spWasLine:getContentSize()
    self.m_spWasLineHeight = wasLineSize.height
end

function PBMainCoinBoardNode:initUI(_buyCallFunc, _buyFreeCallFunc)
    self.m_buyCallFunc = _buyCallFunc
    self.m_buyFreeCallFunc = _buyFreeCallFunc
    PBMainCoinBoardNode.super.initUI(self)
    self:initView()
    self:runCsbAction("idle", true, nil, 60)
end

function PBMainCoinBoardNode:initView()
    self:initCoins()
    self:initCoupon()
    self:initBtnContent()
    self:initBtnVisible()
    self:initNoviceDiscount()
    self:updateBtnBuck()
end

function PBMainCoinBoardNode:updateBtnBuck()
    local buyType = BUY_TYPE.PIGGYBANK_TYPE  
    self:setBtnBuckVisible(self:findChild("btn_buy"), buyType)
end

function PBMainCoinBoardNode:initCoins()
    local baseCoins = self.m_iCollectCoin
    local saleRate = G_GetMgr(G_REF.PiggyBank):getPiggySaleRate()
    if saleRate and saleRate > 0 then
        baseCoins = self.m_iCollectCoin * (1 + saleRate / 100)
        self.m_nodeDelCoin:setVisible(false)
        self.m_lbDelCoin:setString(util_getFromatMoneyStr(self.m_iCollectCoin))
        self:updateLabelSize({label = self.m_lbDelCoin}, globalData.slotRunData.isPortrait == true and 510 or 360)
        self.m_lbCoin:setString(util_getFromatMoneyStr(baseCoins))
        -- 删除线长度适配
        local lbDelSize = self.m_lbDelCoin:getContentSize()
        local lbDelScaleX = self.m_lbDelCoin:getScaleX()
        local spDelSize = self.m_spDelLine:getContentSize()
        local offsetX = 10 -- 删除线比数字长一点点
        self.m_spDelLine:setContentSize(cc.size(lbDelSize.width * lbDelScaleX + offsetX, spDelSize.height))
    else
        self.m_nodeDelCoin:setVisible(false)
        self.m_lbCoin:setString(util_getFromatMoneyStr(baseCoins))
    end
    self.m_factor = 1
    local timeLimitExpansion = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion)
    if timeLimitExpansion then
        self.m_factor = self.m_factor + timeLimitExpansion:getExpansionRatio()
    end
    
    self.m_curCoins = toLongNumber(baseCoins * (1 / self.m_factor))
    self.m_lbCoin:setString(util_getFromatMoneyStr(self.m_curCoins))

    if self.m_factor > 1 then
        gLobalNoticManager:addObserver(
            self,
            function()
                self:carnivalCoinsAction()
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_TIMELIMITEXPANSION_LOGOLAYER_CLOSE)
            end,
            ViewEventType.NOTIFY_TIMELIMITEXPANSION_LOGOLAYER_CLOSE
        )
    end
    self:alignCoins()
end

function PBMainCoinBoardNode:alignCoins()
    local UIList = {}
    local limitWidth = nil
    if globalData.slotRunData.isPortrait == true then
        table.insert(UIList, {node = self.m_spCoin, scale = 0.95, anchor = cc.p(0.5, 0.5)})
        table.insert(UIList, {node = self.m_lbCoin, scale = 0.65, anchor = cc.p(0.5, 0.5), alignX = 3, alignY = 1})
        limitWidth = 580
    else
        table.insert(UIList, {node = self.m_spCoin, scale = 0.7, anchor = cc.p(0.5, 0.5)})
        table.insert(UIList, {node = self.m_lbCoin, scale = 0.5, anchor = cc.p(0.5, 0.5), alignX = 3, alignY = 1})
        limitWidth = 430
    end
    util_alignCenter(UIList, nil, limitWidth)
end

function PBMainCoinBoardNode:carnivalCoinsAction()
    if self.m_factor > 1 then
        local baseCoins = self.m_iCollectCoin
        local saleRate = G_GetMgr(G_REF.PiggyBank):getPiggySaleRate()
        if saleRate and saleRate > 0 then
            baseCoins = self.m_iCollectCoin * (1 + saleRate / 100)
        end
        local interval = 1 / 30
        local rolls = 33
        local curStep = toLongNumber(baseCoins - self.m_curCoins) * (1 / rolls)

        self.m_scheduleId =
            schedule(
            self,
            function()
                self.m_curCoins = LongNumber.min(self.m_curCoins + curStep, baseCoins)
                self.m_lbCoin:setString(util_getFromatMoneyStr(self.m_curCoins))
                self:alignCoins()
                if toLongNumber(self.m_curCoins) >= toLongNumber(baseCoins) then
                    if self.m_scheduleId then
                        self:stopAction(self.m_scheduleId)
                        self.m_scheduleId = nil
                    end
                end
            end,
            interval
        )

        local _ts = (rolls + 2) * interval
        local _action = {}
        _action[1] = cc.EaseBackInOut:create(cc.ScaleTo:create(_ts, 1.2))
        _action[2] = cc.ScaleTo:create(0.1, 1)
        _action[3] =
            cc.CallFunc:create(
            function()
                self:playBaoZaAction()
            end
        )
        self.m_node_coin:runAction(cc.Sequence:create(_action))
    end
end

function PBMainCoinBoardNode:playBaoZaAction()
    local sp = util_createAnimation(SHOP_RES_PATH.CoinLizi)
    if sp then
        self.m_node_coin:addChild(sp, 10)
        sp:playAction(
            "start",
            false,
            function()
                sp:removeFromParent()
            end,
            60
        )
    end
end

--小猪优惠券
function PBMainCoinBoardNode:initCoupon()
    self.m_couponNode = util_createView("views.piggy.main.PBMainCouponNode")
    self.m_nodeCoupon:addChild(self.m_couponNode)
end

function PBMainCoinBoardNode:initBtnContent()
    self:setButtonLabelContent("btn_buy", "BREAK FOR $" .. (self.m_iprice or 0))
end

function PBMainCoinBoardNode:initBtnVisible()
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    if data and data:isFree() then
        self.m_btnFree:setVisible(true)
        self.m_btnBuy:setVisible(false)
    else
        self.m_btnFree:setVisible(false)
        self.m_btnBuy:setVisible(true)
        -- 升降档
        if data and data:isLevelDown() then
            self.m_nodeWasPrice:setVisible(false)
            local wasPrice = data:getValuePrice()
            self.m_lbWasPrice:setString("WAS $" .. wasPrice)
            local lbWasPriceSize = self.m_lbWasPrice:getContentSize()
            self.m_spWasLine:setContentSize(cc.size(lbWasPriceSize.width + 10, self.m_spWasLineHeight))
        else
            self.m_nodeWasPrice:setVisible(false)
        end
    end
end

-- 小猪 的新手折扣
function PBMainCoinBoardNode:initNoviceDiscount()
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    local isIn = false
    if data and data:isUnlock() and data:checkInNoviceDiscount() then
        isIn = true
    end
    if not isIn then
        return
    end
    
    local parent = self:findChild("node_1st_more")
    if not parent then
        return
    end

    local view = util_createView("views.piggy.main.PBMainNoviceFirstSaleTipNode")
    parent:addChild(view)
end

function PBMainCoinBoardNode:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_buy" then
        if self.m_buyCallFunc then
            self.m_buyCallFunc()
        end
    elseif name == "btn_free" then
        if self.m_buyFreeCallFunc then
            self.m_buyFreeCallFunc()
        end
    end
end

function PBMainCoinBoardNode:updateCoins()
    -- 小猪网络数据
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    self.m_iCollectCoin = toLongNumber(piggyBankData.p_coins)

    local baseCoins = self.m_iCollectCoin
    local saleRate = G_GetMgr(G_REF.PiggyBank):getPiggySaleRate()
    if saleRate and saleRate > 0 then
        baseCoins = self.m_iCollectCoin * (1 + saleRate / 100)
        self.m_nodeDelCoin:setVisible(false)
        self.m_lbDelCoin:setString(util_getFromatMoneyStr(self.m_iCollectCoin))
        self:updateLabelSize({label = self.m_lbDelCoin}, globalData.slotRunData.isPortrait == true and 510 or 360)
        self.m_lbCoin:setString(util_getFromatMoneyStr(baseCoins))
        -- 删除线长度适配
        local lbDelSize = self.m_lbDelCoin:getContentSize()
        local lbDelScaleX = self.m_lbDelCoin:getScaleX()
        local spDelSize = self.m_spDelLine:getContentSize()
        local offsetX = 10 -- 删除线比数字长一点点
        self.m_spDelLine:setContentSize(cc.size(lbDelSize.width * lbDelScaleX + offsetX, spDelSize.height))
    else
        self.m_nodeDelCoin:setVisible(false)
        self.m_lbCoin:setString(util_getFromatMoneyStr(baseCoins))
    end
end

function PBMainCoinBoardNode:onEnter()
    PBMainCoinBoardNode.super.onEnter(self)

    if self.m_couponRate and self.m_couponRate > 0 then
        local updateTime = function()
            local strLeftTime, isOver = util_daysdemaining((self.m_couponExpireAt or 0) / 1000, true)
            if isOver then
                self.m_couponNode:stopAllActions()
                self.m_couponNode:initCoupon()
                self:updateCoins()
            end
        end
        util_schedule(self.m_couponNode, updateTime, 1)
        updateTime()
    end
end

return PBMainCoinBoardNode
