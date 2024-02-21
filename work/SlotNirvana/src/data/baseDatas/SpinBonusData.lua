-- message SpinBonusConfig {
--     optional string activityId = 1; //活动id
--     optional string activityName = 2; //活动名称
--     optional int64 expireAt = 3; //截止时间
--     optional int32 expire = 4; //剩余时间
--     optional bool collected = 5; //已经领取过
--     optional CommonRewards rewards = 6; //奖励
--     optional int32 target = 7; //目标，100表示100次spin
--     optional int32 current = 8; //当前spin次数
--     optional bool completed = 9; // 是否完成任务
--     optional int32 taskExpire = 10; //任务剩余多少时间完成
--     optional int64 taskExpireAt = 11; //任务截止日期时间戳
--   }
local CommonRewards = require "data.baseDatas.CommonRewards"
local SpinBonusData = class("SpinBonusData")

function SpinBonusData:ctor()

end

function SpinBonusData:parseData(data)
    self.p_activityId = data.activityId
    self.p_activityName = data.activityName
    self.p_expireAt = tonumber(data.expireAt)
    self.p_expire = tonumber(data.expire)
    self.p_collected = data.collected
    if data.rewards then
        self.p_rewards =  CommonRewards:create()
        self.p_rewards:parseData(data.rewards)
    end
    self.p_target = tonumber(data.target)
    self.p_current = tonumber(data.current)
    self.p_completed = data.completed
    self.p_taskExpire = tonumber(data.taskExpire)
    self.p_taskExpireAt = tonumber(data.taskExpireAt)
    self.p_coinsUpTo = tonumber(data.coinsUpTo)

end

function SpinBonusData:getRewardCoins()
    if self.p_rewards and self.p_rewards.coins then
        return self.p_rewards.coins
    end
    return 0
end

function SpinBonusData:getCanCollect()
    if self.p_completed and not self.p_collected then
        return true
    end
    return false
end

--是否开启
function SpinBonusData:isTaskOpen()
    if not self.p_taskExpireAt then
        return false
    end
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    if self.p_taskExpireAt == 0 or curTime>=self.p_taskExpireAt/1000 or self.p_taskExpire<=0 then
        return false
    end
    if self.p_collected then
        return false
    end
    return true
end

--是否开启
function SpinBonusData:isActivityOpen()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
    end
    if self.p_expireAt == 0 or curTime>=self.p_expireAt/1000 or self.p_expire <= 0 then
            return false
    end
    if self.p_collected then
        return false
    end
    return true
end

return  SpinBonusData