--[[
    奖励信息
    author:{author}
    time:2021-01-25 20:03:48 
]]
-- FIX IOS 139
local ShopItem = require("data.baseDatas.ShopItem")
local HolidayChallengeRewardData = class("HolidayChallengeRewardData")

function HolidayChallengeRewardData:ctor()
    self.m_phase = 1

    self.m_points = 0

    self.m_collected = false

    self.m_rewardItems = nil

    self.m_coins = 0

    self.m_coinsValue = nil -- 金币价值

    self.m_description = ""

    self.m_rewardType = "" --奖励类型
end

function HolidayChallengeRewardData:parseData(data)
    if not data then
        return
    end
    self.m_phase =      data.phase
    self.m_points =     data.points
    self.m_collected =  data.collected
    self.m_coins =      data.coins

    -- 新版聚合挑战字段
    self.m_coinsValue = data.rewardValue
    self.m_description = data.description
    self.m_rewardType = data.rewardType

    self.m_rewardItems = {}
    for i = 1, #(data.itemData or {}) do
        local itemData = data.itemData[i]
        local rewardItem = ShopItem:create()
        rewardItem:parseData(itemData)
        table.insert(self.m_rewardItems, rewardItem)
    end
end

function HolidayChallengeRewardData:getPhase()
    return self.m_phase
end

function HolidayChallengeRewardData:getPoints()
    return self.m_points
end

function HolidayChallengeRewardData:getCollected()
    return self.m_collected
end

function HolidayChallengeRewardData:getCoins()
    return self.m_coins
end

function HolidayChallengeRewardData:getRewardItem(  )
    return self.m_rewardItems
end

function HolidayChallengeRewardData:getCoinsValue( )
    return self.m_coinsValue
end

function HolidayChallengeRewardData:getDescription( )
    return self.m_description
end

function HolidayChallengeRewardData:getRewardType( )
    return self.m_rewardType
end

return HolidayChallengeRewardData
