--[[
]]

-- message ChaseForChipsTaskData {
--     optional int32 points = 1; //完成任务获得的点数
--     optional string taskType = 2; //任务卡片的类型
--     optional int32 current = 3; //当前的进度
--     repeated int32 goals = 4;//每个小目标
--     optional string desc = 5;//任务的描述
--     optional int32 finishTimes = 6;//任务的完成次数
--     optional string cardType = 7; //卡片类型
--     optional int32 star = 8; //卡片的星级
--   }
local ChaseForChipsTaskData = class("ChaseForChipsTaskData")

function ChaseForChipsTaskData:parseData(_netData)
    self.p_rewardPoints = _netData.points
    self.p_taskType = _netData.taskType

    -- 累加的当前进度
    self.p_current = _netData.current
    
    -- 累加的目标值
    self.p_goals = {}
    if _netData.goals and #_netData.goals > 0 then
        for i = 1, #_netData.goals do
            table.insert(self.p_goals, _netData.goals[i])
        end
    end
    -- 每个阶段的目标差值
    self.p_diffGoals = {}
    if self.p_goals and #self.p_goals > 0 then
        local start = 0
        for i=1,#self.p_goals do
            table.insert(self.p_diffGoals, self.p_goals[i] - start)
            start = self.p_goals[i]
        end
    end

    self.m_desc = _netData.desc

    -- 已完成的次数
    self.p_finishTimes = _netData.finishTimes
    -- 总共可完成的次数
    self.m_totalTimes = #self.p_diffGoals

    -- 新增卡类型
    self.p_cardType = _netData.cardType
    -- 新增星
    self.p_star = _netData.star

    -- 当前进度
    self.m_curPro = 0
    if self.p_finishTimes == 0 then
        self.m_curPro = self.p_current
    elseif self.p_finishTimes == #self.p_diffGoals then
        self.m_curPro = self.p_diffGoals[#self.p_diffGoals]
    else
        if self.p_goals and #self.p_goals > 0 then
            local preMaxPro = self.p_goals[self.p_finishTimes]
            self.m_curPro = math.max(0, self.p_current - preMaxPro)
        end
    end
    -- 当前进度最大值
    self.m_maxPro = self.p_diffGoals[math.min(#self.p_diffGoals, self.p_finishTimes+1)]
end

function ChaseForChipsTaskData:getRewardPoints()
    return self.p_rewardPoints
end

function ChaseForChipsTaskData:getTaskType()
    return self.p_taskType
end

function ChaseForChipsTaskData:getCurrent()
    return self.p_current
end

function ChaseForChipsTaskData:getGoals()
    return self.p_goals
end

function ChaseForChipsTaskData:getFinishTimes()
    return self.p_finishTimes
end

function ChaseForChipsTaskData:getDesc()
    return self.m_desc
end

function ChaseForChipsTaskData:getGoalByIndex(_index)
    if self.p_goals and #self.p_goals > 0 then
        return self.p_goals[_index]
    end
    return
end

function ChaseForChipsTaskData:getDiffGoalByIndex(_index)
    if self.p_diffGoals and #self.p_diffGoals > 0 then
        return self.p_diffGoals[_index]
    end
    return
end

function ChaseForChipsTaskData:getCurPro()
    return self.m_curPro
end

function ChaseForChipsTaskData:getMaxPro()
    return self.m_maxPro
end

function ChaseForChipsTaskData:getTotalTimes()
    return self.m_totalTimes
end

function ChaseForChipsTaskData:getCardType()
    return self.p_cardType
end

function ChaseForChipsTaskData:getStar()
    return self.p_star
end

return ChaseForChipsTaskData