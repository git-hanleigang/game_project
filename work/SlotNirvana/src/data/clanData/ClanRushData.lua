--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-21 17:33:50
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-21 17:41:11
FilePath: /SlotNirvana/src/data/clanData/ClanRushData.lua
Description: 公会rush数据
--]]
local ClanRushData = class("ClanRushData")
local ClanRushTaskData = util_require("data.clanData.ClanRushTaskData")

function ClanRushData:ctor()
    self.m_expireAt = 0 -- 过期时间
    self.m_curIdx = 1 -- 当前位置
    self.m_taskList = {} -- 任务详细信息
end

function ClanRushData:parseData(_data)
    if not _data then
        return
    end

    self.m_expireAt = tonumber(_data.expireAt) or 0
    self.m_curIdx = (tonumber(_data.current) or 0) + 1
    self:parseTaskData(_data.tasks or {})

    self:parseRecordData()
end

function ClanRushData:parseTaskData(_list)
    self.m_taskList = {}
    for i, _info in ipairs(_list) do
        local data = ClanRushTaskData:create(i)
        data:parseData(_info)
        table.insert(self.m_taskList, data)
    end
    if self.m_curIdx > #self.m_taskList then
        self.m_curIdx = #self.m_taskList
    end
end

function ClanRushData:parseRecordData()
    if self.m_expireAt == self.m_recordExpireAt then
        self.m_bCompleteCurTask = self.m_curIdx > self.m_recordCurIdx
        if self.m_recordCurIdx == self:getTaskListCount() then
            local recordTaskData = self:getCurTaskData(true)
            local taskData = self:getCurTaskData()
            self.m_bCompleteCurTask = not recordTaskData:checkTaskFinish() and taskData:checkTaskFinish()
        end
    else
        self:resetRecordData()
    end
end
function ClanRushData:resetRecordData()
    self.m_recordExpireAt = self.m_expireAt
    self.m_recordCurIdx = self.m_curIdx
    self.m_recordTaskList = clone(self.m_taskList)
    self.m_bCompleteCurTask = false
end


-- 过期时间
function ClanRushData:getExpireAt()
    return math.floor(self.m_expireAt * 0.001)
end

-- 当前任务位置
function ClanRushData:getCurTaskIdx(_bRecord)
    if _bRecord then
        return self.m_recordCurIdx
    end
    return self.m_curIdx
end

-- 任务列表
function ClanRushData:getTaskList(_bRecord)
    if _bRecord then
        return self.m_recordTaskList
    end
    return self.m_taskList
end

-- 获取任务个数
function ClanRushData:getTaskListCount()
    return #self.m_taskList
end

-- 获取当前任务
function ClanRushData:getCurTaskData(_bRecord)
    if _bRecord then
        return self.m_recordTaskList[self.m_recordCurIdx] or ClanRushTaskData:create()
    end

    return self.m_taskList[self.m_curIdx] or ClanRushTaskData:create()
end

function ClanRushData:isRunning()
    local curTime = util_getCurrnetTime()
    if curTime >= self:getExpireAt() then
        return false
    end 

    return #self.m_taskList > 0
end

-- 是否完成了新任务
function ClanRushData:isCompleteCurTask()
    return self.m_bCompleteCurTask
end
-- 玩家自己有没有参与刚完成的任务
function ClanRushData:isJoinPreTask()
    local preTaskData = self.m_taskList[self.m_curIdx-1]
    if preTaskData then
        return preTaskData:checkSelfIsJoinTask()
    end 
    return false
end

return ClanRushData