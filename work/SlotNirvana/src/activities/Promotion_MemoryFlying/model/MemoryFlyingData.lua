-- 6个箱子 数据

local ShopItem = require("data.baseDatas.ShopItem")
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseActivityData = require "baseActivity.BaseActivityData"
local MemoryFlyingData = class("MemoryFlyingData", BaseActivityData)

--message MemoryFlyingSaleConfig {
--    optional string activityId = 1; //活动id
--    optional int32 expire = 2; //剩余秒数
--    optional int64 expireAt = 3; //过期时间
--    optional int32 treasureIndex = 4; // 当前箱子的位置，从0开始
--    repeated MemoryFlyingTreasure treasures = 5; // 箱子
--    optional SaleItemConfig saleItem = 6;// 通用促销数据
--}
function MemoryFlyingData:parseData(data)
    BaseActivityData.parseData(self, data)
    self.rewardIdx = data.treasureIndex
    -- 支付相关数据
    -- local config = globalData.GameConfig:getActivityConfigById(data.activityId)
    -- if config then
    --     self:setRefName(config:getRefName())
    --     self:setThemeName(config:getThemeName())
    -- end
    self.saleItem = SaleItemConfig:create()
    self.saleItem:parseData(data.saleItem)
    self.rewards = self:parseRewards(data.treasures)
end

--message MemoryFlyingTreasure {
--    optional int64 coins = 1; // 金币
--    repeated ShopItem items = 2; // 物品
--    optional int32 type = 3;// 是否需要付费：0不需要，1需要
--    optional string price = 4; //价格
--}
function MemoryFlyingData:parseRewards(data)
    local rewards = {}
    if not data then
        return rewards
    end

    for idx, reward in ipairs(data) do
        local reward_data = {}
        reward_data.coins = reward.coins
        reward_data.items = {}
        for i, data in ipairs(reward.items) do
            local shopItem = ShopItem:create()
            shopItem:parseData(data)
            table.insert(reward_data.items, shopItem)
        end
        reward_data.pay_type = reward.type
        reward_data.price = reward.price
        reward_data.idx = idx - 1

        local curIdx = self:getCurIndex()
        if curIdx > reward_data.idx then
            reward_data.state = "COMPLETE"
        elseif curIdx < reward_data.idx then
            reward_data.state = "LOCKED"
        else
            reward_data.state = "OPEN"
        end
        rewards[reward_data.idx] = reward_data
    end
    return rewards
end

--function MemoryFlyingData:getThemeName()
--    return self:getRefName()
--end

function MemoryFlyingData:getCurIndex()
    return self.rewardIdx or 0
end

function MemoryFlyingData:getRewardByIdx(idx)
    for i, reward_data in pairs(self.rewards) do
        if reward_data.idx == idx then
            return self.rewards[idx]
        end
    end

    return nil
end

function MemoryFlyingData:isComplete()
    return self:getCurIndex() >= 6
end

function MemoryFlyingData:getSaleData()
    return self.saleItem
end

return MemoryFlyingData
