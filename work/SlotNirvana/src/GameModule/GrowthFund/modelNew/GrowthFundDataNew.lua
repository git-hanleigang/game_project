--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-18 10:56:41
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-18 10:56:54
FilePath: /SlotNirvana/src/GameModule/GrowthFund/modelNew/GrowthFundDataNew.lua
Description: 成长基金数据 新版  分阶段
--]]
local BaseGameModel = require("GameBase.BaseGameModel")
local GrowthFundDataNew = class("GrowthFundDataNew", BaseGameModel)
local GrowthFundRewardNew = util_require("GameModule.GrowthFund.modelNew.GrowthFundRewardNew")
local GrowthFundUlckDataNew = util_require("GameModule.GrowthFund.modelNew.GrowthFundUlckDataNew")

function GrowthFundDataNew:ctor()
    GrowthFundDataNew.super.ctor(self)
    self.m_isUnlock = false

    -- 阶段定价
    self.m_ulckPhaseList = {}
    -- 等级奖励
    self.m_totalLevelRewards = {}
    self.m_curPhaseRewards = {}
    self.m_phaseRewards = {}
    self.m_canHandlePhaseIdxList = {}

    -- 当前所处阶段
    self.m_curPhaseIdx = 1

    -- 1：免费；2：付费
    -- 可领取数
    self.m_collectNum = {0, 0}
    -- 已完成数
    self.m_completedNum = {0, 0}
    -- 完成最新idx
    self._completedIdx = {0, 0}
    -- 获取第一个可领取位置
    self._collectIdx = {0, 0}

    -- 检索 奖励状态从 显示的最小奖励数据 idx
    self.m_minPhaseRewardIdx = 1
end

function GrowthFundDataNew:parseData(data)
    GrowthFundDataNew.super.parseData(self, data)
    self.m_canHandlePhaseIdxList = {}

    -- 等级奖励
    self:parseRewardLevelList(data.levelRewards or {})
    -- 阶段定价
    self:parseUlckLevelList(data.levelPrices or {})
    -- 当前阶段相关信息
    self:parseCurPhaseInfo()

    -- 检查是否完成
    if not self:isCompleted() then
        self:setCompleted(self:checkCompleteCondition())
    end
end

-- 可领取总数
function GrowthFundDataNew:getCanCollectLevelCount(isCheckUnlock)
    local freeNum = self:getCanCollectCountByType(1)
    local payNum = self:getCanCollectCountByType(2)
    return freeNum + payNum
end
-- 获得不同类型奖励的可领数量
function GrowthFundDataNew:getCanCollectCountByType(_type)
    if not _type then
        return 0
    end

    return (self.m_collectNum[_type] or 0)
end
-- 已完成总数
function GrowthFundDataNew:getCompletedCount()
    return (self.m_completedNum[1] or 0) + (self.m_completedNum[2] or 0)
end

function GrowthFundDataNew:isUnlockNewReward()
    return (self:getCanCollectLevelCount() + self:getCompletedCount()) > (self.m_ulckReNum or 0)
end

function GrowthFundDataNew:updateTotalNum()
    -- 上一次解锁总数
    self.m_ulckReNum = self:getCanCollectLevelCount() + self:getCompletedCount()
    -- 可领取数
    self.m_collectNum = {0, 0}
    -- 已完成数
    self.m_completedNum = {0, 0}
    -- 完成最新idx
    self._completedIdx = {0, 0}

    -- 获取第一个可领取位置
    self._collectIdx = {0, 0}

    -- 检索 奖励状态从 显示的最小奖励数据开始检索 到 本阶段结束
    self.m_minPhaseRewardIdx = self:getMinPhaseRewardIdx()
    for typeIdx = 1, 2 do
        for i = self.m_minPhaseRewardIdx, #self.m_totalLevelRewards do
            local rewardItem = self.m_totalLevelRewards[i]
            local phaseIdx = rewardItem:getPhaseIdx()
            local status = rewardItem:getLevelStatus(typeIdx)
            if phaseIdx > self.m_curPhaseIdx then
                break
            end

            if status == GrowthFundConfig.LEVEL_STATUS.Collect then
                self.m_collectNum[typeIdx] = self.m_collectNum[typeIdx] + 1
                self._collectIdx[typeIdx] = i + 1 - self.m_minPhaseRewardIdx
            elseif status == GrowthFundConfig.LEVEL_STATUS.Complete then
                self.m_completedNum[typeIdx] = self.m_completedNum[typeIdx] + 1
                self._completedIdx[typeIdx] = i - self.m_minPhaseRewardIdx
            end
        end
    end
