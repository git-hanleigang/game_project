local BrokenSaleV2Cell = class("BrokenSaleV2Cell", BaseView)

function BrokenSaleV2Cell:getCsbName()
    if globalData.slotRunData.isPortrait then
        return "BrokenSaleV2/csd/BrokenSale_coin_shu.csb"
    else
        return "BrokenSaleV2/csd/BrokenSale_coin_heng.csb"
    end
end

function BrokenSaleV2Cell:initDatas(data)
    self.m_saleItem = data.saleItem
    self.m_delegate = data.delegate
    self.m_index = self.m_saleItem:getIndex()
    self.rewards_list = {}
end

function BrokenSaleV2Cell:initUI()
    BrokenSaleV2Cell.super.initUI(self)

    self:refreshUI(self.m_saleItem)
    self:runCsbAction("idle", true)
    self:updateBtnBuck()
end

function BrokenSaleV2Cell:updateBtnBuck()
    local buyType = BUY_TYPE.BROKENSALEV2
    self:setBtnBuckVisible(self:findChild("btn_pay"), buyType, nil, {{node = self:findChild("btn_pay"):getChildByName("ef_zi"):getChildByName("label_1"), addX = 20}})
end
--刷新UI
function BrokenSaleV2Cell:refreshUI(data)
    if not data then
        return
    end
    self.m_saleItem = data

    for i = 1, 3 do
        local item = self:findChild("node_prize" .. i)
        local node_reward = self:findChild("node_rewards" .. i)
        local spCoinBg = self:findChild("sp_coin_bg_" .. i)
        item:setVisible(i == self.m_index)
        if i == self.m_index then
            --当前获得金箔 金币sp位置
            local sp_coin = spCoinBg:getChildByName("node_coin"):getChildByName("sp_coin")
            local lb_coin = spCoinBg:getChildByName("node_coin"):getChildByName("lb_coin")
            lb_coin:setString(util_formatCoins(self.m_saleItem:getCoins(), 9))
            local uiList = {
                {node = sp_coin},
                {node = lb_coin, alignX = 3}
            }
            util_alignCenter(uiList)

            node_reward:setScale(0.8)
            self:refreshReward(node_reward)

            local node_buff = item:getChildByName("node_buff")
            local node_buff_bubble = item:getChildByName("node_buff_bubble")
            self:refreshBuffReward(node_buff, node_buff_bubble)

            -- 折扣More
            local baseNodeMore = item:getChildByName("node_more")
            local nodeMore, act = util_csbCreate("BrokenSaleV2/csd/BrokenSale_more.csb")
            nodeMore:setName("node_more")
            baseNodeMore:addChild(nodeMore)
            util_csbPlayForKey(act, "idle", true, nil, 60)
            local discount = self.m_saleItem:getDiscount() .. "%"
            local normalTag = nodeMore:getChildByName("ef_biaoqian")
            local goldTag = nodeMore:getChildByName("ef_biaoqian_gold")
            normalTag:getChildByName("lb_shuzi"):setString(discount)
            goldTag:getChildByName("lb_shuzi"):setString(discount)
            normalTag:setVisible(i ~= 3)
            goldTag:setVisible(i == 3)
        end
    end

    self:setButtonLabelContent("btn_pay", "ONLY $" .. self.m_saleItem:getPrice())
end

function BrokenSaleV2Cell:refreshReward(node_reward)
    local items = self.m_saleItem:getItems()
    local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
    local ui_list = {}
    local last_counts = #self.rewards_list
    local total_counts = #items
    if total_counts > 0 then
        for i, v in ipairs(items) do
            local reward_item = self.rewards_list[i]
            if reward_item then
                gLobalItemManager:updateItem(reward_item, v, ITEM_SIZE_TYPE.REWARD)
                table.insert(ui_list, {node = reward_item, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)})
            else
                local shopItemUI = gLobalItemManager:createRewardNode(v, ITEM_SIZE_TYPE.REWARD)
                if shopItemUI then
                    shopItemUI:addTo(node_reward)
                    table.insert(self.rewards_list, shopItemUI)
                    table.insert(ui_list, {node = shopItemUI, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)})
                end
            end
        end

        if last_counts > total_counts then
            for i = last_counts, total_counts + 1, -1 do
                local reward = self.rewards_list[i]
                if reward then
                    self.rewards_list[i] = nil
                    reward:removeSelf()
                end
            end
        end
    else
        local purchaseData = gLobalItemManager:getCardPurchase(nil, self.m_saleItem:getPrice())
        if purchaseData then
            node_reward:removeAllChildren()
            width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
            local vipPoints = self.m_saleItem:getVipPoint()
            if vipPoints <= 0 then
                vipPoints = self:getItemVipPoints(purchaseData.p_vipPoints)
            end
            local clubPoints = purchaseData.p_clubPoints

            if vipPoints > 0 then
                local item = gLobalItemManager:createLocalItemData("Vip", vipPoints)
                local shopItemUI = gLobalItemManager:createRewardNode(item, ITEM_SIZE_TYPE.TOP)
                if shopItemUI then
                    shopItemUI:addTo(node_reward)
                    table.insert(ui_list, {node = shopItemUI, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)})
                end
            end
            if clubPoints > 0 then
                local item = gLobalItemManager:createLocalItemData("DeluxeClub", clubPoints)
                local shopItemUI = gLobalItemManager:createRewardNode(item, ITEM_SIZE_TYPE.TOP)
                if shopItemUI then
                    shopItemUI:addTo(node_reward)
                    table.insert(ui_list, {node = shopItemUI, size = cc.size(width, width), anchor = cc.p(0.5, 0.5), alignX = 10})
                end
            end
        end
    end

    if #ui_list > 0 then
        util_alignCenter(ui_list)
    end
