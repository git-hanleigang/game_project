-- 现实任务数据

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local TopUpBonusCoinIncreaseData = require "activities.Activity_TopUpBonus.model.TopUpBonusCoinIncreaseData"
local TopUpBonusData = class("TopUpBonusData", BaseActivityData)

--[[
    message TopUpBonus {
    optional string activityId = 1; //活动id
    optional int64 expireAt = 2; //过期时间
    optional int32 expire = 3; //剩余秒数
    repeated TopUpBonusStage stage = 4;
    optional string recharge = 5;//累积充值
    repeated TopUpBonusWheelCell wheel = 6; //转盘数据
    optional string showPrizePoolUsd = 7; //显示奖池美刀值
    repeated TopUpBonusWheelBigReward wheelBigRewards = 8; //轮盘大赢列表
    optional int64 leftWheelCount = 9; //剩余转盘次数
    optional string nextExpectedValue = 10; //下个检查点美刀值
    optional int64 nextExpectedAt = 11; //下个检查点时间戳 距当前时间不大于15分钟
}
    --]]

function TopUpBonusData:parseData(data)
    TopUpBonusData.super.parseData(self, data)
    
    self.totalAmount = tonumber(data.recharge) --累积充值
    self:parseRewardsData(data.stage)

    self.m_refreshWheel = false -- 是否刷新轮盘
    
    self.showPrizePoolUsd = tonumber(data.showPrizePoolUsd) --显示奖池美刀值
    if self.m_showPrizePoolUsd_befor then
        if self.m_showPrizePoolUsd_befor > 0 and self.showPrizePoolUsd <= 0 then
            self.m_refreshWheel = true
        elseif self.m_showPrizePoolUsd_befor <= 0 and self.showPrizePoolUsd > 0 then
            self.m_refreshWheel = true
        end
    end

    self.m_showPrizePoolUsd_befor = self.showPrizePoolUsd
    self.nextExpectedValue = tonumber(data.nextExpectedValue) --下个检查点美刀值
    self.nextExpectedAt = tonumber(data.nextExpectedAt)/1000 --下个检查点时间戳 距当前时间不大于15分钟

    self.m_wheelBigRewards = {}
    if data.wheelBigRewards and #data.wheelBigRewards > 0 then
        for i,v in ipairs(data.wheelBigRewards) do
            local wheelRecord = {}
            wheelRecord.nickname = v.nickname
            wheelRecord.winUsd = v.winUsd
            table.insert(self.m_wheelBigRewards,wheelRecord)
        end
    end
    self.m_wheelData = {}
    if data.wheel and #data.wheel > 0 then
        for i,v in ipairs(data.wheel) do
            local oneData = {}
            oneData.index = v.index
            oneData.type = v.type --奖励类型 Dollar/Item
            oneData.coins = v.usd
            oneData.items = {}
            if v.items and #v.items > 0 then
                for i,v in ipairs(v.items) do
                    local shopItem = ShopItem:create()
                    shopItem:parseData(v, true)
                    table.insert(oneData.items,shopItem)
                end
            end
            oneData.superMark = true --超级大奖标记 0.否 1.是
            if v.superMark and v.superMark == 0 then
                oneData.superMark = false
            end
            table.insert(self.m_wheelData,oneData)
        end
    end
    self.leftWheelCount = data.leftWheelCount --剩余转盘次数

    if not self.m_firstInit then
        self.m_firstInit  = true
        self:updateTopUpBonusGoldIncrease(true,{})
    end
    --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.TopUpBonus})
end

function TopUpBonusData:parseRewardsData(data)
    if not self.rewards then
        self.rewards = {}
    end
    local currentStage = 0
    for idx, reward_data in ipairs(data) do
        if idx then
            if not self.rewards[idx] then
                self.rewards[idx] = {}
            end
            self.rewards[idx].index = reward_data.index
            local price = tonumber(reward_data.price)
            self.rewards[idx].price = price
            self.rewards[idx].coins = tonumber(reward_data.coins) or 0
            local items = {}
            for item_idx, item_data in ipairs(reward_data.itemList) do
                local shopItem = ShopItem:create()
                shopItem:parseData(item_data.item, true)
                shopItem.extraCounts = item_data.num
                items[item_idx] = shopItem
            end
            self.rewards[idx].items = items
            self.rewards[idx].isCurrentStage = false
            if self.totalAmount > price then
                currentStage = idx
            end
            self.rewards[idx].wheelNum = reward_data.wheelNum
            self.rewards[idx].finish = reward_data.finish
            self.rewards[idx].collect = reward_data.collect
        end
    end
    if currentStage +1 <= #self.rewards then
        self.rewards[currentStage +1].isCurrentStage = true
    end
