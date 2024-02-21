-- 现实任务数据

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local AllpayData = class("AllpayData", BaseActivityData)

-- message AccumulatedRecharge {
--     optional string activityId = 1;
--     optional string name = 2;
--     optional string begin = 3;
--     optional int64 expireAt = 4;
--     optional int32 expire = 5;
--     optional int32 totalPoint = 6;//获得代币总数
--     optional int32 point = 7;//现在全服累充代币数
--     repeated AccumulatedRechargeReward rewards = 8;//宝箱奖励配置
-- }
function AllpayData:parseData(data)
    AllpayData.super.parseData(self, data)

    if not self.cur_point or (self.cur_point and data.point and self.cur_point < data.point) then
        self.cur_point = data.point or 0
    end
    -- self.max_point = data.totalPoint or 0
    self.max_gear_point = 0
    self:parseRewardsData(data.rewards)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.Allpay})
end

-- message AccumulatedRechargeReward {
--    optional int32 chestID = 1;//宝箱id
--    optional int32 require = 2;//解锁宝箱所需代币数
--    repeated ShopItem items = 3;//物品
-- }
function AllpayData:parseRewardsData(data)
    if not self.rewards then
        self.rewards = {}
    end
    for idx, reward_data in ipairs(data) do
        if idx then
            if not self.rewards[idx] then
                self.rewards[idx] = {}
            end
            self.rewards[idx].chestID = reward_data.chestID
            self.rewards[idx].target = reward_data.require
            local items = {}
            for item_idx, item_data in ipairs(reward_data.items) do
                local shopItem = ShopItem:create()
                shopItem:parseData(item_data, true)
                items[item_idx] = shopItem
            end
            self.rewards[idx].items = items

            self.max_gear_point = math.max(self.max_gear_point, reward_data.require)
        end
    end
end

function AllpayData:getPercentData()
    return self.cur_point, self.max_gear_point
end

function AllpayData:getRewardDataByIdx(idx)
    if self.rewards and self.rewards[idx] then
        return self.rewards[idx]
    end
end

return AllpayData
