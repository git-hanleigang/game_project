--[[
]]

local OutsideGaveRewardData = util_require("activities.Activity_OutsideCave.model.OutsideGaveRewardData")
local OutsideGaveStepRewardData = class("OutsideGaveStepRewardData")

-- message OutsideGaveStepReward {
--     optional int32 steps = 1; //格子数
--     optional OutsideGaveReward reward = 2; //奖励
-- }
function OutsideGaveStepRewardData:parseData(data)
    self.steps = data.steps
    self.reward = nil
    if data:HasField("reward") then
        self.reward = OutsideGaveRewardData:create()
        self.reward:parseData(data.reward)
    end
end

function OutsideGaveStepRewardData:getSteps()
    return self.steps
end

function OutsideGaveStepRewardData:getReward()
    return self.reward
end

return OutsideGaveStepRewardData