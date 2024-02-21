--[[
    任务数据
    author:{author}
    time:2020-09-24 11:17:17 
]]
-- FIX IOS 139
local HolidayChallengeTaskData = class("HolidayChallengeTaskData")

function HolidayChallengeTaskData:ctor()
    self.m_taskType = ""            -- 任务类型
    self.m_taskIndex = 1            -- 小任务序号
    self.m_points = 0               -- 奖励点数
    self.m_icon = ""                -- 资源图
    self.m_description = ""         -- 描述
    self.m_status = ""              -- 任务状态(init/completed/tomorrow/allDone/comeSoon)
    self.m_unCollectedNums = 0      -- 未领取次数
    self.m_taskSeq = 1              -- 任务排序
    self.m_countLimit = 1           -- 任务限制次数
    self.m_completeCount = 0        -- 完成次数
    self.m_progress = 0             -- 当前进度
    self.m_progressMax = 1          -- 进度最大值
end

function HolidayChallengeTaskData:parseData(data)
    if not data then
        return
    end
    self.m_taskType =       data.taskType
    self.m_taskIndex =      data.taskIndex
    self.m_points =         data.points
    self.m_icon =           data.icon
    self.m_description =    data.description
    self.m_status =         data.status
    self.m_unCollectedNums = data.unCollected
    self.m_taskSeq =        data.taskSeq
    self.m_countLimit =     data.countLimit
    self.m_completeCount =  data.completeCount
    self.m_progress   =     data.progress
    self.m_progressMax   =  data.progressMax
end

function HolidayChallengeTaskData:getTaskType( )
    return self.m_taskType
end

function HolidayChallengeTaskData:getTaskIndex( )
    return self.m_taskIndex
end

function HolidayChallengeTaskData:getPoints( )
    return self.m_points
end

function HolidayChallengeTaskData:getIcon( )
    return self.m_icon
end

function HolidayChallengeTaskData:getStatus( )
    return self.m_status
end

function HolidayChallengeTaskData:getDescription( )
    return self.m_description
end

function HolidayChallengeTaskData:getUnCollectedNums( )
    return self.m_unCollectedNums
end

function HolidayChallengeTaskData:getTaskSeqID( )
    return self.m_taskSeq
end

function HolidayChallengeTaskData:getCountLimit( )
    return self.m_countLimit
end

function HolidayChallengeTaskData:getCompleteCount( )
    return self.m_completeCount
end

function HolidayChallengeTaskData:getProgress( )
    return self.m_progress
end

function HolidayChallengeTaskData:getProgressMax( )
    return self.m_progressMax
end

return HolidayChallengeTaskData
