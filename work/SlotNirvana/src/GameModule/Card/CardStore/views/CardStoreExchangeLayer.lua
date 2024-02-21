-- 卡牌商店 道具兑换界面

local CardStoreExchangeLayer = class("CardStoreExchangeLayer", BaseLayer)

function CardStoreExchangeLayer:ctor()
    CardStoreExchangeLayer.super.ctor(self)

    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    -- 设置横屏csb
    self:setLandscapeCsbName(p_config.ExchangeUI)
    self:setExtendData("CardStoreExchangeLayer")
end

function CardStoreExchangeLayer:initCsbNodes()
    self.node_reward = self:findChild("node_reward")
    self.lb_num = self:findChild("lb_num")
    self.lb_counts = self:findChild("lb_counts")
    self.btn_minus = self:findChild("btn_minus")
    self.btn_add = self:findChild("btn_add")
    self.btn_buy_normal = self:findChild("btn_buy_normal")
    self.btn_buy_gold = self:findChild("btn_buy_gold")
end

function CardStoreExchangeLayer:initDatas(reward_data)
    self.reward_data = reward_data
end

function CardStoreExchangeLayer:initView()
    self.node_reward:removeChildByName("rewardItem")
    local rewards = self.reward_data:getRewards()
    if rewards.coins and rewards.coins > 0 then
        local item_info = gLobalItemManager:createLocalItemData("Coins", rewards.coins, {p_limit = 3})
        item_info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
        if item then
            item:setName("rewardItem")
            item:addTo(self.node_reward)
        end
        self.str_sub = ""
        self.item_num = rewards.coins
        self.lb_num:setString(util_formatCoins(self.item_num, 3))
    elseif rewards.gems and rewards.gems > 0 then
        local item_info = gLobalItemManager:createLocalItemData("Gem", rewards.gems, {p_limit = 3})
        item_info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
        if item then
            item:setName("rewardItem")
            item:addTo(self.node_reward)
        end
        self.str_sub = ""
        self.item_num = rewards.gems
        self.lb_num:setString(util_formatCoins(self.item_num, 3))
    elseif rewards.items and table.nums(rewards.items) > 0 then
        local item_info = rewards.items[1]
        item_info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
        if item then
            item:setName("rewardItem")
            item:addTo(self.node_reward)
        end
        local charType = item_info.p_mark[1]
        if charType ~= ITEM_MARK_TYPE.NONE then
            self.str_sub = "x"
            self.item_num = item_info:getNum()
            self.lb_num:setString(self.str_sub .. self.item_num)
        else
            self.lb_num:setVisible(false)
        end
    end

    self.counts = 1
    self.lb_counts:setString(self.counts)
    local chips = self.reward_data:getChips()

    local item_type = self.reward_data:getItemType()
    self.btn_buy_normal:setVisible(item_type == "NORMAL")
    self.btn_buy_gold:setVisible(item_type == "GOLDEN")
    self:setButtonLabelContent("btn_buy_normal", chips)
    self:setButtonLabelContent("btn_buy_gold", chips)

    self.btn_minus:setBright(false)
    local buy_max = self:getBuyMax()
    self.btn_add:setBright(buy_max > 1)
end

function CardStoreExchangeLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

--点击监听
function CardStoreExchangeLayer:clickStartFunc(sender)
    local act_has = self:getActionByTag(10000)
    if act_has then
        self:stopAction(act_has)
    end

    local name = sender:getName()
    local act_change =
        cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.CallFunc:create(
            function()
                local max = self:getBuyMax()
                if max >= 1 then
                    if name == "btn_minus" then
                        self:onChanged(-1 * max)
                    elseif name == "btn_add" then
                        self:onChanged(max)
                    end
                end
            end
        )
    )
    if act_change then
        act_change:setTag(10000)
        self:runAction(act_change)
    end
end

--结束监听
function CardStoreExchangeLayer:clickEndFunc(sender)
    local act_change = self:getActionByTag(10000)
    if act_change then
        self:stopAction(act_change)
    end
end

function CardStoreExchangeLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_buy_normal" or name == "btn_buy_gold" then
        self:onBuy()
    elseif name == "btn_minus" then
        self:onChanged(-1)
    elseif name == "btn_add" then
        self:onChanged(1)
    end
end

function CardStoreExchangeLayer:getBuyMax()
    local item_type = self.reward_data:getItemType()
    local chips = self.reward_data:getChips()
    local total_chips = 0
    local store_data = G_GetMgr(G_REF.CardStore):getRunningData()
    if item_type == "NORMAL" then
        total_chips = store_data:getNormalChipPoints()
    elseif item_type == "GOLDEN" then
        total_chips = store_data:getGoldenChipPoints()
    end
    local buy_max = math.floor(total_chips / chips)
    local counts = self.reward_data:getCounts()
    if buy_max > counts then
        buy_max = counts
    end
    return buy_max
end

function CardStoreExchangeLayer:onChanged(num)
    if not num or num == 0 then
        return
    end
    local max = self:getBuyMax()
    self.counts = self.counts + num
    if self.counts < 1 then
        self.counts = 1
    elseif self.counts > max then
        self.counts = max
    end
    self.btn_minus:setBright(self.counts > 1)
    self.btn_add:setBright(self.counts < max)

    if self.item_num and self.item_num > 0 then
        self.lb_num:setString(self.str_sub .. util_formatCoins(self.item_num * self.counts, 3))
    end
    self.lb_counts:setString(self.counts)

    local chips = self.reward_data:getChips()
    self:setButtonLabelContent("btn_buy_normal", chips * self.counts)
    self:setButtonLabelContent("btn_buy_gold", chips * self.counts)
end

-- 发起购买
function CardStoreExchangeLayer:onBuy()
    local item_id = self.reward_data:getItemId()
    local item_num = self.counts
    local item_type = self.reward_data:getItemType()
    local item_cost = self.reward_data:getChips()
    G_GetMgr(G_REF.CardStore):sendToExchange(item_id, item_num, item_type, item_cost)
    self:closeUI()
end

return CardStoreExchangeLayer
