--[[
    @desc: ddaily mission rush 活动
    author:csc
    time:2021-08-13 15:27:54
]]
local ShopItem = require("data.baseDatas.ShopItem")
local BaseActivityData = require("baseActivity.BaseActivityData")
local MissionRushData = class("MissionRushData",BaseActivityData)

-- optional int32 gems = 1;
-- repeated ShopItem items = 2;

function MissionRushData:ctor()
    MissionRushData.super.ctor(self)
    -- 奖励道具
    self.m_coins = nil
    self.m_rewards = {}
end

function MissionRushData:parseData(data)
    if not data then
        return
    end
    MissionRushData.super.parseData(self, data)

    self.m_rewards = {}
    if data.rewards and #data.rewards > 0 then -- 就一个 reward
        local reward = data.rewards[1]
        self.m_coins = reward.coins
        for i=1,#reward.items do
            local _item = ShopItem:create()
            _item:parseData(reward.items[i])
            table.insert(self.m_rewards, _item)
        end
    end
end

function MissionRushData:getCoins()
    return tonumber(self.m_coins) 
end

function MissionRushData:getRewards()
    return self.m_rewards
end

-- 重写领奖弹板
function MissionRushData:getRewardLayer()
    local _filePath = "Activity/" .. self:getThemeName().."RewardLayer"
    if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
        local _module, count = string.gsub(_filePath, "/", ".")
        return _module
    end
    return ""
end

function MissionRushData:getSoundPath()
    return "Activity/DailyMissionRush/sound/dailymissionrush_openrewardlayer.mp3"
end

function MissionRushData:checkCompleteCondition()
    if globalData.missionRunData.p_allMissionCompleted == true and globalData.missionRunData.p_taskInfo.p_taskCollected == true then --全部完成
        return true
    end   
    return false
end

function MissionRushData:isRunning()
    if not MissionRushData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true
end

return MissionRushData
