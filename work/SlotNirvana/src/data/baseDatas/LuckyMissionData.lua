--[[--
    每日任务活动数据
    多主题
]]
-- FIX IOS 139
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require("baseActivity.BaseActivityData")
local LuckyMissionData = class("LuckyMissionData", BaseActivityData)
function LuckyMissionData:ctor()
    LuckyMissionData.super.ctor(self)
    self.p_open = true
end

-- 解析数据
function LuckyMissionData:parseData(data)
    LuckyMissionData.super.parseData(self, data)
    self.p_name = data.name 
    if data.rewards and next(data.rewards) ~= nil then
        self.p_rewards = {}
        for i=1,#data.rewards do
            self.p_rewards[i] = self:parseMissionRewards(data.rewards[i])
        end
    end
    print(" ----- 2222 ----- ")
end

function LuckyMissionData:parseMissionRewards(data)
    local t = {}
    t.p_index = data.index
    t.p_collected = data.collected
    t.p_coins = tonumber(data.coins)
    if data.items and next(data.items) ~= nil then
        t.p_items = {}
        for i=1,#data.items do
            t.p_items[i] = ShopItem:create()
            t.p_items[i]:parseData(data.items[i],true)
        end
    end
    return t
end

function LuckyMissionData:isRunning()
    if not LuckyMissionData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true
end

-- 检查完成条件
function LuckyMissionData:checkCompleteCondition()
    if self.p_rewards then
        for i=1,#self.p_rewards do
            if self.p_rewards[i].p_collected == false then
                return false                
            end
        end
        return true
    else
        return false
    end
end

function LuckyMissionData:getMissionName()
    return self.p_name
end

function LuckyMissionData:getMissionReward()
    return self.p_rewards
end

function LuckyMissionData:getMissionRewardByIndex(index)
    if self.p_rewards then
        for i=1,#self.p_rewards do
            if self.p_rewards[i].p_index == index then
                return self.p_rewards[i]
            end
        end
    end
    return nil
end

return LuckyMissionData