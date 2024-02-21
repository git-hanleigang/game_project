
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local XmasCraze2023Data = class("XmasCraze2023Data", BaseActivityData)

--[[
    message HolidayNewChallengeCraze {
        optional string activityId = 1; // 活动的id
        optional string activityName = 2;// 活动的名称
        optional string begin = 3;// 活动的开启时间
        optional int64 expireAt = 4; // 活动倒计时

        optional string rewardPoll = 5;// 奖池
        optional bool paid = 6;// 是否付过费
        optional string preRewardPoll = 7;// 前一个奖池
    }
]]

function XmasCraze2023Data:parseData(_data)
    XmasCraze2023Data.super.parseData(self, _data)

    self.p_rewardPoll = _data.rewardPoll
    self.p_paid = _data.paid
    self.p_preRewardPoll = _data.preRewardPoll
end

function XmasCraze2023Data:getRewardPoll()
    if self.p_rewardPoll == "" then
        return "0"
    end
    return self.p_rewardPoll or "0"
end

function XmasCraze2023Data:isPaid()
    return true == self.p_paid
end

function XmasCraze2023Data:getPreRewardPoll()
    if self.p_preRewardPoll == "" then
        return "0"
    end
    return self.p_preRewardPoll or "0"
end

return XmasCraze2023Data
