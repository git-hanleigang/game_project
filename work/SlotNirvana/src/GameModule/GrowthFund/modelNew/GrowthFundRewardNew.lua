--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-08 14:31:58
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-22 10:33:47
FilePath: /SlotNirvana/src/GameModule/GrowthFund/modelNew/GrowthFundRewardNew.lua
Description: 成长基金数据 新版 阶段奖励数据
--]]
local ShopItem = require("data.baseDatas.ShopItem")

local GrowthFundRewardNew = class("GrowthFundRewardNew")

function GrowthFundRewardNew:ctor()
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
    -- 阶段
    self.m_stage = 1

end

function GrowthFundRewardNew:parseData(data, _idx)
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
    -- 阶段
    self.m_stage = (tonumber(data.stage) or 0) + 1
end

function GrowthFundRewardNew:getIdx()
    return self.m_idx or 1
end

function GrowthFundRewardNew:getType()
    return self.m_type
end

function GrowthFundRewardNew:getLevel()
    return self.m_level or 1
end
function GrowthFundRewardNew:isCanCollectLevel()
    return self.m_level <= globalData.userRunData.levelNum
end

function GrowthFundRewardNew:isCollected(typeIdx)
    return self.m_collect[typeIdx] or false
end

function GrowthFundRewardNew:getDollar(typeIdx)
    return self.m_usd[typeIdx] or 0
end

function GrowthFundRewardNew:getGem(typeIdx)
    return self.m_gem[typeIdx] or ""
end

function GrowthFundRewardNew:getItem(typeIdx)
    return self.m_items[typeIdx]
end

function GrowthFundRewardNew:getLevelStatus(typeIdx)
    if self:isCollected(typeIdx) then
        return GrowthFundConfig.LEVEL_STATUS.Complete
    end

    if not G_GetMgr(G_REF.GrowthFund):isUnlock(self:getPhaseIdx()) and typeIdx == GrowthFundConfig.Type.Pay then
        return GrowthFundConfig.LEVEL_STATUS.Lock
    end

    if self:isCanCollectLevel() then
        return GrowthFundConfig.LEVEL_STATUS.Collect
    end
    return GrowthFundConfig.LEVEL_STATUS.Lock
end

-- 新版分阶段
function GrowthFundRewardNew:getPhaseIdx()
    return self.m_stage
end

return GrowthFundRewardNew
