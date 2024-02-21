--[[
    圣诞聚合 -- pass
]]
local HolidayTaskData = class("HolidayTaskData")

--[[
    message HolidayNewChallengePassTask {
        optional int32 points = 1;//完成任务获得点数
        optional string description = 2;// 任务描述
        optional string taskType = 3;// 任务类型  NO_LIMIT：无线次数 NUM_LIMIT:有限次数但每次奖励一样 REWARD_LIMIT:有限次数但每次奖励不一样
        optional int32 finishTimes = 4;// 完成次数
        optional int32 limit = 5; // 总共的限制
        optional bool finished = 6; // 是否已经完成
    }
]]
function HolidayTaskData:parseData(_data)
    self.p_points = tonumber(_data.points)
    self.p_description = _data.description
    self.p_taskType = _data.taskType
    self.p_taskSeq = tonumber(_data.taskSeq)
    self.p_finishTimes = tonumber(_data.finishTimes)
    self.p_targetTimes = tonumber(_data.limit)
    self.p_completed = _data.finished
end

function HolidayTaskData:getPoints()
    return self.p_points or 0
end

function HolidayTaskData:getDescription()
    return self.p_description or ""
end

function HolidayTaskData:getTaskSeq()
    return self.p_taskSeq
end

function HolidayTaskData:getFinishTimes()
    return self.p_finishTimes or 0
end

function HolidayTaskData:getTargetTimes()
    return self.p_targetTimes or 0
end

function HolidayTaskData:getCompleted()
    return self.p_completed
end

return HolidayTaskData
