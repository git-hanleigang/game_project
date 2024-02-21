--[[
    @desc: season mission rush 活动
    author:csc
    time:2021-08-13 15:27:54
]]
local ShopItem = require("data.baseDatas.ShopItem")
local BaseActivityData = require("baseActivity.BaseActivityData")
local SeasonMissionRushData = class("SeasonMissionRushData",BaseActivityData)

-- optional int32 expire = 1; //剩余秒数
-- optional int64 expireAt = 2; //过期时间
-- optional string activityId = 3; //活动id
-- optional string name = 4; //活动名字
-- optional int32 progress = 5; //完成进度
-- optional int32 progressMax = 6; //总进度
-- optional bool collected = 7; // 是否领取
-- optional int64 coins = 8;
-- repeated ShopItem items = 9;

function SeasonMissionRushData:ctor()
    SeasonMissionRushData.super.ctor(self)
    self.m_progress = 0
    self.m_progressMax = 0
    self.m_bCollected = false
    self.m_coins = nil
    -- 奖励道具
    self.m_rewards = {}
end

function SeasonMissionRushData:parseData(data)
    if not data then
        return
    end
    SeasonMissionRushData.super.parseData(self, data)

    self.m_progress = data.progress
    self.m_progressMax = data.progressMax
    self.m_bCollected = data.collected
    self.m_coins = data.coins

    if #data.items > 0 then
        for i = 1, #data.items do
            local _item = ShopItem:create()
            _item:parseData(data.items[i])
            table.insert(self.m_rewards, _item)
        end
    end
end

function SeasonMissionRushData:getRewards()
    return self.m_rewards
end

function SeasonMissionRushData:getCollected( )
    return self.m_bCollected
end

function SeasonMissionRushData:getCurProgress()
    return self.m_progress
end

function SeasonMissionRushData:getMaxProgress( )
    return self.m_progressMax
end

-- 重写领奖弹板
function SeasonMissionRushData:getRewardLayer()
    local _filePath = "Activity/" .. self:getThemeName().."RewardLayer"
    if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
        local _module, count = string.gsub(_filePath, "/", ".")
        return _module
    end
    return ""
end

function SeasonMissionRushData:getSoundPath()
    return "Activity/SeasonMissionRush/sound/seasonmissionrush_openrewardlayer.mp3"
end

function SeasonMissionRushData:checkCompleteCondition()
    if self.m_bCollected then
        return true
    end
    return false
end
return SeasonMissionRushData
