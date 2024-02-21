-- 现实任务数据

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local SevenDaysPurchaseData = class("SevenDaysPurchaseData", BaseActivityData)

-- message NewUserCharge {
--     optional int32 displayLevel = 1;//活动展示等级
--     optional int64 expireAt = 2;
--     repeated NewUserChargeReward rewards = 3;
--     optional string totalAmount = 4;//当前累计充值
--     optional bool display = 5; // 是否可以展示
--     optional int32 expire = 6;
-- }

function SevenDaysPurchaseData:parseData(data)
    SevenDaysPurchaseData.super.parseData(self, data)
    -- 新手期生效
    self:setNovice(true)

    self.displayLevel = data.displayLevel
    self.totalAmount = tonumber(data.totalAmount)
    self.display = data.display
    self:parseRewardsData(data.rewards)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.SevenDaysPurchase})
end

-- message NewUserChargeReward {
--     optional string price = 1;
--     optional int64 coins = 2;
--     repeated ShopItem items = 3;
--     optional bool collected = 4; //是否已领取
--   }
function SevenDaysPurchaseData:parseRewardsData(data)
    self.rewards = {}

    local not_collect = {}
    local collected = {}
    for idx, reward_data in ipairs(data) do
        if idx then
            local item_data = {}
            item_data.price = tonumber(reward_data.price) or 0
            item_data.collected = reward_data.collected
            item_data.isMore = tonumber(reward_data.highQuality) == 1
            item_data.items = {}
            local coins = tonumber(reward_data.coins) or 0
            if coins > 0 then
                local shopItem = gLobalItemManager:createLocalItemData("Coins", coins)
                if shopItem then
                    table.insert(item_data.items, shopItem)
                end
            end

            if reward_data.items and #reward_data.items > 0 then
                for idx, _data in ipairs(reward_data.items) do
                    local shopItem = ShopItem:create()
                    if shopItem then
                        shopItem:parseData(_data, true)
                        table.insert(item_data.items, shopItem)
                    end
                end
            end

            if item_data.collected then
                table.insert(collected, item_data)
            else
                table.insert(not_collect, item_data)
            end
        end
    end
    table.insertto(self.rewards, not_collect)
    table.insertto(self.rewards, collected)
end

-- 累积充值金额
function SevenDaysPurchaseData:getTotalAmount()
    return self.totalAmount
end

function SevenDaysPurchaseData:getRewardsData()
    return self.rewards
end

function SevenDaysPurchaseData:getRewardDataByIdx(idx)
    if self.rewards and self.rewards[idx] then
        return self.rewards[idx]
    end
end

function SevenDaysPurchaseData:hasRewards()
    if not self.rewards or table.nums(self.rewards) <= 0 then
        return false
    end
    for idx, reward_data in ipairs(self.rewards) do
        if reward_data and reward_data.collected == false then
            return true
        end
    end
    return false
end

function SevenDaysPurchaseData:recordRewardsList(buyResult)
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

function SevenDaysPurchaseData:getRewardCoins()
    return self.reward_coins
end

function SevenDaysPurchaseData:getRewardsList()
    return self.rewards_collect or {}
end

function SevenDaysPurchaseData:clearRewardsList()
    self.rewards_collect = nil
    self.reward_coins = nil
end

return SevenDaysPurchaseData
