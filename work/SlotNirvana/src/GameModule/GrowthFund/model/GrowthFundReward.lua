--[[
    成长基金奖励
    author:{author}
    time:2023-03-16 14:58:49
]]
local ShopItem = require("data.baseDatas.ShopItem")

local GrowthFundReward = class("GrowthFundReward")

function GrowthFundReward:ctor()
    -- 领取标记
    self.m_collect = {}
    -- 解锁等级
    self.m_level = 0
    -- 奖励美金
    self.m_usd = {}
    -- 奖励钻石
    self.m_gem = {}
    -- 奖励物品
    self.m_items = {}
    -- 类型
    self.m_type = 0
end

function GrowthFundReward:parseData(data, _idx)
    if not data then
        return
    end

    self.m_idx = _idx

    -- 解锁等级
    self.m_level = data.level
    -- 1：免费；2：付费
    -- 领取标记
    self.m_collect[1] = data.freeCollect
    self.m_collect[2] = data.collect
    -- 奖励美金
    self.m_usd[1] = data.freeUsd
    self.m_usd[2] = data.usd
    -- 奖励钻石
    self.m_gem[1] = data.freeGem
    self.m_gem[2] = data.gem
    -- 奖励物品
    self.m_items[1] = data.freeItems
    self.m_items[2] = data.items
    -- 类型
    self.m_type = data.type
end

function GrowthFundReward:getIdx()
    return self.m_idx or 1
end

function GrowthFundReward:getType()
    return self.m_type
end

function GrowthFundReward:isCanCollectLevel()
    return self.m_level <= globalData.userRunData.levelNum
end

function GrowthFundReward:isCollected(typeIdx)
    return self.m_collect[typeIdx] or false
end

function GrowthFundReward:getDollar(typeIdx)
    return self.m_usd[typeIdx] or 0
end

function GrowthFundReward:getGem(typeIdx)
    return self.m_gem[typeIdx] or ""
end

function GrowthFundReward:getItem(typeIdx)
    return self.m_items[typeIdx]
end

function GrowthFundReward:getLevelStatus(typeIdx)
    if self:isCollected(typeIdx) then
        return GrowthFundConfig.LEVEL_STATUS.Complete
    end
    if self:isCanCollectLevel() then
        return GrowthFundConfig.LEVEL_STATUS.Collect
    end
    return GrowthFundConfig.LEVEL_STATUS.Lock
end

return GrowthFundReward