end

function GrowthFundDataNew:onRegister()
    GrowthFundDataNew.super.onRegister(self)
    self:initCompleteStatus()
end

function GrowthFundDataNew:getCurPhaseRewards()
    return self.m_curPhaseRewards
end
function GrowthFundDataNew:getTotalRewards()
    return self.m_totalLevelRewards
end

function GrowthFundDataNew:isRunning()
    if self:isCompleted() then
        return false
    end

    return GrowthFundDataNew.super.isRunning(self)
end
function GrowthFundDataNew:checkCompleteCondition()
    return self.m_curPhaseIdx == #self.m_ulckPhaseList and not self:isCanShowEntry()
end

function GrowthFundDataNew:getCompleteMinIdx()
    if self._collectIdx[1] > 0 then
        return self._collectIdx[1]
    elseif self._collectIdx[2] > 0 then
        return self._collectIdx[2]
    else
        local showCount = #self.m_totalLevelRewards-self.m_minPhaseRewardIdx
        return math.min(math.max(math.max(self._completedIdx[1], self._completedIdx[2]), 1), showCount)
    end
end
function GrowthFundDataNew:isUnlock(_phaseIdx)
    if not _phaseIdx then
        return self.m_isUnlock
    end
    local ulckPhaseData = self.m_ulckPhaseList[_phaseIdx]
    if not ulckPhaseData then
        return self.m_isUnlock
    end
    return ulckPhaseData:isPay()
end

function GrowthFundDataNew:setUnlock(isUnlock)
    self.m_isUnlock = isUnlock or false
end

-- 获得奖励信息
function GrowthFundDataNew:getRewardItem(idx)
    if not idx then
        return nil
    end

    return self.m_totalLevelRewards[idx]
end

-- 获得奖励状态
function GrowthFundDataNew:getLevelStatus(idx, typeIdx, _phaseIdx)
    if _phaseIdx and _phaseIdx > self.m_curPhaseIdx then
        return GrowthFundConfig.LEVEL_STATUS.Lock 
    end

    local item = self:getRewardItem(idx)
    if not item then
        return GrowthFundConfig.LEVEL_STATUS.Lock
    end
    return item:getLevelStatus(typeIdx)
end

function GrowthFundDataNew:isCanShowEntry()
    if self.m_totalLevelRewards and #self.m_totalLevelRewards > 0 then
        for i = #self.m_totalLevelRewards, 1, -1 do
            local rewardData = self.m_totalLevelRewards[i]
            local status_1 = rewardData:getLevelStatus(1)
            local status_2 = rewardData:getLevelStatus(2)
            if status_2 ~= GrowthFundConfig.LEVEL_STATUS.Complete or status_1 ~= GrowthFundConfig.LEVEL_STATUS.Complete then
                return true
            end
        end
    end
    return false
end

-- 阶段定价
function GrowthFundDataNew:parseUlckLevelList(_list)
    self.m_ulckPhaseList = {}
    for i = 1, #_list do
        local ulckData = GrowthFundUlckDataNew:create()
        ulckData:parseData(_list[i], i)

        table.insert(self.m_ulckPhaseList, ulckData)
    end
end
function GrowthFundDataNew:getCurPhaseUlckData()
    local ulckPhase = self.m_ulckPhaseList[self.m_curPhaseIdx]
    return ulckPhase
end
function GrowthFundDataNew:getUlckPhaseList()
    return self.m_ulckPhaseList
end

-- 等级奖励
function GrowthFundDataNew:parseRewardLevelList(_list)
    self.m_totalLevelRewards = {} -- 多有奖励数据
    self.m_phaseRewards = {} -- 分阶段的数据
    for i = 1, #_list do
        local rewardItem = GrowthFundRewardNew:create()
        rewardItem:parseData(_list[i], i)
        local phaseIdx = rewardItem:getPhaseIdx()

        if not self.m_phaseRewards[phaseIdx] then
            self.m_phaseRewards[phaseIdx] = {}
        end
        table.insert(self.m_phaseRewards[phaseIdx], rewardItem)
        table.insert(self.m_totalLevelRewards, rewardItem)
    end
end
function GrowthFundDataNew:getPhaseRewardsList(_idx)
    if not _idx then
        return self.m_phaseRewards
    end
    return self.m_phaseRewards[_idx] or {}
end
function GrowthFundDataNew:getPhaseRewardsListCount(_idx)
    return #self.m_phaseRewards[_idx]
end

