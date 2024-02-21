--[[
Author: cxc
Date: 2022-01-11 11:50:44
LastEditTime: 2022-01-11 14:20:09
LastEditors: your name
Description: Lottery乐透 额外奖励活动 数据
FilePath: /SlotNirvana/src/activities/Activity_Lottery_Jackpot/model/LotteryJackpotData.lua
--]]
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local LotteryJackpotData = class("LotteryJackpotData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")

function LotteryJackpotData:parseData(_data)
    LotteryJackpotData.super.parseData(self, _data)
    -- message LotteryExtra{
    --     optional string activityId = 1;
    --     optional string activityName = 2;
    --     optional string referenceName = 3;
    --     optional int64 expireAt = 4;
    --     optional int32 expire = 5;
    --     repeated ShopItem items = 6;
    --   }
    self.m_rewardItems = {} --奖励道具
    self:parseRewardItems(_data.items) 
end

-- 解析 奖励道具
function LotteryJackpotData:parseRewardItems(_items)

    for i = 1, #(_items or {}) do
		local itemData = _items[i]
		local rewardItem = ShopItem:create()
		rewardItem:parseData(itemData)
        
		table.insert(self.m_rewardItems, rewardItem)
	end
end

function LotteryJackpotData:getRewardItems()
    return self.m_rewardItems or {}
end

return LotteryJackpotData
