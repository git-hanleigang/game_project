-- 现实任务数据

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local AddPayData = class("AddPayData", BaseActivityData)

-- message SuperBowlRecharge {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated SuperBowlRechargeStage stage = 4;
--     optional string recharge = 5;//累积充值
-- }
function AddPayData:parseData(data)
    AddPayData.super.parseData(self, data)

    self.recharge = tonumber(data.recharge)
    self:parseRewardsData(data.stage)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.AddPay})
end

-- message SuperBowlRechargeStage {
--     optional int32 index = 1;
--     optional string price = 2;//价格
--     optional int64 coins = 3;//金币奖励
--     repeated SuperBowlRechargeStageItemReward itemList = 4;//物品奖励
--     optional bool giftBox = 5;//是否是礼盒
--     optional bool finish = 6;//是否完成
--     optional bool collect = 7;//是否领奖
-- }

-- message SuperBowlRechargeStageItemReward {
--     repeated ShopItem item = 1;
--     optional int32 num = 2;//数量
-- }
function AddPayData:parseRewardsData(data)
    if not self.rewards then
        self.rewards = {}
    end
    for idx, reward_data in ipairs(data) do
        if idx then
            if not self.rewards[idx] then
                self.rewards[idx] = {}
            end
            self.rewards[idx].index = reward_data.index
            self.rewards[idx].price = tonumber(reward_data.price)
            self.rewards[idx].coins = tonumber(reward_data.coins) or 0
            local items = {}
            for item_idx, item_data in ipairs(reward_data.itemList) do
                local shopItem = ShopItem:create()
                shopItem:parseData(item_data.item, true)
                shopItem.extraCounts = item_data.num
                items[item_idx] = shopItem
            end
            self.rewards[idx].items = items

            self.rewards[idx].finish = reward_data.finish
            self.rewards[idx].collect = reward_data.collect
        end
    end
end

function AddPayData:getRewardDataByIdx(idx)
    if self.rewards and self.rewards[idx] then
        return self.rewards[idx]
    end
end

function AddPayData:hasRewards()
    if not self.rewards or #self.rewards <= 0 then
        return false
    end

    for idx, reward_data in ipairs(self.rewards) do
        if reward_data and reward_data.finish == true and reward_data.collect == false then
            return true
        end
    end
    return false
end

function AddPayData:recordRewardsList(buyResult)
    if not buyResult then
        return
    end

    local coins = 0
    local rewards = {}
    if buyResult.coins and buyResult.coins > 0 then
        local shopItem = gLobalItemManager:createLocalItemData("Coins", buyResult.coins)
        table.insert(rewards, shopItem)
        coins = coins + buyResult.coins
    end

    if buyResult.items and #buyResult.items > 0 then
        for item_idx, item_data in ipairs(buyResult.items) do
            local shopItem = ShopItem:create()
            shopItem:parseData(item_data, true)
            table.insert(rewards, shopItem)
        end
    end

    self.reward_coins = coins
    self.rewards_collect = rewards
end

function AddPayData:getRewardCoins()
    return self.reward_coins
end

function AddPayData:getRewardsList()
    return self.rewards_collect or {}
end

function AddPayData:clearRewardsList()
    self.rewards_collect = nil
    self.reward_coins = nil
end

function AddPayData:getMaxCollectIndex()
    local inx = 0
    if not self.rewards or #self.rewards <= 0 then
        return inx
    end

    for idx, reward_data in ipairs(self.rewards) do
        if reward_data and reward_data.finish == true and reward_data.collect == true then
            inx = inx + 1
        end
    end
    return inx
end

return AddPayData
