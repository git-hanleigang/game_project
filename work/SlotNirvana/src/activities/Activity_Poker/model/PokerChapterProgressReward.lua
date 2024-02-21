--[[--
]]
local CommonRewards = require "data.baseDatas.CommonRewards"
local PokerChapterProgressReward = class("PokerChapterProgressReward")

function PokerChapterProgressReward:ctor()
end

function PokerChapterProgressReward:parseData(_netData)
    self.p_rewards = CommonRewards:create()
    self.p_rewards:parseData(_netData.rewards)

    self.p_posChips = tonumber(_netData.posChips) -- 奖励所在的位置
end

function PokerChapterProgressReward:getRewards()
    return self.p_rewards
end

function PokerChapterProgressReward:getPosChips()
    return self.p_posChips
end

return PokerChapterProgressReward
