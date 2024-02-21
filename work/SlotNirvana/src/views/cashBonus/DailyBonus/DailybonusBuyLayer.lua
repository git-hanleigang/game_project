--[[
   购买付费轮盘弹窗
]]
local DailybonusBuyLayer = class("DailybonusBuyLayer", BaseView)

function DailybonusBuyLayer:getCsbName()
    return "Hourbonus_new3/csd/DailyBonus_Buycell3.csb"
end

function DailybonusBuyLayer:initUI()
    DailybonusBuyLayer.super.initUI(self)

    local key_fixed = "DailybonusBuyLayer:btn_pay_fixed"
    local str_pre = gLobalLanguageChangeManager:getStringByKey(key_fixed)

    local wheel_data = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    if not wheel_data then
        return
    end

    local price_data = wheel_data:getPayData()
    if not price_data then
        return
    end
    local price1 = price_data[1].price
    local coins1 = tonumber(price_data[1].coinsShowMax)
    self.lb_coin1:setString(util_formatCoins(coins1, 6))
    util_alignCenter({{node = self.sp_coin1, alignX = 5}, {node = self.lb_coin1}})
    self:setButtonLabelContent("btn_buy1", str_pre .. price1)

    local price2 = price_data[2].price
    local coins2 = tonumber(price_data[2].coinsShowMax)
    self.lb_coin2:setString(util_formatCoins(coins2, 6))
    util_alignCenter({{node = self.sp_coin2, alignX = 5}, {node = self.lb_coin2}})
    self:setButtonLabelContent("btn_buy2", str_pre .. price2)

    local price3 = price_data[3].price
    local coins3 = tonumber(price_data[3].coinsShowMax)
    self.lb_coin3:setString(util_formatCoins(coins3, 6))
    util_alignCenter({{node = self.sp_coin3, alignX = 5}, {node = self.lb_coin3}})
    self:setButtonLabelContent("btn_buy3", str_pre .. price3)

    -- 默认选择第三档
    wheel_data:setPayIdx(3)
    self.bl_enabled = false
    self:runCsbAction(
        "pull",
        false,
        function()
            self:onSelect(3, false)
            self.bl_enabled = true
        end,
        60
    )

    self:updateBtnBuck()
end

function DailybonusBuyLayer:updateBtnBuck()
    local buyType = BUY_TYPE.CASHBONUS_TYPE_NEW
    self:setBtnBuckVisible(self:findChild("btn_buy1"), buyType, nil, {{node = self:findChild("btn_buy1"):getChildByName("ef_zi"):getChildByName("label_1"), addX = 10}})
    self:setBtnBuckVisible(self:findChild("btn_buy2"), buyType, nil, {{node = self:findChild("btn_buy2"):getChildByName("ef_zi"):getChildByName("label_1"), addX = 10}})
    self:setBtnBuckVisible(self:findChild("btn_buy3"), buyType, nil, {{node = self:findChild("btn_buy3"):getChildByName("ef_zi"):getChildByName("label_1"), addX = 10}})
end

------------新增提示功能
function DailybonusBuyLayer:showBenefitLayer(idx)
    if not idx then
        return
    end
    local node_info = self["btn_benefit" .. idx]
    if not node_info then
        return
    end

    local view = gLobalViewManager:getViewByName("WheelBuyBenefit")
    if view then
        return
    end

    local wheel_data = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    if not wheel_data then
        return
    end

    local price_data = wheel_data:getPayData()
    if not price_data then
        return
    end

    local view = util_createView(SHOP_CODE_PATH.ShopBenefitLayer, {p_price = price_data[idx].price})
    if view then
        view:setName("WheelBuyBenefit")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function DailybonusBuyLayer:hideBPInfo()
    if self.btn_benefit1 then
        self.btn_benefit1:removeChildByName("pbnode")
    end
    if self.btn_benefit2 then
        self.btn_benefit2:removeChildByName("pbnode")
    end
    if self.btn_benefit3 then
        self.btn_benefit3:removeChildByName("pbnode")
    end
end

