--[[
    领取赛季奖励结果信息
    author:徐袁
    time:2020-12-29 16:02:39
]]
local ItemInfo = require("data.baseDatas.ShopItem")
local LeagueCollectResultInfo = class("LeagueCollectResultInfo")

function LeagueCollectResultInfo:ctor()
    self.m_coins = 0
    self.m_items = {}
    self.m_resultString = ""
    self.m_cardDropInfo = nil
    self.m_addTrophyInfo = {}
    self.m_trophyInfo = {}
end

function LeagueCollectResultInfo:parseData(data)
    if not data then
        return
    end

    self.m_resultString = data.collectResult
    self.m_coins = data.coins
    -- 奖励道具
    self.m_items = {}
    for i = 1, #(data.items or {}) do
        local _itemInfo = ItemInfo:create()
        _itemInfo:parseData(data.items[i])
        table.insert(self.m_items, _itemInfo)
    end
    -- 奖励卡牌
    self.m_cardDropInfo = data.cardDropInfo
    -- 巅峰赛掉落奖杯信息
    self:parseTrophyInfo(data)
end

-- 获得金币
function LeagueCollectResultInfo:getCoins()
    return self.m_coins
end

-- 获得物品
function LeagueCollectResultInfo:getItems()
    return self.m_items
end

-- 标题
function LeagueCollectResultInfo:getResultString( )
    return self.m_resultString
end

-- 掉落卡牌
function LeagueCollectResultInfo:getDropCardInfo( )
    return self.m_cardDropInfo
end

-- 巅峰赛掉落奖杯信息
function LeagueCollectResultInfo:parseTrophyInfo(_data)
    if _data.addTrophy then
        self.m_addTrophyInfo = _data.addTrophy
        local iconName = "LeagueSummit_trophy_" .. string.lower(self.m_addTrophyInfo.type)
        local itemData = gLobalItemManager:createLocalItemData(iconName, self.m_addTrophyInfo.num)
        table.insert(self.m_items, itemData) 
    end
    if _data.trophy and #_data.trophy > 0 then
        globalData.userRunData:parseLeagueTrophyData(_data.trophy)
    end
end
-- 巅峰赛掉落奖杯
function LeagueCollectResultInfo:getDropTrophyInfo( )
    return self.m_addTrophyInfo
end

return LeagueCollectResultInfo
