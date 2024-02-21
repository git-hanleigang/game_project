--限时活动奖励数据
local NewDCRushRewardData = class("NewDCRushRewardData")
local ShopItem = require "data.baseDatas.ShopItem"

-- message LuckyChallengeV2TimeLimitReward {
--   optional int32 seq = 1; // 标识第几个奖励
--   optional int32  progress = 2; // 该阶段的进度
--   optional int64 coins = 3; // 该阶段的金币奖励
--   repeated ShopItem items = 4; // 该阶段的道具奖励
--   optional string status = 5; // 奖励的状态
--   optional bool collected = 6; // 是否已经领取
-- }

function NewDCRushRewardData:ctor()
    self.m_coins = toLongNumber(0)
end

function NewDCRushRewardData:parseData(data)
    self.m_index = data.seq
    self.m_progress = data.progress
    self.m_coins:setNum(data.coins)
    self.m_status = data.status
    self.m_collected = data.collected
    if data.items and #data.items > 0 then
        self.m_items = {}
        for i,v in ipairs(data.items) do
            local shop = ShopItem:create()
            shop:parseData(v)
            table.insert(self.m_items,shop)
        end
    end
end

function NewDCRushRewardData:getIndex()
    return self.m_index or 0
end

function NewDCRushRewardData:getProgress()
    return self.m_progress or 0
end

function NewDCRushRewardData:getCoins()
    return self.m_coins or 0
end

function NewDCRushRewardData:getStatus()
    return self.m_status or 0
end

function NewDCRushRewardData:getCollected()
    return self.m_collected or false
end

function NewDCRushRewardData:getItems()
    return self.m_items or {}
end

return NewDCRushRewardData