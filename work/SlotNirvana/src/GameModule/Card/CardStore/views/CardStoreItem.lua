-- 卡牌商城 商品道具

local CardStoreItem = class("CardStoreItem", BaseView)

function CardStoreItem:getCsbName()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    if p_config and p_config.ItemUI then
        return p_config.ItemUI
    end
end

function CardStoreItem:initDatas(reward_idx, reward_type)
    self.reward_idx = reward_idx
    self.reward_type = reward_type
end

function CardStoreItem:initUI()
    CardStoreItem.super.initUI(self)
    self:runCsbAction("idle", true, nil, 60)
    self:onReset(false)
end

function CardStoreItem:initCsbNodes()
    self.node_reward = self:findChild("node_reward")
    self.sp_empty = self:findChild("sp_empty")
    self.lb_itemNum = self:findChild("lb_itemNum")
    self.sp_discountBg = self:findChild("sp_discountBg")
    self.lb_discount = self:findChild("lb_discount")
    self.sp_ticket1 = self:findChild("sp_ticket1")
    self.sp_ticket2 = self:findChild("sp_ticket2")
    self.lb_chips = self:findChild("lb_chips")
    self.sp_bg_black = self:findChild("sp_bg_black")
    self.sp_discountBg_black = self:findChild("sp_discountBg_black")
    self.sp_number_bg = self:findChild("sp_number_bg")
    self.lb_num = self:findChild("lb_num")
end

function CardStoreItem:onReset(bl_playAnim)
    self.sp_ticket1:setVisible(self.reward_type == "NORMAL")
    self.sp_ticket2:setVisible(self.reward_type == "GOLDEN")

    self.node_reward:removeChildByName("rewardItem")

    local reward_data = G_GetMgr(G_REF.CardStore):getItemData(self.reward_type, self.reward_idx)
    if not reward_data then
        return
    end
    local rewards = reward_data:getRewards()
    if rewards.coins and rewards.coins > 0 then
        local item_info = gLobalItemManager:createLocalItemData("Coins", rewards.coins, {p_limit = 3})
        item_info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
        if item then
            item:setName("rewardItem")
            item:addTo(self.node_reward)
        end
        self.lb_itemNum:setString("x" .. util_formatCoins(rewards.coins, 3))
    elseif rewards.gems and rewards.gems > 0 then
        local item_info = gLobalItemManager:createLocalItemData("Gem", rewards.gems, {p_limit = 3})
        item_info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
        if item then
            item:setName("rewardItem")
            item:addTo(self.node_reward)
        end
        self.lb_itemNum:setString("x" .. util_formatCoins(rewards.gems, 3))
    elseif rewards.items and table.nums(rewards.items) > 0 then
        local item_info = rewards.items[1]
        item_info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
        if item then
            item:setName("rewardItem")
            item:addTo(self.node_reward)
        end
        local nums = item_info:getNum()
        self.lb_itemNum:setString("x" .. nums)

        local charType = item_info.p_mark[1]
        self.lb_itemNum:setVisible(charType ~= ITEM_MARK_TYPE.NONE)
    end

    local discount = reward_data:getDiscount()
    if discount and string.len(discount) > 0 then
        self.sp_discountBg:setVisible(true)
        self.lb_discount:setString(discount)
    else
        self.sp_discountBg:setVisible(false)
    end

    local chips = reward_data:getChips()
    self.lb_chips:setString(util_formatCoins(chips, 6))

    self:onRefresh()

    if bl_playAnim == true then
        self:runCsbAction(
            "start",
            false,
            function()
                self:runCsbAction("idle", true, nil, 60)
            end,
            60
        )
    end
end

function CardStoreItem:onRefresh()
    local reward_data = G_GetMgr(G_REF.CardStore):getItemData(self.reward_type, self.reward_idx)
    if not reward_data then
        return
    end
    local counts = reward_data:getCounts()
    self.lb_num:setString(counts)
    self.sp_empty:setVisible(counts <= 0)
    self.sp_bg_black:setVisible(counts <= 0)
    self.sp_discountBg_black:setVisible(counts <= 0)
    self.sp_number_bg:setVisible(counts > 0)
end

function CardStoreItem:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_buy" then
        local reward_data = G_GetMgr(G_REF.CardStore):getItemData(self.reward_type, self.reward_idx)
        if not reward_data then
            return
        end

        local counts = reward_data:getCounts()
        if counts <= 0 then
            return
        end

        local total_chips = 0
        local store_data = G_GetMgr(G_REF.CardStore):getRunningData()
        local item_type = reward_data:getItemType()
        if item_type == "NORMAL" then
            total_chips = store_data:getNormalChipPoints()
        elseif item_type == "GOLDEN" then
            total_chips = store_data:getGoldenChipPoints()
        end
        local chips = reward_data:getChips()

        if total_chips >= chips then
            self:showBuyTip()
        else
            self:showLackTip()
        end
    end
end

-- 显示购买面板
function CardStoreItem:showBuyTip()
    if gLobalViewManager:getViewByExtendData("CardStoreExchangeLayer") then
        return
    end

    local reward_data = G_GetMgr(G_REF.CardStore):getItemData(self.reward_type, self.reward_idx)
    if not reward_data then
        return
    end
    local exchangeUI = util_createView("GameModule.Card.CardStore.views.CardStoreExchangeLayer", reward_data)
    if exchangeUI then
        gLobalViewManager:showUI(exchangeUI, ViewZorder.ZORDER_UI)
    end
end

function CardStoreItem:showLackTip()
    if gLobalViewManager:getViewByExtendData("CardStoreLackLayer") then
        return
    end

    local exchangeUI = util_createView("GameModule.Card.CardStore.views.CardStoreLackLayer")
    if exchangeUI then
        gLobalViewManager:showUI(exchangeUI, ViewZorder.ZORDER_UI)
    end
end

return CardStoreItem