end



-- 累积充值金额
function TopUpBonusData:getTotalAmount()
    return self.totalAmount
end

function TopUpBonusData:getRewardsData()
    return self.rewards
end

function TopUpBonusData:getRewardDataByIdx(idx)
    if self.rewards and self.rewards[idx] then
        return self.rewards[idx]
    end
end

function TopUpBonusData:hasRewards()
    if not self.rewards or #self.rewards <= 0 then
        return false
    end

    for idx, reward_data in ipairs(self.rewards) do
        if reward_data and reward_data.finish == true and reward_data.collect == false then
            return true
        end
    end
    return false
end

function TopUpBonusData:recordRewardsList(buyResult)
    if not buyResult then
        return
    end

    local coins = 0
    local rewards = {}
    if buyResult.coins and buyResult.coins > 0 then
        local shopItem = gLobalItemManager:createLocalItemData("Coins", buyResult.coins)
        table.insert(rewards, shopItem)
        coins = coins + buyResult.coins
    end

    if buyResult.items and #buyResult.items > 0 then
        for item_idx, item_data in ipairs(buyResult.items) do
            local shopItem = ShopItem:create()
            shopItem:parseData(item_data, true)
            table.insert(rewards, shopItem)
        end
    end

    self.reward_coins = coins
    self.rewards_collect = rewards
end

function TopUpBonusData:getRewardCoins()
    return self.reward_coins
end

function TopUpBonusData:getRewardsList()
    return self.rewards_collect or {}
end

function TopUpBonusData:clearRewardsList()
    self.rewards_collect = nil
    self.reward_coins = nil
end

function TopUpBonusData:getMaxCollectIndex()
    local inx = 0
    if not self.rewards or #self.rewards <= 0 then
        return inx
    end

    for idx, reward_data in ipairs(self.rewards) do
        if reward_data and reward_data.finish == true and reward_data.collect == true then
            inx = inx + 1
        end
    end
    return inx
end




function TopUpBonusData:setTargetQuestGoldIncrease(data)
    if data.showPrizePoolUsd then
        self.showPrizePoolUsd = tonumber(data.showPrizePoolUsd) --显示奖池美刀值
        self.nextExpectedValue = tonumber(data.nextExpectedValue) --下个检查点美刀值
        self.nextExpectedAt = tonumber(data.nextExpectedAt)/1000 --下个检查点时间戳 距当前时间不大于15分钟
    end
end

function TopUpBonusData:updateTopUpBonusGoldIncrease(forceInit,data)
    if not self.m_isInitGoldRun and not data then
        return false 
    end

    if data then
        self:setTargetQuestGoldIncrease(data)
    end
    local refresh = false
    if (forceInit  or not self.m_increaseGold)then
        self.m_increaseGold = TopUpBonusCoinIncreaseData:create()
        self.m_increaseGold:setMinCoins(self.showPrizePoolUsd,self.nextExpectedValue,self.nextExpectedAt)
        if not self.m_isInitGoldRun then
            self.m_isInitGoldRun = true
        end
    else
        local oneRefresh = self.m_increaseGold:updateIncrese()
        if not refresh then
            refresh = oneRefresh
        end
    end
    return refresh
end

function TopUpBonusData:isCanShowRunGold()
    return not not self.m_isInitGoldRun
end

function TopUpBonusData:getRunGoldCoin()
    return self.m_increaseGold:getRuningGold()
end

function TopUpBonusData:getRunNameList()
    return self.m_wheelBigRewards
end

function TopUpBonusData:getWheelData()
    return self.m_wheelData
end

function TopUpBonusData:getLeftTicket()
    return self.leftWheelCount 
end

function TopUpBonusData:isWillRefreshWheel()
    return self.m_refreshWheel
end

function TopUpBonusData:clearWillRefreshWheel()
    self.m_refreshWheel = false
end

return TopUpBonusData
