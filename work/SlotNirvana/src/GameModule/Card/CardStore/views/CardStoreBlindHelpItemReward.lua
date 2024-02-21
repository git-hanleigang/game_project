-- 卡牌商店 盲盒产出概率分布

local CardStoreBlindHelpItemReward = class("CardStoreBlindHelpItemReward", BaseView)

function CardStoreBlindHelpItemReward:initUI(item_data)
    CardStoreBlindHelpItemReward.super.initUI(self)
    self.item_data = item_data
    self:initView()
end

function CardStoreBlindHelpItemReward:getCsbName()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    return p_config.BlindReward
end

function CardStoreBlindHelpItemReward:initCsbNodes()
    self.sp_rewardBg = self:findChild("sp_rewardBg")
    self.sp_discBg = self:findChild("sp_discBg")
    self.lb_disc = self:findChild("lb_disc")
    self.node_reward = self:findChild("node_reward")
    self.lb_num = self:findChild("lb_num")
end

function CardStoreBlindHelpItemReward:initView()
    if not self.item_data then
        return
    end

    local rewards = self.item_data:getRewards()
    if rewards.coins and rewards.coins > 0 then
        local item_info = gLobalItemManager:createLocalItemData("Coins", rewards.coins, {p_limit = 3})
        item_info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
        if item then
            item:addTo(self.node_reward)
        end
    elseif rewards.gems and rewards.gems > 0 then
        local item_info = gLobalItemManager:createLocalItemData("Gem", rewards.gems, {p_limit = 3})
        item_info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
        if item then
            item:addTo(self.node_reward)
        end
    elseif rewards.items and table.nums(rewards.items) > 0 then
        local item_info = rewards.items[1]
        item_info:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
        if item then
            item:addTo(self.node_reward)
        end
    end

    local prob = self.item_data:getProb()
    self.lb_disc:setString(prob)
end

function CardStoreBlindHelpItemReward:getContentSize()
    return self.sp_rewardBg:getContentSize()
end

return CardStoreBlindHelpItemReward
