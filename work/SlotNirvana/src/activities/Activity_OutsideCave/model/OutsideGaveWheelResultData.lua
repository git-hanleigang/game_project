--[[
]]
local OutsideGaveRewardData = util_require("activities.Activity_OutsideCave.model.OutsideGaveRewardData")
local OutsideGaveWheelResultData = class("OutsideGaveWheelResultData")

--[[
    optional int position 本次中的轮盘位置
    repeated int positions 所有中的轮盘位置
    以下数据都是轮盘次数消耗完后才发送
    optional int rewardSteps 奖励的总步数 
    optional OutsideGaveReward reward 轮盘奖励
    optional OutsideGaveReward stageReward 章节奖励
    optional OutsideGaveReward roundReward 轮次奖励
    optional OutsideGaveReward stepReward 步数奖励【即砸龙蛋的道具】
]]
function OutsideGaveWheelResultData:parseData(data)
    self.position = data.position

    self.hitPositions = {}
    if data.positions and #data.positions > 0 then
        for i=1,#data.positions do
            table.insert(self.hitPositions, data.positions[i])
        end
    end

    self.rewardSteps = data.rewardSteps

    self.reward = nil
    if data.reward ~= nil and next(data.reward) ~= nil then
        local rData = OutsideGaveRewardData:create()
        rData:parseData(data.reward)
        if rData:isEffective() then
            self.reward = rData
        end
    end
end

function OutsideGaveWheelResultData:getHitPosition()
    return self.position
end

function OutsideGaveWheelResultData:getHitPositions()
    return self.hitPositions
end

function OutsideGaveWheelResultData:getRewardSteps()
    return self.rewardSteps
end

function OutsideGaveWheelResultData:getWheelReward()
    return self.reward
end

return OutsideGaveWheelResultData