-- 当前阶段相关信息
function GrowthFundDataNew:parseCurPhaseInfo()
    local hadPayMaxPhaseIdx
    for i = 1, #self.m_ulckPhaseList do
        local ulckData = self.m_ulckPhaseList[i]
        if ulckData:isPay() then
            hadPayMaxPhaseIdx = i
        end
    end
    local curPhaseIdx = 1
    if hadPayMaxPhaseIdx then
        -- 已支付的该阶段是否 达成目标了
        local checkPhaseRewardList = self:getPhaseRewardsList(hadPayMaxPhaseIdx)
        local lastRewardData = checkPhaseRewardList[#checkPhaseRewardList]
        if lastRewardData then
            local lv  = lastRewardData:getLevel()
            if lv <= globalData.userRunData.levelNum then
                curPhaseIdx = math.min(hadPayMaxPhaseIdx + 1, #self.m_ulckPhaseList)
            else
                curPhaseIdx = hadPayMaxPhaseIdx
            end
        end
    end
    self.m_curPhaseIdx = curPhaseIdx -- 当前 阶段idx
    self.m_curPhaseRewards = self:getPhaseRewardsList(curPhaseIdx) -- 当前阶段数据奖励数据
    
    --当前阶段是否 付费
    local ulckPhase = self:getCurPhaseUlckData()
    if ulckPhase then
        self:setUnlock(ulckPhase:isPay())
    end

    -- 解析 tb 显示的 阶段数据
    self.m_canHandlePhaseIdxList = {} -- 显示的阶段idx 列表
    local minIdx
    for idx = 1, self.m_curPhaseIdx-1 do
        if minIdx then
            break
        end
        -- 解锁的阶段是否 还有未领取的
        local phaseRewardList = self:getPhaseRewardsList(idx)
        for i= #phaseRewardList, 1, -1 do
            local rewardData = phaseRewardList[i]
            if rewardData:getLevelStatus(1) ~= GrowthFundConfig.LEVEL_STATUS.Complete or rewardData:getLevelStatus(2) ~= GrowthFundConfig.LEVEL_STATUS.Complete then
                minIdx = idx
                break
            end
        end

    end
    -- minIdx -> maxIdx 都加入显示
    minIdx = minIdx or self.m_curPhaseIdx
    for i=minIdx, math.min(self.m_curPhaseIdx+1, #self.m_ulckPhaseList) do
        table.insert(self.m_canHandlePhaseIdxList, i)
    end

end
function GrowthFundDataNew:getShowPhaseIdxList()
    return self.m_canHandlePhaseIdxList
end
function GrowthFundDataNew:getCurPhaseIdx()
    return self.m_curPhaseIdx or 1
end
-- 获取显示的 第一个阶段 的最小奖励idx
function GrowthFundDataNew:getMinPhaseRewardIdx()
    local idx = 1
    if self.m_canHandlePhaseIdxList and self.m_canHandlePhaseIdxList[1] then
        local minPhaseIdx = self.m_canHandlePhaseIdxList[1]
        local phaseRewardList = self:getPhaseRewardsList(minPhaseIdx)
        local firstShowRewardData = phaseRewardList[1]
        if firstShowRewardData then
            idx = firstShowRewardData:getIdx()
        end
    end
    return idx
end


-- 当前阶段 支付价格
function GrowthFundDataNew:getPrice()
    local ulckPhase = self:getCurPhaseUlckData()
    if not ulckPhase then
        return 0
    end

    return ulckPhase:getPrice()
end

-- 当前阶段 折扣
function GrowthFundDataNew:getDiscount()
    local ulckPhase = self:getCurPhaseUlckData()
    if not ulckPhase then
        return 0
    end

    return ulckPhase:getDiscount()
end

-- 解锁商品信息
function GrowthFundDataNew:getGoodsInfo()
    local ulckPhase = self:getCurPhaseUlckData()
    if not ulckPhase then
        return {}
    end

    return {
        key = ulckPhase:getKey(),
        keyId = ulckPhase:getKeyId(),
        price = ulckPhase:getPrice()
    }
end

function GrowthFundDataNew:getPrePhaseIdxEndLevel(_phaseIdx)
    if not _phaseIdx or _phaseIdx == 1 then
        return 1
    end
    local prePhaseIdx = _phaseIdx - 1
    local prePhaseDataList = self:getPhaseRewardsList(prePhaseIdx)
    local prePhaseLastData = prePhaseDataList[#prePhaseDataList]
    if prePhaseLastData then
        return prePhaseLastData:getLevel()
    end
    return 1
end

return GrowthFundDataNew
