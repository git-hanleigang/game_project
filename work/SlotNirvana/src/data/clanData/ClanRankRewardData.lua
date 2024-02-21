--[[
Author: cxc
Date: 2022-02-26 15:18:11
LastEditTime: 2022-02-26 15:18:22
LastEditors: cxc
Description: 公会排行榜奖励
FilePath: /SlotNirvana/src/data/clanData/ClanRankRewardData.lua
--]]
local ClanRankRewardData = class("ClanRankRewardData")
local ClanConfig = util_require("data.clanData.ClanConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")

local RNANK_SUFFIX = {"ST","ND","RD","TH"}

--   message ClanRankReward {
--     optional int32 minRank = 1; //最小排名
--     optional int32 maxRank = 2; //最大排名
--     optional int32 coins = 3; //奖励金币
--     repeated ShopItem items = 4; //物品奖励 废弃
-- repeated int32 points = 4; //高倍场点数
--   }

function ClanRankRewardData:ctor()
   self.m_minRank = 0 -- 最小排名
   self.m_maxRank = 0 -- 最大排名
   self.m_coins = 0 -- 奖励金币
   self.m_deluxePints = 0 -- 高倍场点数
   self.m_rewardList = {} -- 物品奖励
end

function ClanRankRewardData:parseData(_data)
    if not _data then
        return
    end

    self.m_minRank = _data.minRank or 0 -- 最小排名
    self.m_maxRank = _data.maxRank or 0 -- 最大排名
    self.m_coins = tonumber(_data.coins) or 0 -- 奖励金币
    self.m_deluxePints = tonumber(_data.points) or 0 -- 高倍场点数

    self.m_rewardList = {} -- 物品奖励
    self.m_rewardNoCoinsList = {} -- 物品奖励 不带金币
    if self.m_coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self.m_coins, 3))
        table.insert(self.m_rewardList, itemData)
    end
    if self.m_deluxePints > 0 then
        local itemData = gLobalItemManager:createLocalItemData("DeluxeClub", self.m_deluxePints)
        table.insert(self.m_rewardList, itemData)
        table.insert(self.m_rewardNoCoinsList, itemData)
    end 
    for k, data in ipairs(_data.items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(self.m_rewardList, shopItem)
        table.insert(self.m_rewardNoCoinsList, shopItem)
    end
end

-- 获取排行描述
function ClanRankRewardData:getRankDesc()
    if self.m_minRank == self.m_maxRank then
        return self.m_minRank .. (RNANK_SUFFIX[self.m_minRank] or RNANK_SUFFIX[#RNANK_SUFFIX])
    end

    return self.m_minRank .. (RNANK_SUFFIX[self.m_minRank] or RNANK_SUFFIX[#RNANK_SUFFIX]) .. "-" .. self.m_maxRank .. (RNANK_SUFFIX[self.m_minRank] or RNANK_SUFFIX[#RNANK_SUFFIX])
end

-- 获取物品奖励
function ClanRankRewardData:getRewardList()
    return self.m_rewardList
end

-- 获取金币
function ClanRankRewardData:getCoins()
    return self.m_coins
end

-- 获取高倍场点数
function ClanRankRewardData:getDeluxePints()
    return self.m_deluxePints
end


-- 获取物品奖励 不带金币
function ClanRankRewardData:getRewardNoCoinsList()
    return self.m_rewardNoCoinsList
end

-- 检查排行 是否在本奖励排行区间
function ClanRankRewardData:checkRankIn(_rank)
    if not _rank then
        return
    end
    
    return _rank >= self.m_minRank and _rank <= self.m_maxRank
end

return ClanRankRewardData