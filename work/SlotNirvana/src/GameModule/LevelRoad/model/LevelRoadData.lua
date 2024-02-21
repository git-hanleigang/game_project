local BaseGameModel = require("GameBase.BaseGameModel")
local LevelRoadData = class("LevelRoadData", BaseGameModel)
local ShopItem = util_require("data.baseDatas.ShopItem")

--[[
    message LevelRoadResult {
        optional int32 v = 1;// 玩家的v
        optional string platFrom = 2;// 平台
        optional int32 level = 3; // 玩家的level
        repeated LevelRoadRewardResult display = 4;// 展示的奖励（未领取的以及后续展示的）
        repeated LevelRoadRewardResult rewards = 5;// 玩家所有的奖励
        optional LevelRoadPromotionResult levelRoadPromotion = 6; // 促销
        optional int32 prevLevelExpansion = 7; // 前一个等级的膨胀
    }
]]
function LevelRoadData:parseData(_data)
    if _data == nil then
        return
    end
    self.p_v = _data.v
    self.p_platFrom = _data.platFrom
    self.p_level = tonumber(_data.level)
    self.p_display = self:parseLevelRoadReward(_data.display)
    self.p_rewards = self:parseLevelRoadReward(_data.rewards)
    self.p_saleData = self:parseLevelRoadPromotion(_data.levelRoadPromotion)
    self.p_prevLevelExpansion = tonumber(_data.prevLevelExpansion)
end

--[[
    message LevelRoadRewardResult {
        optional int32 level = 1; // 玩家的level
        optional string type = 2; // 奖励的类型 Swell:膨胀系数 + 小游戏  Function:解锁的功能 Item:道具 CoinsItems:（老玩家）首次奖励 + Items Game:解锁新关
        optional int32 expansion = 3;// 膨胀系数
        repeated ShopItem items = 4;// 道具
        repeated string unLock = 5;// 解锁的功能
        optional bool collected = 6; // 是否领取
        optional int64 winUpTo = 7;// winUpTo
        optional int64 coins = 8;// 首次奖励的金币
        repeated string unlockName = 9; // 解锁功能的名字
        repeated string unlockGame = 10; // 解锁关卡的ID
    }
]]
function LevelRoadData:parseLevelRoadReward(_data)
    local rewardList = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = {}
            tempData.level = tonumber(v.level)
            tempData.type = v.type
            tempData.expansion = tonumber(v.expansion)
            tempData.items = self:parseItems(v.items)
            tempData.unLock = v.unLock
            tempData.collected = v.collected
            tempData.winUpTo = tonumber(v.winUpTo)
            tempData.coins = tonumber(v.coins) or 0
            tempData.unlockName = v.unlockName
            if v.type == "Game" and tempData.coins > 0 then
                local coinsData = gLobalItemManager:createLocalItemData("Coins", tonumber(tempData.coins), {p_limit = 3})
                table.insert(tempData.items, coinsData)
            end
            tempData.unlockGameList = v.unlockGame -- 解锁关卡的ID 集合
            table.insert(rewardList, tempData)
        end
    end
    return rewardList
end

--[[
    message LevelRoadPromotionResult {
        optional string key = 1; // 付费的档位
        optional string price = 2; // 付费的价格
        optional string value = 3; // 对应的支付连接
        optional int64 expireAt = 4;//促销倒计时
        optional int64 coins = 5;// 金币
        optional bool payUnLocked = 6;//是否付过费
        optional int32 level = 7;// 触发促销时的level
    }
]]
function LevelRoadData:parseLevelRoadPromotion(_data)
    local saleData = {}
    if _data then
        saleData.key = _data.key
        saleData.price = _data.price
        saleData.value = _data.value
        saleData.expireAt = tonumber(_data.expireAt)
        saleData.coins = tonumber(_data.coins)
        saleData.payUnLocked = _data.payUnLocked
        saleData.level = tonumber(_data.level)
    end
    return saleData
