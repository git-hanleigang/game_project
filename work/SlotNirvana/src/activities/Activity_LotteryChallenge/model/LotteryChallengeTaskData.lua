--[[
Author: cxc
Date: 2022-01-10 14:22:05
LastEditTime: 2022-01-10 14:22:06
LastEditors: your name
Description: Lottery乐透 挑战活动 任务数据
FilePath: /SlotNirvana/src/activities/Activity_LotteryChallenge/model/LotteryChallengeTaskData.lua
--]]
local LotteryChallengeTaskData = class("LotteryChallengeTaskData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function LotteryChallengeTaskData:ctor(_data)
    --   message LotteryChallengeGoalResult {
    --     optional int32 index = 1;
    --     optional int32 goal = 2;
    --     optional int64 coins = 3;
    --     repeated ShopItem itemDatas = 4;
    --     optional bool collected = 5;
    --   }

    self.m_idx = _data.index or 1 -- 任务idx
    self.m_taskNeed = _data.goal or 0 -- 任务需求值
    self.m_rewardCoins = tonumber(_data.coins) or 0 --奖励金币
    self.m_rewardItems = {} --奖励道具
    self:parseRewardItems(_data.itemDatas) 
    self.m_bCollected = _data.collected  -- 是否领奖
end

-- 解析 奖励道具
function LotteryChallengeTaskData:parseRewardItems(_items)
    if self.m_rewardCoins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_rewardCoins)
        table.insert(self.m_rewardItems, itemData)
    end

    for i = 1, #(_items or {}) do
		local itemData = _items[i]
		local rewardItem = ShopItem:create()
		rewardItem:parseData(itemData)
        
		table.insert(self.m_rewardItems, rewardItem)
	end
end

function LotteryChallengeTaskData:getTaskIdx()
    return self.m_idx
end

function LotteryChallengeTaskData:getTaskNeed()
    return self.m_taskNeed
end

function LotteryChallengeTaskData:getRewardCoins()
    return self.m_rewardCoins
end

function LotteryChallengeTaskData:getRewardItems()
    return self.m_rewardItems
end

function LotteryChallengeTaskData:isCollected()
    return self.m_bCollected
end

return LotteryChallengeTaskData