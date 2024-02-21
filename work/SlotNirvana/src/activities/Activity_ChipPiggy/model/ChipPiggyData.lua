--[[
    集卡小猪数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ChipPiggyData = class("ChipPiggyData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")

ChipPiggyData.m_lastPrice = nil --存储的实际价值

function ChipPiggyData:ctor()
    ChipPiggyData.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChipPiggy)
end

--[[
    message PigChipResult {
        optional string begin = 1;
        optional int64 expireAt = 2;
        optional string activityId = 3;
        optional string value = 4;
        optional string key = 5;
        optional string price = 6;
        optional int64 totalPoints = 9;
        optional int64 currentPoints = 10;
        repeated PigChipProgressResult progressRewards = 11;
    }
]]
function ChipPiggyData:parseData(data)
    if not data then
        return
    end
    ChipPiggyData.super.parseData(self, data)
    self.p_value = data.value -- 购买的keyId
    self.p_key = data.key -- 购买的key（Sx）
    self.p_price = data.price -- 购买的价格
    self.p_totalPoints = tonumber(data.totalPoints) -- 总点数
    self.p_currentPoints = tonumber(data.currentPoints) -- 当前点数
    self.p_progressRewards = self:parseProgressResult(data.progressRewards) -- 集卡进度
    -- if not self.p_oldPoints then
    --     self.p_oldPoints = self.p_currentPoints
    -- else
    --     self:checkIsGetNewCard()
    -- end
end

--[[
    message PigChipProgressResult {
        optional int64 points = 1;
        repeated ShopItem items = 2;
        optional int64 coins = 3;
        optional string icon = 4;
    }
]]
function ChipPiggyData:parseProgressResult(data)
    local result = {}
    for i, v in ipairs(data) do
        local temp = {}
        temp.points = tonumber(v.points or 0)
        temp.items = self:parseItem(v.items)
        temp.coins = tonumber(v.coins or 0)
        temp.icon = v.icon
        table.insert(result, temp)
    end
    return result
end

function ChipPiggyData:parseItem(_data)
    local itemList = {}
    for i, v in ipairs(_data) do
        local tempData = ShopItem:create()
        tempData:parseData(v)
        table.insert(itemList, tempData)
    end
    return itemList
end

function ChipPiggyData:getKeyId()
    return self.p_value
end

function ChipPiggyData:getPrice()
    return self.p_price
end

function ChipPiggyData:getTotalPoints()
    return self.p_totalPoints or 0
end

function ChipPiggyData:getCurrentPoints()
    return self.p_currentPoints or 0
end

function ChipPiggyData:getProgressRewards()
    return self.p_progressRewards
end

-- 付费前记录一下金币
function ChipPiggyData:setRewardCoin(_rewardCoin)
    self.m_rewardCoin = _rewardCoin
end

function ChipPiggyData:getRewardCoin()
    return self.m_rewardCoin or 0
end

function ChipPiggyData:setSavePhaseReward(_items)
    self.m_rewardItems = _items
end

function ChipPiggyData:getSavePhaseReward()
    return self.m_rewardItems or {}
end

function ChipPiggyData:setSavePrice(_price)
    self.m_savePrice = _price
end

function ChipPiggyData:getSavePrice()
    return self.m_savePrice or 0
end

-- 最终基底奖励
function ChipPiggyData:getGrandPrize()
    if #self.p_progressRewards > 0 then
        return self.p_progressRewards[#self.p_progressRewards]
    end
    return {}
end

-- 当前阶段奖励数据（如果满了显示最终基地奖励）
function ChipPiggyData:getCurPhaseMaxReward()
    for i = #self.p_progressRewards, 1, -1 do
        if self.p_progressRewards[i].points <= self.p_currentPoints then
            return self.p_progressRewards[i]
        end
    end
    return self:getGrandPrize()
end

-- 当前段奖励数据（如果满了显示最终基地奖励）
function ChipPiggyData:getCurPhaseReward()
    local curPoints = self:getCurrentPoints()
    for i = #self.p_progressRewards, 1, -1 do
        local info = self.p_progressRewards[i]
        if info.points <= curPoints then
            return info
        end
    end
    if #self.p_progressRewards > 0 then
        return self.p_progressRewards[1]
    end
    return {}
end

-- 小于等于当前阶段的所有奖励
function ChipPiggyData:getAllPhaseRewardByPoint()
    local curPoints = self:getCurrentPoints()
    local rewards = {}
    for i = 1, #self.p_progressRewards do
        local info = self.p_progressRewards[i]
        if info.points <= curPoints then
            table.insert(rewards, info)
        end
    end
    return rewards
end

function ChipPiggyData:isMax()
    return self.p_currentPoints >= self.p_totalPoints
end

-- 检测是否获得新卡（关卡集卡小猪节点弹出气泡）
-- function ChipPiggyData:checkIsGetNewCard()
--     if self.p_oldPoints >= self.p_currentPoints then
--         return
--     end
--     if not gLobalViewManager:isLevelView() then
--         return
--     end
--     local curPhase = 0
--     local oldPhase = 0
--     for i = #self.p_progressRewards, 1, -1 do
--         if self.p_progressRewards[i].points <= self.p_currentPoints then
--             curPhase = math.max(i, curPhase)
--         end
--         if self.p_progressRewards[i].points <= self.p_oldPoints then
--             oldPhase = math.max(i, oldPhase)
--         end
--     end
--     self.p_oldPoints = self.p_currentPoints
--     if curPhase <= oldPhase then
--         return
--     end
--     G_GetMgr(G_REF.PiggyBank):getBubbleCtr():showTip("ChipReward")
-- end

return ChipPiggyData