function DailybonusBuyLayer:onSelect(cur_idx, bl_showAnim)
    local wheel_data = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    if not wheel_data then
        return
    end
    local idx = wheel_data:getPayIdx()
    if idx and idx == cur_idx then
        bl_showAnim = false
    end
    self:hideBPInfo()
    wheel_data:setPayIdx(cur_idx)
    -- 图片状态
    local selected_1 = (cur_idx == 1)
    self.sp_selectoff1:setOpacity(selected_1 and 0 or 255)
    self.sp_selecton1:setOpacity(selected_1 and 255 or 0)
    self.btn_buy1:setTouchEnabled(selected_1)
    if selected_1 then
        self:startButtonAnimation("btn_buy1", "sweep")
    else
        self:startButtonAnimation("btn_buy1", "idle")
    end
    self.btn_benefit1:setVisible(selected_1)
    self.btn_benefit1:setTouchEnabled(selected_1)

    local selected_2 = (cur_idx == 2)
    self.sp_selectoff2:setOpacity(selected_2 and 0 or 255)
    self.sp_selecton2:setOpacity(selected_2 and 255 or 0)
    self.btn_buy2:setTouchEnabled(selected_2)
    if selected_2 then
        self:startButtonAnimation("btn_buy2", "sweep")
    else
        self:startButtonAnimation("btn_buy2", "idle")
    end
    self.btn_benefit2:setVisible(selected_2)
    self.btn_benefit2:setTouchEnabled(selected_2)

    local selected_3 = (cur_idx == 3)
    self.sp_selectoff3:setOpacity(selected_3 and 0 or 255)
    self.sp_selecton3:setOpacity(selected_3 and 255 or 0)
    self.btn_buy3:setTouchEnabled(selected_3)
    if selected_3 then
        self:startButtonAnimation("btn_buy3", "sweep")
    else
        self:startButtonAnimation("btn_buy3", "idle")
    end
    self.btn_benefit3:setVisible(selected_3)
    self.btn_benefit3:setTouchEnabled(selected_3)

    local anim = "start" .. cur_idx
    self:runCsbAction(anim, true, nil, 60)

    -- 通知轮盘变更
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASHBONUS_WHEEL_CHANGE, {bl_showAnim = bl_showAnim})
end

function DailybonusBuyLayer:initCsbNodes()
    self.btn_buy1 = self:findChild("btn_buy1")
    self.sp_selectoff1 = self:findChild("sp_selectoff1")
    self.sp_selecton1 = self:findChild("sp_selecton1")
    self.node_coin1 = self:findChild("node_coin1")
    self.sp_coin1 = self:findChild("sp_coin1")
    self.lb_coin1 = self:findChild("lb_coin1")
    self.btn_benefit1 = self:findChild("btn_benefit1")

    self.btn_buy2 = self:findChild("btn_buy2")
    self.sp_selectoff2 = self:findChild("sp_selectoff2")
    self.sp_selecton2 = self:findChild("sp_selecton2")
    self.node_coin2 = self:findChild("node_coin2")
    self.sp_coin2 = self:findChild("sp_coin2")
    self.lb_coin2 = self:findChild("lb_coin2")
    self.btn_benefit2 = self:findChild("btn_benefit2")

    self.btn_buy3 = self:findChild("btn_buy3")
    self.sp_selectoff3 = self:findChild("sp_selectoff3")
    self.sp_selecton3 = self:findChild("sp_selecton3")
    self.node_coin3 = self:findChild("node_coin3")
    self.sp_coin3 = self:findChild("sp_coin3")
    self.lb_coin3 = self:findChild("lb_coin3")
    self.btn_benefit3 = self:findChild("btn_benefit3")
end

function DailybonusBuyLayer:setTouchEnabled(bl_enabled)
    self.bl_enabled = bl_enabled
end

function DailybonusBuyLayer:clickFunc(sender)
    if not self.bl_enabled then
        return
    end
    local name = sender:getName()
    if name == "btn_select1" then
        self:onSelect(1, true)
    elseif name == "btn_select2" then
        self:onSelect(2, true)
    elseif name == "btn_select3" then
        self:onSelect(3, true)
    elseif name == "btn_buy1" then
        self:buyWheelPay(1)
    elseif name == "btn_buy2" then
        self:buyWheelPay(2)
    elseif name == "btn_buy3" then
        self:buyWheelPay(3)
    elseif name == "btn_benefit1" then
        self:showBenefitLayer(1)
    elseif name == "btn_benefit2" then
        self:showBenefitLayer(2)
    elseif name == "btn_benefit3" then
        self:showBenefitLayer(3)
    end
end

function DailybonusBuyLayer:buyWheelPay(idx)
    local wheel_data = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    if not wheel_data then
        return
    end
    local payIdx = wheel_data:getPayIdx()
    if payIdx == idx then
        -- 发起支付
        wheel_data:recordWheelIdx()
        wheel_data:recordWheelReward()
        wheel_data:recordJackpotIdx()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASHBONUS_WHEEL_PAY)
    end
end

function DailybonusBuyLayer:closeUI()
    if self.bl_close then
        return
    end
    self.bl_close = true

    self:runCsbAction(
        "stop",
        false,
        function()
            self:removeSelf()
        end,
        60
    )
end

return DailybonusBuyLayer
