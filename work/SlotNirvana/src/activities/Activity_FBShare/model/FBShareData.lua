--[[--
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local FBGroupData = class("FBGroupData", BaseActivityData)

function FBGroupData:ctor()
    FBGroupData.super.ctor(self)
    self.p_open = true
end

-- message FacebookShareConfig {
--     optional int32 expire = 1; //剩余秒数
--     optional int64 expireAt = 2; //过期时间
--     optional string activityId = 3; //活动id
--     optional string begin = 4;
--     optional bool collected = 5;
--     optional int64 coins = 6;
--   }
function FBGroupData:parseData(_netData)
    FBGroupData.super.parseData(self, _netData)
    self.p_begin = _netData.begin
    self.p_collected = _netData.collected
    self.p_coins = tonumber(_netData.coins)
end

function FBGroupData:isTodayCollected()
    return self.p_collected
end

function FBGroupData:getCoins()
    return self.p_coins
end

-- 发奖时间计算
function FBGroupData:getRewardTime()
    -- local curTime = os.time()
    -- if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
    --     curTime = globalData.userRunData.p_serverTime / 1000
    -- end
    local leftTime = self:getExpireAt() + ONE_DAY_TIME_STAMP
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

return FBGroupData
