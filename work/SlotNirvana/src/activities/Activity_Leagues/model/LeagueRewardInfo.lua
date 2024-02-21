--[[
    排行榜奖励列表信息
    author:徐袁
    time:2020-12-21 14:11:46
]]
local ItemInfo = require("data.baseDatas.ShopItem")
local LeagueRewardInfo = class("LeagueRewardInfo")

function LeagueRewardInfo:ctor(_bSummit)
    self.m_coins = 0
    self.m_items = {}
    self.m_maxRank = nil
    self.m_minRank = nil
    self.m_bSummit = _bSummit --是否是巅峰赛
end

function LeagueRewardInfo:parseData(data)
    if not data then
        return
    end

    self.m_coins = data.coins
    self.m_items = {}

    for i = 1, #(data.items or {}) do
        local _itemInfo = ItemInfo:create()
        _itemInfo:parseData(data.items[i])
        table.insert(self.m_items, _itemInfo)
    end

    self.m_maxRank = data.maxRank
    self.m_minRank = data.minRank

    -- 巅峰赛奖杯
    self:addSummitTrophyItem()
end

-- 巅峰赛奖杯
function LeagueRewardInfo:addSummitTrophyItem()
    if not self.m_bSummit then
        return
    end

    local trophyType = G_GetMgr(ACTIVITY_REF.LeagueSummit):getCurRankTrophyType(self.m_minRank)
    if not trophyType then
        return
    end
    local iconName = "LeagueSummit_trophy_" .. trophyType
    local itemData = gLobalItemManager:createLocalItemData(iconName, 1)
    table.insert(self.m_items, itemData)
end

function LeagueRewardInfo:getCoins()
    return self.m_coins or 0
end

function LeagueRewardInfo:getItems()
    return self.m_items or {}
end

function LeagueRewardInfo:getMaxRank()
    return self.m_maxRank or 0
end

function LeagueRewardInfo:getMinRank()
    return self.m_minRank or 0
end

function LeagueRewardInfo:getRank()
    return self.m_rank or 0
end

return LeagueRewardInfo
