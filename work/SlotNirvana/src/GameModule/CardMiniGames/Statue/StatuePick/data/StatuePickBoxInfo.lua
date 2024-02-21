--[[
    小游戏宝箱信息
    author:徐袁
    time:2020-12-21 14:11:46
]]
local ItemInfo = require("data.baseDatas.ShopItem")
local StatuePickBoxInfo = class("StatuePickBoxInfo")

function StatuePickBoxInfo:ctor()
    self.m_id = 0
    -- 是否是免费箱子
    self.m_isFree = true
    -- 奖励类型
    self.m_type = nil
    self.m_isOpened = false
    self.m_coins = 0
    self.m_items = {}
    -- 宝石数量
    self.m_gems = 0
end

function StatuePickBoxInfo:parseData(data)
    if not data then
        return
    end

    self.m_id = data.id
    self.m_type = data.type
    self.m_isOpened = data.pick
    self.m_coins = tonumber(data.coins)
    self.m_items = {}
    -- 解析奖励道具
    for i = 1, #(data.rewards or {}) do
        local _itemInfo = ItemInfo:create()
        _itemInfo:parseData(data.rewards[i])
        table.insert(self.m_items, _itemInfo)
    end

    self.m_gems = tonumber(data.gems)
    self.m_isFree = data.free
end

function StatuePickBoxInfo:isOpened()
    return self.m_isOpened or false
end

-- 物品类型
function StatuePickBoxInfo:getType()
    return self.m_type or "NONE"
end

-- 获得等级
function StatuePickBoxInfo:isFree()
    return self.m_isFree
end

-- 箱子Id
function StatuePickBoxInfo:getId()
    return self.m_id
end

-- 是否有奖励
function StatuePickBoxInfo:isHasReward()
    -- return self:getCoins() > 0 or self:getGems() > 0 or #(self:getItems()) > 0
    return self:getType() ~= "NONE"
end

-- 金币
function StatuePickBoxInfo:getCoins()
    return self.m_coins or 0
end

-- 道具
function StatuePickBoxInfo:getItems()
    return self.m_items or {}
end

-- 宝石
function StatuePickBoxInfo:getGems()
    return self.m_gems
end

return StatuePickBoxInfo