end

function LevelRoadData:parseItems(_items)
    local tempData = {}
    if _items and #_items > 0 then
        for i, v in ipairs(_items) do
            local temp = ShopItem:create()
            temp:parseData(v)
            table.insert(tempData, temp)
        end
    end
    return tempData
end

function LevelRoadData:getOpenLevel()
    return 1
end

function LevelRoadData:getPrevLevelExpansion()
    return self.p_prevLevelExpansion or 1
end

function LevelRoadData:getSaleData()
    return self.p_saleData
end

function LevelRoadData:getSaleExpireAt()
    local expirtAt = self.p_saleData.expireAt or 0
    return math.floor(expirtAt / 1000)
end

function LevelRoadData:getPhaseData()
    local phaseList = {}
    local curLevel = globalData.userRunData.levelNum
    local num = 0
    for i, v in ipairs(self.p_display) do
        if num >= 8 then
            break
        end
        if not v.collected then
            if curLevel <= v.level then
                num = num + 1
            end
            table.insert(phaseList, v)
        end
    end
    return phaseList
end

function LevelRoadData:getPreviousPhaseLevel()
    local phaseLevel = 0
    local curLevel = globalData.userRunData.levelNum
    for i, v in ipairs(self.p_rewards) do
        if curLevel >= v.level then
            phaseLevel = v.level
        else
            break
        end
    end
    return phaseLevel
end

function LevelRoadData:getNextPhaseLevel()
    local phaseLevel = 0
    local curLevel = globalData.userRunData.levelNum
    for i, v in ipairs(self.p_display) do
        if curLevel < v.level then
            phaseLevel = v.level
            break
        end
    end
    return phaseLevel > 0 and phaseLevel or curLevel
end

function LevelRoadData:getNextPhaseReward()
    local reward = nil
    local curLevel = globalData.userRunData.levelNum
    for i, v in ipairs(self.p_display) do
        if curLevel < v.level then
            reward = v
            break
        end
    end
    return reward
end

-- 当前等级的下一个膨胀节点
function LevelRoadData:getNextPhaseSwellReward()
    local reward = nil
    local curLevel = globalData.userRunData.levelNum
    for i, v in ipairs(self.p_display) do
        if curLevel < v.level and v.type == "Swell" then
            reward = v
            break
        end
    end
    return reward
end

function LevelRoadData:checkIsCanCollect()
    local isCanCollect = false
    local curLevel = globalData.userRunData.levelNum
    for i, v in ipairs(self.p_display) do
        if curLevel >= v.level then
            if not v.collected then
                isCanCollect = true
                break
            end
        else
            break
        end
    end
    return isCanCollect
end

function LevelRoadData:getRedPointNum()
    local num = 0
    local curLevel = globalData.userRunData.levelNum
    for i, v in ipairs(self.p_display) do
        if curLevel >= v.level and not v.collected then
            num = num + 1
        else
            break
        end
    end
    return num
end

function LevelRoadData:getCurrentExpansion()
    local boost = self:getPrevLevelExpansion()
    local curLevel = globalData.userRunData.levelNum
    for i, v in ipairs(self.p_rewards) do
        if curLevel >= v.level and v.collected and v.type == "Swell" then
            boost = v.expansion or 1
        end
    end
    return boost
end

function LevelRoadData:isRunning()
    local phaseList = self:getPhaseData()
    if #phaseList <= 0 then
        return false
    end
    return LevelRoadData.super.isRunning(self)
end

function LevelRoadData:isCanShowEntry()
    local curTime = util_getCurrnetTime()
    local saleExpireAt = self:getSaleExpireAt()
    if curTime >= saleExpireAt then
        return false
    end
    local isPayUnLocked = self.p_saleData.payUnLocked
    if isPayUnLocked then
        return false
    end
    return LevelRoadData.super.isCanShowEntry(self)
end

function LevelRoadData:getUnlockGameIdList()
    
end

return LevelRoadData
