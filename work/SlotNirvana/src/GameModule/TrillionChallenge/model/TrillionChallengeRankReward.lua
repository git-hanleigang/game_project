--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:26:01
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/model/TrillionChallengeRankReward.lua
Description: 亿万赢钱挑战 排行榜 奖励数据
--]]
local TrillionChallengeRankReward = class("TrillionChallengeRankReward")
local ShopItem = util_require("data.baseDatas.ShopItem")

 function TrillionChallengeRankReward:ctor(_data)
     self._minRank = _data.minRank or 0 -- 最小排名
     self._maxRank = _data.maxRank or 0 -- 最大排名
     self._coins = tonumber(_data.coins) or 0 -- 奖励金币
     self._rewardList = {} -- 物品奖励
     if self._coins > 0 then
         local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self._coins, 3))
         table.insert(self._rewardList, itemData)
     end
     for k, data in ipairs(_data.items or {}) do
         local shopItem = ShopItem:create()
         shopItem:parseData(data)
         table.insert(self._rewardList, shopItem)
     end
 end
 
 -- 获取物品奖励
 function TrillionChallengeRankReward:getRewardList()
     return self._rewardList
 end
 -- 获取金币
 function TrillionChallengeRankReward:getCoins()
     return self._coins
 end
 -- 检查排行 是否在本奖励排行区间
 function TrillionChallengeRankReward:checkRankIn(_rank)
     if not _rank then
         return
     end
     
     return _rank >= self._minRank and _rank <= self._maxRank
 end
 
 return TrillionChallengeRankReward