--[[
    成长基金数据
    author:{author}
    time:2023-03-10 15:51:58
]]
local GrowthFundReward = require("GameModule.GrowthFund.model.GrowthFundReward")
local BaseGameModel = require("GameBase.BaseGameModel")
local GrowthFundData = class("GrowthFundData", BaseGameModel)

function GrowthFundData:ctor()
    GrowthFundData.super.ctor(self)
    self.m_isUnlock = false
    -- 解锁支付相关
    self.m_ulckKey = ""
    self.m_ulckKeyId = ""
    self.m_ulckPrice = ""
    -- 显示折扣
    self.m_discount = 0
    -- 等级奖励
    self.m_levelRewards = {}

    -- 1：免费；2：付费
    -- 可领取数
    self.m_collectNum = {0, 0}
    -- 已完成数
    self.m_completedNum = {0, 0}
end

function GrowthFundData:parseData(data)
    GrowthFundData.super.parseData(self, data)

    self.m_isUnlock = data.pay
    -- 解锁基金购买信息
    self.m_ulckKey = data.key
    self.m_ulckKeyId = data.keyId
    self.m_ulckPrice = data.price

    self.m_discount = data.discount

    self.m_levelRewards = {}

    for i = 1, #(data.levelRewards or {}) do
        local rewardItem = GrowthFundReward:create()
        rewardItem:parseData(data.levelRewards[i], i)

        table.insert(self.m_levelRewards, rewardItem)
    end

    -- 检查是否完成
    if not self:isCompleted() then
        self:setCompleted(self:checkCompleteCondition())
    end
end

-- 可领取总数
function GrowthFundData:getCanCollectLevelCount(isCheckUnlock)
    local freeNum = self:getCanCollectCountByType(1)
    local payNum = 0
    if (not isCheckUnlock) or (isCheckUnlock and self.m_isUnlock) then
        payNum = self:getCanCollectCountByType(2)
    end
    return freeNum + payNum
end

-- 获得不同类型奖励的可领数量
function GrowthFundData:getCanCollectCountByType(_type)
    if not _type then
        return 0
    end

    return (self.m_collectNum[_type] or 0)
end

-- 已完成总数
function GrowthFundData:getCompletedCount()
    return (self.m_completedNum[1] or 0) + (self.m_completedNum[2] or 0)
end

function GrowthFundData:isUnlockNewReward()
    return (self:getCanCollectLevelCount() + self:getCompletedCount()) > (self.m_ulckReNum or 0)
end

function GrowthFundData:updateTotalNum()
    -- 上一次解锁总数
    self.m_ulckReNum = self:getCanCollectLevelCount() + self:getCompletedCount()
    -- 可领取数
    self.m_collectNum = {0, 0}
    -- 已完成数
    self.m_completedNum = {0, 0}

    -- 获取第一个可领取位置
    self.m_collectIdx = {0, 0}

    for typeIdx = 1, 2 do
        for i = 1, #self.m_levelRewards do
            local rewardItem = self.m_levelRewards[i]
            if rewardItem:getLevelStatus(typeIdx) == GrowthFundConfig.LEVEL_STATUS.Collect then
                self.m_collectNum[typeIdx] = self.m_collectNum[typeIdx] + 1
                -- if self.m_collectIdx[typeIdx] == 0 then
                    self.m_collectIdx[typeIdx] = i
                -- end
            elseif rewardItem:getLevelStatus(typeIdx) == GrowthFundConfig.LEVEL_STATUS.Complete then
                self.m_completedNum[typeIdx] = self.m_completedNum[typeIdx] + 1
            end
        end
    end
end

function GrowthFundData:onRegister()
    GrowthFundData.super.onRegister(self)
    self:initCompleteStatus()
end

-- 解锁商品信息
function GrowthFundData:getGoodsInfo()
    return {
        key = self.m_ulckKey,
        keyId = self.m_ulckKeyId,
        price = self.m_ulckPrice
    }
end

function GrowthFundData:getRewardItems()
    return self.m_levelRewards
end

function GrowthFundData:isRunning()
    if self:isCompleted() then
        return false
    end

    return GrowthFundData.super.isRunning(self)
end

function GrowthFundData:checkCompleteCondition()
    return self:getCompletedCount() >= 2 * #self.m_levelRewards
end

function GrowthFundData:getCompleteMinIdx()
    -- for i = 2, 1, -1 do
    --     if self.m_collectNum[i] > 0 then
    --         return self.m_completedNum[i]
    --     end
    -- end
    -- return math.max(self.m_completedNum[1], self.m_completedNum[2])

    if self.m_collectIdx[2] > 0 then
        return self.m_collectIdx[2]
    elseif self.m_collectIdx[1] > 0 then
        return self.m_collectIdx[1]
    else
        return math.min(math.max(self.m_completedNum[1], self.m_completedNum[2]) + 1, #self.m_levelRewards)
    end
end

function GrowthFundData:isUnlock()
    return self.m_isUnlock
end

function GrowthFundData:setUnlock(isUnlock)
    self.m_isUnlock = isUnlock or false
end

-- 获得奖励信息
function GrowthFundData:getRewardItem(idx)
    if not idx then
        return nil
    end

    return self.m_levelRewards[idx]
end

-- -- 奖励是否锁定
-- function GrowthFundData:isRewardCanCollect(idx)
--     if not self.m_isUnlock then
--         return GrowthFundConfig.LEVEL_STATUS.Lock
--     end
--     local item = self:getRewardItem(idx)
--     if not item then
--         return false
--     else
--         return item:isCanCollect()
--     end
-- end

-- 获得奖励状态
function GrowthFundData:getLevelStatus(idx, typeIdx)
    if not self.m_isUnlock and typeIdx == GrowthFundConfig.Type.Pay then
        return GrowthFundConfig.LEVEL_STATUS.Lock
    end

    local item = self:getRewardItem(idx)
    if not item then
        return GrowthFundConfig.LEVEL_STATUS.Lock
    end
    return item:getLevelStatus(typeIdx)
end

function GrowthFundData:isCanShowEntry()
    if self.m_levelRewards and #self.m_levelRewards > 0 then
        for typeIdx = 1, 2 do
            for i = 1, #self.m_levelRewards do
                local status = self:getLevelStatus(i, typeIdx)
                if status ~= GrowthFundConfig.LEVEL_STATUS.Complete then
                    return true
                end
            end
        end
    end
    return false
end

function GrowthFundData:getPrice()
    return self.m_ulckPrice
end

function GrowthFundData:getDiscount()
    return self.m_discount
end

return GrowthFundData