end

function BrokenSaleV2Cell:refreshBuffReward(node_buff, node_buff_bubble)
    local items = self.m_saleItem:getExtraItems()
    local buffNode = node_buff:getChildByTag("10001")
    if items and #items > 0 then
        if buffNode then
            return
        end
        local item = items[1]
        local shopItemUI = gLobalItemManager:createRewardNode(item, ITEM_SIZE_TYPE.REWARD)
        if shopItemUI then
            shopItemUI:setIconTouchEnabled(false)
            shopItemUI:addTo(node_buff)
            shopItemUI:setTag("10001")
        end

        local buffBubble = util_createView("views.sale.BrokenSaleV2.BrokenSaleV2BuffBubble")
        if buffBubble then
            node_buff_bubble:addChild(buffBubble)
            buffBubble:showBubble()
            self.m_buffBubble = buffBubble
        end
    else
        if buffNode then
            node_buff:removeChildByTag("10001")
        end
        node_buff_bubble:removeAllChildren()
        self.m_buffBubble = nil
    end
end

function BrokenSaleV2Cell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_pay" then
        self:buySale()
    elseif name == "btn_buff_" .. self.m_index then
        if self.m_buffBubble then
            self.m_buffBubble:showBubble()
        end
    elseif name == "btn_benefit_" .. self.m_index then
        G_GetMgr(G_REF.PBInfo):showPBInfoLayer(self.m_saleItem, self.m_saleItem:getItems(), nil, true)
    end
end

function BrokenSaleV2Cell:buySale()
    G_GetMgr(G_REF.BrokenSaleV2):requestBuySale(self.m_saleItem, handler(self, self.buySuccess), handler(self, self.buyFailed))
end

function BrokenSaleV2Cell:buySuccess()
    if not tolua.isnull(self) then
        local levelUpNum = gLobalSaleManager:getLevelUpNum()
        local buyType = BUY_TYPE.BROKENSALEV2
    
        local view = util_createView("GameModule.Shop.BuyTip")
        view:initBuyTip(buyType, self.m_saleItem:getBuyTipData(), self.m_saleItem:getCoins(), levelUpNum)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        self.m_delegate:closeLayer()
    end
end

function BrokenSaleV2Cell:buyFailed(_errorInfo)
    if not tolua.isnull(self) then
        self:checkPopPayConfirmLayer(_errorInfo)
    end
end

-- 检查是否弹出 二次确认弹板
function BrokenSaleV2Cell:checkPopPayConfirmLayer(_errorInfo)
    if not _errorInfo or not _errorInfo.bCancel then
        -- 非用户自主取消 返回
        return
    end

    local data = G_GetMgr(G_REF.BrokenSaleV2):getRunningData()
    if not data then
        return
    end

    local saleData = data:getSaleItemByIndex(self.m_index)
    if not saleData then
        return
    end

    local payCoins = saleData:getCoins()
    local priceV = saleData:getPrice()
    local params = {
        coins = payCoins,
        price = priceV,
        confirmCB = function()
            if not tolua.isnull(self) then
                self.m_saleItem = saleData
                self:buySale()
            end
        end,
        cancelCB = function()
        end
    }
    local view = G_GetMgr(G_REF.PaymentConfirm):showPayCfmLayer(params)
    return view
end

return BrokenSaleV2Cell
