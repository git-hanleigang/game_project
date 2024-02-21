--[[
Author: cxc
Date: 2021-06-08 17:13:31
LastEditTime: 2021-06-09 20:57:19
LastEditors: Please set LastEditors
Description: levelRush 档位奖励数据
FilePath: /SlotNirvana/src/data/levelRush/LevelRushPhaseData.lua
--]]
local LevelRushPhaseData = class("LevelRushPhaseData")
local ShopItem = util_require("data.baseDatas.ShopItem")
  -- message LevelRushPhase {
    --     optional int64 level = 1; //等级
    --     optional int64 coins = 2; //金币奖励
    --     repeated ShopItem items = 3;//物品奖励
    --   }
function LevelRushPhaseData:ctor()
    self.m_level = 0
    self.m_coins = 0
    self.m_items = {}
end

function LevelRushPhaseData:parseData(_data)
    if not _data then
        return
    end

    self.m_level = tonumber(_data.level) or 0
    self.m_coins = tonumber(_data.coins) or 0
    self.m_items = self:parseShopItem(_data.items)

    self:reParseCollectType()
end

-- 因为 spin 回来 先回来的 活动数据 再回来的 玩家等级数据 所以 需要spin后重新 解析下 领取类型
function LevelRushPhaseData:reParseCollectType()
    -- 领取状态(0, 已领， 1，可领， 2 不可领)
    self.m_collectType = 2
    local curLevel = globalData.userRunData.levelNum
    if curLevel > self.m_level then
        self.m_collectType = 0
    elseif curLevel == self.m_level then
        self.m_collectType = 1     
    end
end

function LevelRushPhaseData:parseShopItem(_items)
    if not _items then
        return {}
    end

    local shopItems = {}
    if self.m_coins > 0 then
        newItemList[1] = gLobalItemManager:createLocalItemData("Coins", self.m_coins)
    end
    for i, data in ipairs(_items) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data, true)
        if globalData:isCardNovice() and shopItem.p_type == "Package" then
            -- 新手集卡期不显示 集卡 道具
        else
            table.insert(shopItems, shopItem)
        end
    end

    return shopItems
end


function LevelRushPhaseData:getLevel()
    return self.m_level
end

function LevelRushPhaseData:getCoins()
    return self.m_coins
end

function LevelRushPhaseData:getItems()
    return self.m_items
end

-- 获取领取 状态 当玩家spin 升级的时候就把奖励给了
function LevelRushPhaseData:getCollectType(_bLvUP)
    -- 不是升级打开的界面 就只有 已领 和 未领取 两种状态
    if not _bLvUP  and self.m_collectType == 1 then
        self.m_collectType = 0
        return self.m_collectType
    end

    return self.m_collectType
end

return LevelRushPhaseData