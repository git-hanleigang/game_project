

-- FB粉丝200k达成送奖

--message FacebookAttentionReward {
--    optional bool reward = 1;
--    optional int64 coins = 2;//金币数
--    optional int64 expireAt = 3; //活动结束时间
--    optional int64 expire = 4; //活动剩余时间
--    optional int32 startLevel = 5; //开始等级
--    optional string activityId = 6; //活动id
--    optional string activityName = 7; //活动名称
--    optional int64 activityStart = 8; //活动开始时间
--}

local BaseActivityData = require("baseActivity.BaseActivityData")
local FBGift200kData = class("FBGift200kData", BaseActivityData)

function FBGift200kData:ctor()
    FBGift200kData.super.ctor(self)
    self.p_open = true
end

function FBGift200kData:parseData(data)
    self.bl_reward = data.reward
    self.coins = data.coins
end

function FBGift200kData:isCollected()
    return self.bl_reward
end

function FBGift200kData:getCoins()
    return tonumber(self.coins) or 0
end

return FBGift200kData
