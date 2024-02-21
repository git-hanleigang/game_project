--[[
Author: cxc
Date: 2022-01-10 12:13:46
LastEditTime: 2022-01-10 13:59:58
LastEditors: your name
Description: Lottery乐透 挑战活动 数据
FilePath: /SlotNirvana/src/activities/Activity_LotteryChallenge/model/LotteryChallengeData.lua
--]]
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local LotteryChallengeTaskData = util_require("activities.Activity_LotteryChallenge.model.LotteryChallengeTaskData")
local LotteryChallengeData = class("LotteryChallengeData", BaseActivityData)

function LotteryChallengeData:parseData(_data)
    LotteryChallengeData.super.parseData(self, _data)
    -- message LotteryChallenge {
    --     optional string activityId = 1;
    --     optional string activityName = 2;
    --     optional string referenceName = 3;
    --     optional int64 expireAt = 4;
    --     optional int32 expire = 5;
    --     repeated LotteryChallengeGoalResult goals = 6;
    --     optional int32 progress = 7;
    --   }
    self.m_taskList = {}
    local list = _data.goals or {}
    for i=1, #list do
        local info = list[i]
        local taskData = LotteryChallengeTaskData:create(info)
        table.insert(self.m_taskList, taskData)
    end

    self.m_taskCur = _data.progress or 0 -- 任务当前完成值
end

function LotteryChallengeData:getTaskList()
    return self.m_taskList or {}
end

function LotteryChallengeData:getTaskCur()
    return self.m_taskCur or 0
end

return LotteryChallengeData
