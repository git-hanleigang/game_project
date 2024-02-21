--新版限时活动
local BaseActivityData = require "baseActivity.BaseActivityData"
local NewDCLimitRewardData = require("activities.Activity_NewDiamondChallengeRush.model.NewDCRushRewardData")
local ShopItem = require "data.baseDatas.ShopItem"

local NewDCRushData = class("NewDCRushData", BaseActivityData)

-- message LuckyChallengeV2TimeLimit {
--   optional string activityId = 1; // 活动的id
--   optional string activityName = 2;// 活动的名称
--   optional string begin = 3;// 活动的开启时间
--   optional string end = 4;// 活动的结束时间
--   optional int64 expireAt = 5; // 活动倒计时
--   optional int32 curProgress = 6;// 当前进度
--   optional int32 totalProgress = 7; // 总进度
--   repeated LuckyChallengeV2TimeLimitReward rewards = 8;// 奖励数据
-- }
function NewDCRushData:ctor()
    NewDCRushData.super.ctor(self)
end

function NewDCRushData:parseData(data)
    NewDCRushData.super.parseData(self, data)
    self.m_curProgress = data.curProgress
    self.m_totalProgress = data.totalProgress
    if data.rewards and #data.rewards > 0 then
        self.m_reward = {}
        for i,v in ipairs(data.rewards) do
            if i <= 6 then
                local item = NewDCLimitRewardData:create()
                item:parseData(v)
                table.insert(self.m_reward,item)
            end
        end
    end
end

function NewDCRushData:getCurProgress()
    return self.m_curProgress or 0
end

function NewDCRushData:getTotalProgress()
    return self.m_totalProgress or 0
end

function NewDCRushData:getItems()
    return self.m_reward or {}
end

return NewDCRushData
