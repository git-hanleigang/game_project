-- 现实任务数据

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local BalloonRushData = class("BalloonRushData", BaseActivityData)

function BalloonRushData:ctor()
    BalloonRushData.super.ctor(self)

    self.collect_items = {}
    self.collect_coins = 0
end

------------------------------------    游戏登录下发数据    ------------------------------------
--message InflateConsume {
--    optional string activityId = 1;
--    optional string name = 2;
--    optional string begin = 3;
--    optional int64 expireAt = 4;
--    optional int32 expire = 5;
--    optional int32 points = 6;//当前点数
--    optional bool collect = 7;//全部奖励是否已领取
--    repeated InflateConsumeReward reward = 8;//阶段奖励
--    optional int64 stage = 9;//当前阶段
--}
function BalloonRushData:parseData(data)
    BalloonRushData.super.parseData(self, data)

    self.phaseIdx = tonumber(data.stage)
    self.points = data.points or 0
    self.all_collected = data.collect or false
    self:parseRewardsData(data.reward)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.BalloonRush})
end

--message InflateConsumeReward {
--    optional int32 point = 1; //当前阶段点数
--    optional int64 coins = 2;//普通奖励金币
--    repeated ShopItem items = 3;//普通奖励物品
--    optional int64 limitCoins = 4;//限时奖励金币
--    repeated ShopItem limitItems = 5;//限时奖励物品
--    optional int64 expireAt = 6;//限时奖励过期时间
--    optional int32 expire = 7;//限时奖励剩余秒数
--    optional bool collect = 8 ;//当前阶段奖励是否领取
--    optional int64 stage = 9;//当前阶段
--}
function BalloonRushData:parseRewardsData(data)
    local rewards = {}
    for _, reward_data in pairs(data) do
        local idx = tonumber(reward_data.stage)
        if idx then
            rewards[idx] = {}
            rewards[idx].phaseIdx = idx

            rewards[idx].point = reward_data.point

            -- 固定奖励
            local normal = {}
            normal.coins = tonumber(reward_data.coins) or 0
            local items = {}
            for item_idx, item_data in ipairs(reward_data.items) do
                local shopItem = ShopItem:create()
                shopItem:parseData(item_data, true)
                items[item_idx] = shopItem
            end
            normal.items = items
            rewards[idx].reward = normal

            -- 限时奖励
            local extra = {}
            extra.coins = tonumber(reward_data.limitCoins) or 0
            local limitItems = {}
            for item_idx, item_data in ipairs(reward_data.limitItems) do
                local shopItem = ShopItem:create()
                shopItem:parseData(item_data, true)
                limitItems[item_idx] = shopItem
            end
            extra.items = limitItems

            -- 限时奖励过期时间
            extra.expireAt = tonumber(reward_data.expireAt)

            rewards[idx].extra = extra
            -- 是否已经领取
            rewards[idx].collect = reward_data.collect
        end
    end
    self.phaseData = rewards
end

function BalloonRushData:getCurPhaseIdx()
    return self.phaseIdx
end

function BalloonRushData:getMaxPhaseIdx()
    return #self.phaseData
end

function BalloonRushData:getCurPoints()
    return self.points
end

function BalloonRushData:setCurPoint(point)
    if point and point >= 0 then
        self.points = point
    end
end

function BalloonRushData:getMaxPointsByIdx(phaseIdx)
    if self.phaseData and phaseIdx and self.phaseData[phaseIdx] then
        return self.phaseData[phaseIdx].point
    end
end

function BalloonRushData:getMaxPoints()
    return self:getMaxPointsByIdx(self.phaseIdx)
end

function BalloonRushData:getAllPhases()
    if self.phaseData then
        return self.phaseData
    end
end

function BalloonRushData:getPhaseData(phaseIdx)
    if self.phaseData and phaseIdx >= 1 and self.phaseData[phaseIdx] then
        return self.phaseData[phaseIdx]
    end
end

-- 获取spin变化数据
function BalloonRushData:getControllData()
    local activityData = self:getActivityData()
    if not activityData then
        return
    end

    --local result = {}
    --result.num = activityData:getLeftBalls()
    --result.num_max = activityData:getSpinBallLimit()
    --result.energy = activityData:getCollect()
    --result.energy_max = activityData:getMax()
    ---- 能量越过或抵达最大值 重置为0
    --if result.energy >= result.energy_max then
    --    result.energy = 0
    --end

    --return result
end

--function BalloonRushData:isRunning()
--    local time_running = BalloonRushData.super.isRunning(self)
--    if not time_running then
--        return false
--    end
--    local all_collected = self:isAllCollected()
--    local rewards, coins = self:getRewards()
--    if all_collected and table.nums(rewards) <= 0 and coins <= 0 then
--        return false
--    end
--    return true
--end

function BalloonRushData:isAllCollected()
    return self.all_collected
end

function BalloonRushData:getCollect()
    return self.collect
end

-- 领取奖励数据
function BalloonRushData:saveRewards(items, coins)
    self.collect_items = items
    self.collect_coins = coins
end

function BalloonRushData:getRewards()
    return self.collect_items, self.collect_coins
end

--获取入口位置 1：左边，0：右边
function BalloonRushData:getPositionBar()
    return 1
end

return BalloonRushData
