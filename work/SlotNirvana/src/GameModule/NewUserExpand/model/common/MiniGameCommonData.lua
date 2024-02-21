--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-23 19:49:15
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-23 19:49:29
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/model/common/MiniGameCommonData.lua
Description: 扩圈小游戏 游戏数据
--]]
local MiniGameCommonData = class("MiniGameCommonData")
local GameTaskPassData = util_require("GameModule.NewUserExpand.model.common.GameTaskPassData")

function MiniGameCommonData:parseData(_data)
    self.m_curIdx = (tonumber(_data.current) or 0) + 1
    self:parseTaskGameData(_data.game)
    self:parseTaskPassListData(_data.pass)
end

function MiniGameCommonData:getGameDataLuaPath()
    return ""
end

-- 当前 游戏数据
function MiniGameCommonData:parseTaskGameData(_gameData)
    if not _gameData then
        return
    end

    if self.m_curTaskGameData then
        self.m_curTaskGameData:parseData(_gameData, self.m_curIdx)
        return
    end
    self.m_curTaskGameData = util_require(self:getGameDataLuaPath()):create()
    self.m_curTaskGameData:parseData(_gameData, self.m_curIdx)
end

-- 任务详情
function MiniGameCommonData:parseTaskPassListData(_taskList)
    if not _taskList or #_taskList == 0 then
        return
    end

    self.m_taskGameList = {}
    self.m_taskMissionList = {}
    self.m_totalPassList = {}
    local bCurMissionOpen = true
    for i=1, #_taskList do
        local taskData = GameTaskPassData:create()
        local serverData = _taskList[i]        
        taskData:parseData(serverData, bCurMissionOpen)
        if taskData:checkIsMission() then
            if not taskData:checkDone() then
                bCurMissionOpen = false
            end
            taskData:setCurTypeIdx(#self.m_taskMissionList + 1)
            taskData:setChapterIdx(#self.m_taskMissionList + 1)
            table.insert(self.m_taskMissionList, taskData)
        else
            taskData:setChapterIdx(#self.m_taskMissionList)
            taskData:setCurTypeIdx(#self.m_taskGameList + 1)
            table.insert(self.m_taskGameList, taskData)
        end

        table.insert(self.m_totalPassList, taskData)
    end
end

function MiniGameCommonData:getCurTaskGameData()
    return self.m_curTaskGameData
end
function MiniGameCommonData:getTaskGameLsit()
    return self.m_taskGameList or {}
end
function MiniGameCommonData:getTaskMisssionLsit()
    return self.m_taskMissionList or {}
end
function MiniGameCommonData:getTotalTaskLsit()
    return self.m_totalPassList or {}
end
function MiniGameCommonData:getCurIdx()
    return self.m_curIdx
end
function MiniGameCommonData:checkGameEnabled()
    if self.m_bEnabled ~= nil then
        return self.m_bEnabled
    end

    self.m_bEnabled = (self.m_curTaskGameData and self.m_totalPassList and self.m_curIdx > 0)
    return self.m_bEnabled
end

-- 获取当前任务 数据
function MiniGameCommonData:getCurTaskData()
    local curIdx = self:getCurIdx()
    local list = self:getTotalTaskLsit()
    return list[curIdx]
end
function MiniGameCommonData:getNextTaskData()
    local curIdx = self:getCurIdx()
    local list = self:getTotalTaskLsit()
    return list[curIdx + 1]
end

-- 获取最后一个任务
function MiniGameCommonData:getLastTaskData()
    local list = self:getTotalTaskLsit()
    return list[#list]
end

-- 获取已完成的最新章节任务数据
function MiniGameCommonData:getHadDoneMissionTaskData()
    local list = self:getTaskMisssionLsit()
    local taskData = nil
    for _, data in pairs(list) do
        if data:checkDone() then
            taskData = data
        else
            break
        end
    end

    return taskData
end

-- 检查是否是最后一个任务
function MiniGameCommonData:checkIsLastTask()
    if self.m_totalPassList then
        return self.m_curIdx == #self.m_totalPassList
    end

    return false
end

return MiniGameCommonData