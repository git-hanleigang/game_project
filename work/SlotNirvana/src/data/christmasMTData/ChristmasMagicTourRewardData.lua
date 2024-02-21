--[[
    购买等级信息
    author:{author}
    time:2020-09-24 11:11:54
]]
-- FIX IOS 139
local ShopItem = require("data.baseDatas.ShopItem")
local ChristmasMagicTourRewardData = class("ChristmasMagicTourRewardData")

function ChristmasMagicTourRewardData:ctor()
    self.m_phase = 1

    self.m_points = 0

    self.m_collected = false

    self.m_rewardItems = nil

    self.m_coins = 0
end

function ChristmasMagicTourRewardData:parseData(data)
    if not data then
        return
    end
    self.m_phase =      data.phase
    self.m_points =     data.points
    self.m_collected =  data.collected
    self.m_coins =      data.coins

    self.m_rewardItems = {}
    for i = 1, #(data.itemData or {}) do
        local itemData = data.itemData[i]
        local rewardItem = ShopItem:create()
        rewardItem:parseData(itemData)
        table.insert(self.m_rewardItems, rewardItem)
    end
end

function ChristmasMagicTourRewardData:getPhase()
    return self.m_phase
end

function ChristmasMagicTourRewardData:getPoints()
    return self.m_points
end

function ChristmasMagicTourRewardData:getCollected()
    return self.m_collected
end

function ChristmasMagicTourRewardData:getCoins()
    return self.m_coins
end

function ChristmasMagicTourRewardData:getRewardItem(  )
    return self.m_rewardItems
end

return ChristmasMagicTourRewardData
