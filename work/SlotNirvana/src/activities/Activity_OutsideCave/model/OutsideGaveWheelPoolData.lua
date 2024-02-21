--[[
]]
local OutsideGaveRewardData = util_require("activities.Activity_OutsideCave.model.OutsideGaveRewardData")
local OutsideGaveWheelPoolData = class("OutsideGaveWheelPoolData")

-- message OutsideGaveWheelPool {
--     optional int32 position = 1; //位置
--     optional string type = 2; //类型 ITEM COIN FORWARD
--     optional OutsideGaveReward reward = 3; //奖励
--     optional int32 steps = 4; //获得的步数 类型 = FORWARD
--     optional int32 rare = 5; //稀有程度
-- }
function OutsideGaveWheelPoolData:parseData(data)
    
    self.position = data.position
    self.type = data.type

    self.reward = nil
    if data:HasField("reward") then
        self.reward = OutsideGaveRewardData:create()
        self.reward:parseData(data.reward)
    end

    self.steps = data.steps
    self.rare = data.rare
end

function OutsideGaveWheelPoolData:getPosition()
    return self.position
end

function OutsideGaveWheelPoolData:getType()
    return self.type
end

function OutsideGaveWheelPoolData:getReward()
    return self.reward
end

function OutsideGaveWheelPoolData:getSteps()
    return self.steps
end

function OutsideGaveWheelPoolData:getRare()
    return self.rare
end

return OutsideGaveWheelPoolData