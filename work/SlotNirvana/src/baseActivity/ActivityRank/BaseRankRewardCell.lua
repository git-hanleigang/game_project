--[[
    author:JohnnyFred
    time:2019-11-05 10:23:40
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseRankRewardCell = class("BaseRankRewardCell", util_require("base.BaseView"))

function BaseRankRewardCell:initUI(csb_res)
    if csb_res then
        self:setCsbName(csb_res)
    end
    self:createCsbNode(self:getCsbName())
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function BaseRankRewardCell:initCsbNodes()
    self.sp_bg = self:findChild("sp_bg")
    self.sp_1st = self:findChild("sp_1st")
    self.sp_2nd = self:findChild("sp_2nd")
    self.sp_3rd = self:findChild("sp_3rd")
    self.lb_rank = self:findChild("lb_rank")
    self.sp_coinBg = self:findChild("sp_coinBg")
    self.lb_coin = self:findChild("lb_coin")
    self.node_rewards = self:findChild("node_rewards")
end

function BaseRankRewardCell:updateView(reward_data, idx)
    if not reward_data or table.nums(reward_data) <= 0 then
        return
    end

    if not idx then
        return
    end

    --设置排名
    self:setRankValue(reward_data.p_minRank, reward_data.p_maxRank)
    --设置金币奖励
    self:setCoins(reward_data.p_coins)
    -- 设置物品奖励
    self:setRewards(reward_data.p_items)
end

function BaseRankRewardCell:setRankValue(minRank, maxRank)
    if not minRank or not maxRank then
        return
    end

    self.sp_1st:setVisible(minRank == maxRank and tonumber(minRank) == 1)
    self.sp_2nd:setVisible(minRank == maxRank and tonumber(minRank) == 2)
    self.sp_3rd:setVisible(minRank == maxRank and tonumber(minRank) == 3)

    self.lb_rank:setVisible(minRank > 3)
    if minRank ~= maxRank then
        self.lb_rank:setString(string.format("%d-%d", minRank, maxRank))
    else
        self.lb_rank:setString(minRank)
    end
end

--设置奖励
function BaseRankRewardCell:setCoins(coins)
    if coins and tonumber(coins) <= 0 then
        return
    end
    local maxLen = self:getCoinMaxLen()
    self.lb_coin:setString(util_formatCoins(coins, maxLen))
end

function BaseRankRewardCell:setRewards(items)
    if not items or table.nums(items) <= 0 then
        return
    end

    if not self.node_rewards then
        return
    end
    self.node_rewards:removeAllChildren()

    local uiList = {}
    local rewardScale = self:getRewardScale()
    local item_width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
    for i, shopItemData in ipairs(items) do
        local shopItemUI = gLobalItemManager:createRewardNode(shopItemData, ITEM_SIZE_TYPE.TOP)
        if shopItemUI ~= nil then
            self.node_rewards:addChild(shopItemUI)
            shopItemUI:setScale(rewardScale)
            table.insert(uiList, {node = shopItemUI, alignX = 3, size = cc.size(item_width, item_width), anchor = cc.p(0.5, 0.5)})
        end
    end
    util_alignLeft(uiList)
end

function BaseRankRewardCell:getContentSize()
    if self.sp_bg then
        return self.sp_bg:getContentSize()
    end
    assert(false, "获取 BaseRankRewardCell 控件大小失敗 默认背景图片命名不一致")
end

function BaseRankRewardCell:setCsbName(csb_res)
    self.csb_res = csb_res
end

function BaseRankRewardCell:getCsbName()
    return self.csb_res
end

function BaseRankRewardCell:getCoinMaxLen()
    return self.coin_len
end

function BaseRankRewardCell:setCoinMaxLen(coin_len)
    self.coin_len = coin_len
end

function BaseRankRewardCell:getRewardScale()
    return self.reward_len or 1
end

function BaseRankRewardCell:setRewardScale(reward_len)
    self.reward_len = reward_len
end

return BaseRankRewardCell
