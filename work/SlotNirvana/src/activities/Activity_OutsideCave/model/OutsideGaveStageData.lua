--[[
]]

local OutsideGaveRewardData = util_require("activities.Activity_OutsideCave.model.OutsideGaveRewardData")
local OutsideGaveStepRewardData = util_require("activities.Activity_OutsideCave.model.OutsideGaveStepRewardData")

local OutsideGaveStageData = class("OutsideGaveStageData")

-- message OutsideGaveStage {
--     optional int32 stage = 1; //章节数
--     optional int32 steps = 2; //本关地图共有几格
--     optional int32 curStep = 3; //当前处于第几个格子
--     repeated OutsideGaveStepReward stepRewards = 4; //格子奖励
--     optional OutsideGaveReward stageReward = 5; //章节奖励
-- }
function OutsideGaveStageData:parseData(data)
    self.stage = data.stage
    self.steps = data.steps
    self.curStep = data.curStep

    self.stepRewards = {}
    if data.stepRewards and #data.stepRewards > 0 then
        for i=1,#data.stepRewards do
            local reward = OutsideGaveStepRewardData:create()
            reward:parseData(data.stepRewards[i])
            table.insert(self.stepRewards, reward)
        end
    end
    
    self.stageReward = nil
    if data:HasField("stageReward") then
        self.stageReward = OutsideGaveRewardData:create()
        self.stageReward:parseData(data.stageReward)
    end
end

function OutsideGaveStageData:getStage()
    return self.stage
end

function OutsideGaveStageData:getSteps()
    return self.steps
end

function OutsideGaveStageData:getCurStep()
    return math.max(1, self.curStep)
end

function OutsideGaveStageData:getStepRewards()
    return self.stepRewards
end

function OutsideGaveStageData:getStageReward()
    return self.stageReward
end

function OutsideGaveStageData:getStepRewardDataByStepId(_stepId)
    if _stepId and _stepId > 0 and self.stepRewards and #self.stepRewards > 0 then
        for i=1,#self.stepRewards do
            local stepRewardData = self.stepRewards[i]
            if stepRewardData:getSteps() == _stepId then
                local reward = stepRewardData:getReward()
                return reward
            end
        end
        -- local stepRewardData = self.stepRewards[_stepId]
        -- if stepRewardData then
        --     return stepRewardData:getReward()
        -- end
    end
    return 
end

return OutsideGaveStageData