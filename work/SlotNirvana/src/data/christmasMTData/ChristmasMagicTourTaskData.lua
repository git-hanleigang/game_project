--[[
    等级及宝箱数据
    author:{author}
    time:2020-09-24 11:17:17
]]
-- FIX IOS 139
local ChristmasMagicTourTaskData = class("ChristmasMagicTourTaskData")

function ChristmasMagicTourTaskData:ctor()
    self.m_taskType = ""            -- 任务类型
    self.m_taskIndex = 1            -- 小任务序号
    self.m_points = 0               -- 奖励点数
    self.m_icon = ""                -- 资源图
    self.m_description = ""         -- 描述
    self.m_status = ""              -- 任务状态(init/completed/tomorrow/allDone/comeSoon)
    self.m_unCollectedNums = 0      -- 未领取次数
    self.m_taskSeq = 1              -- 任务排序
end

function ChristmasMagicTourTaskData:parseData(data)
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
end

function ChristmasMagicTourTaskData:getTaskType( )
    return self.m_taskType
end

function ChristmasMagicTourTaskData:getTaskIndex( )
    return self.m_taskIndex
end

function ChristmasMagicTourTaskData:getPoints( )
    return self.m_points
end

function ChristmasMagicTourTaskData:getIcon( )
    return self.m_icon
end

function ChristmasMagicTourTaskData:getStatus( )
    return self.m_status
end

function ChristmasMagicTourTaskData:getDescription( )
    return self.m_description
end

function ChristmasMagicTourTaskData:getUnCollectedNums( )
    return self.m_unCollectedNums
end

function ChristmasMagicTourTaskData:getTaskSeqID( )
    return self.m_taskSeq
end

return ChristmasMagicTourTaskData
