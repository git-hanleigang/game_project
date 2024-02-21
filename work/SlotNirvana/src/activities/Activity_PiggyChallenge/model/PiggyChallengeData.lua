-- FIX IOS 150 v463
-- 小猪挑战 累充活动 数据
local BaseActivityData = require "baseActivity.BaseActivityData"
local PiggyChallengeData = class("PiggyChallengeData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")

-- 2021-03-17 改小R四个档位 大R8个档位
local BIG_R_GEAR = 8
local SMALL_R_GEAR = 4

function PiggyChallengeData:ctor()
    PiggyChallengeData.super.ctor(self)

    self.m_unGainRewards = {}
    -- self.m_preGear = gLobalDataManager:getNumberByField("PiggyChallengeData_PreGear2", 0)
end

function PiggyChallengeData:parseData(data)
    data = data or {}
    BaseActivityData.parseData(self, data)

    if self.p_buyTimes and self.p_buyTimes ~= data.buyTimes then
        self.m_preGear = self.p_buyTimes
    end

    self.p_buyTimes = data.buyTimes
    self.p_maxTimes = data.maxTimes
    if self.p_buyTimes > self.p_maxTimes then
        self.p_buyTimes = self.p_maxTimes
    end

    self.p_rewards = {} -- 奖励
    if data.rewards then
        self.p_rewards = self:parseRewardData(data.rewards)
    end
end

-- 解析所有宝箱奖励信息
function PiggyChallengeData:parseRewardData(rewards)
    local rewardList = {}
    for idx, info in ipairs(rewards) do
        local rewardData = {}
        rewardData.pos = info.pos -- 奖励位置，购买次数
        rewardData.coins = info.coins -- 奖励金币
        rewardData.collected = info.collected -- 是否领取
        rewardData.items = {}
        if info.items then
            rewardData.items = self:parseShopItemData(info.items)
        end

        rewardList[info.pos] = rewardData
    end
    return rewardList
end

-- 解析所有道具信息
function PiggyChallengeData:parseShopItemData(items)
    local itemList = {}
    for _, data in ipairs(items) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data, true)
        table.insert(itemList, shopItem)
    end

    return itemList
end

function PiggyChallengeData:getRewards()
    return self.p_rewards
end

-- 获取奖励信息 _idx
function PiggyChallengeData:getRewardDataByBoxId(_idx)
    if not _idx then
        return self.p_rewards
    end

    if not self:isSmallR() then
        _idx = _idx * 2
    end

    return self:getRewardData(_idx)
end

-- 获取奖励信息 _idx
function PiggyChallengeData:getRewardData(_idx)
    if not _idx then
        return self.p_rewards
    end

    return self.p_rewards[_idx]
end

function PiggyChallengeData:getCurIdx()
    return self.p_buyTimes
end

function PiggyChallengeData:hasRewards(_idx)
    if not self:isSmallR() then
        if _idx % 2 >= 1 then
            return false
        end
    end
    local reward_data = self:getRewardData(_idx)
    if reward_data.coins and tonumber(reward_data.coins) > 0 then
        return true
    end
    if reward_data.coins and table.nums(reward_data.coins) > 0 then
        return true
    end
    return false
end

-- 档位奖励是否已经领取
function PiggyChallengeData:isRewardCollected(_idx)
    if not self:isSmallR() then
        if _idx % 2 >= 1 then
            return true
        end
    end
    local reward_data = self:getRewardData(_idx)
    if reward_data then
        return reward_data.collected
    end
    return true
end

-- 当前进度
function PiggyChallengeData:getCurProcess()
    return self.p_buyTimes / self.p_maxTimes
end

-- 上一进度 如果没有领取过宝箱 则先显示上一进度 做滚动到当前进度以后领取宝箱的动画
function PiggyChallengeData:getPreProcess()
    local process = (self.p_buyTimes - 1) / self.p_maxTimes
    if process < 0 then
        process = 0
    end
    return process
end

-- 关闭界面的回调
function PiggyChallengeData:setCloseCallBack(_cb)
    self.m_closeBack = _cb
end
function PiggyChallengeData:getCloseCallBack()
    return self.m_closeBack
end

function PiggyChallengeData:isRunning()
    local bRunning = PiggyChallengeData.super.isRunning(self)
    if not bRunning then
        return false
    end

    local config = globalData.GameConfig:getActivityConfigById(self:getActivityID(), ACTIVITY_TYPE.COMMON)
    if not config then
        return false
    end

    return true
end

-- 判断是不是小R
function PiggyChallengeData:isSmallR()
    return self.p_maxTimes <= SMALL_R_GEAR -- 是不是小R
end

-- 获取该活动倒数两个的 卡包奖励
function PiggyChallengeData:getAdvertiseCardInfoList()
    local count = table.nums(self.p_rewards)
    if count <= 0 then
        return {}
    end

    local itemList = {}
    for i = count - 1, count do
        local rewardData = self:getRewardData(i)
        if rewardData and rewardData.items and rewardData.items[1] then
            local item = rewardData.items[1]
            table.insert(itemList, item)
        end
    end

    return itemList
end

return PiggyChallengeData
