--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-23 10:24:31
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-23 19:57:43
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/model/common/GameTaskPassData.lua
Description: 扩圈小游戏 任务数据
--]]
local GameTaskPassData = class("GameTaskPassData")
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")

function GameTaskPassData:parseData(_data, _bCurChapterOpen)
    self.m_seq = _data.seq or 0 -- pass序号
    self.m_taskType = _data.type or "" -- 类型 GAME,LEVEL
    self.m_value = _data.param or 0 -- 进度
    self.m_status = tonumber(_data.status) or 0 -- 任务状态 0未解锁 1已解锁 2已完成 3已通过或已领取奖励
    if not _bCurChapterOpen then
        self.m_status = -1
    end
    self.m_desc = _data.description or "" -- 描述
    if self.m_taskType == "LEVEL" then
        self.m_desc = string.format("Unlocks at Level %s", self.m_value)
    end
end

-- 当前任务类型 idx
function GameTaskPassData:setCurTypeIdx(_idx)
    self.m_curIdx = _idx
end
function GameTaskPassData:getCurTypeIdx()
    return self.m_curIdx or 0
end

-- 所属章节idx
function GameTaskPassData:setChapterIdx(_idx)
    self.m_curChapterIdx = _idx
end
function GameTaskPassData:getChapterIdx()
    return self.m_curChapterIdx or 0
end

-- 整个任务中该任务 所属序号
function GameTaskPassData:getSeq()
    return self.m_seq or 0
end
function GameTaskPassData:getDesc()
    return self.m_desc or ""
end
function GameTaskPassData:getTaskType()
    return self.m_taskType or ""
end
function GameTaskPassData:checkIsMission()
    return self.m_taskType == "LEVEL"
end
function GameTaskPassData:getProgValue()
    return self.m_value or 0
end
function GameTaskPassData:getStatus()
    return self.m_status or 0
end
function GameTaskPassData:checkDone()
    return self:getStatus() >= 2
end
function GameTaskPassData:checkPass()
    return self:getStatus() > 2
end
function GameTaskPassData:getState()
    local state = NewUserExpandConfig.TASK_STATE.LOCK
    if self.m_status == 1 then
        state = NewUserExpandConfig.TASK_STATE.UNLOCK
    elseif self:checkDone() then
        state = NewUserExpandConfig.TASK_STATE.DONE
    end

    return state
end

return GameTaskPassData