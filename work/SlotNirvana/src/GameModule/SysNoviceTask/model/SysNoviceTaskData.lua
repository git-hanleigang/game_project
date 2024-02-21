--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-06 11:12:24
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-06 11:12:58
FilePath: /SlotNirvana/src/GameModule/SysNoviceTask/model/SysNoviceTaskData.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local BaseGameModel = require("GameBase.BaseGameModel")
local SysNoviceTaskData = class("SysNoviceTaskData", BaseGameModel)
local SysNoviceTaskConfig = util_require("GameModule.SysNoviceTask.config.SysNoviceTaskConfig")

function SysNoviceTaskData:ctor()
    SysNoviceTaskData.super.ctor(self)

    self._status = SysNoviceTaskConfig.SYS_STATUS.CLOSE
    self._taskInfo = {}
    self:setRefName(G_REF.SysNoviceTask)
end

function SysNoviceTaskData:parseData(_data)
    if not _data then
        return
    end
    SysNoviceTaskData.super.parseData(self, _data)

    
    self._status = _data.status or SysNoviceTaskConfig.SYS_STATUS.CLOSE
    self:parseTaskInfo(_data.task or {})
end

function SysNoviceTaskData:parseTaskInfo(_taskInfo)
    self._taskInfo = {}
    self._taskInfo.seq = _taskInfo.seq --任务顺序
    self._taskInfo.description = _taskInfo.description --任务描述
    self._taskInfo.type = _taskInfo.type --任务类型
    self._taskInfo.progress = _taskInfo.progress --进度
    self._taskInfo.param = _taskInfo.param --参数
    self._taskInfo.coins = _taskInfo.coins --奖励
    self._taskInfo.complete = _taskInfo.complete --完成标记
    self._taskInfo.collect = _taskInfo.collect --领取标记
    self._taskInfo.unlockSysStr = _taskInfo.extra -- 拓展字段，直接转发给客户端 (达到某个等级 解锁的功能)
end

-- 关卡spin更新任务
function SysNoviceTaskData:spinUpdateTaskInfo(_taskInfo)
    self:parseTaskInfo(_taskInfo or {})
end

function SysNoviceTaskData:getSysStatus()
    return self._status
end
-- 任务序号
function SysNoviceTaskData:getTaskIdx()
    return self._taskInfo.seq or 1
end
-- 任务描述
function SysNoviceTaskData:getTaskDesc()
    local desc = string.gsub(self._taskInfo.description or "", "%%S", "%%s")
    if string.find(desc, "%%s") then
        local limit = self:getTaskLimitV()
        desc = string.format(desc, limit)
    end
    return desc
end
-- 任务类型
function SysNoviceTaskData:getTaskType()
    return self._taskInfo.type or ""
end
-- 任务进度
function SysNoviceTaskData:getTaskCurV()
    return tonumber(self._taskInfo.progress) or 0
end
-- 任务参数 要求
function SysNoviceTaskData:getTaskLimitV()
    return tonumber(self._taskInfo.param) or 0
end
-- 任务 奖励金币
function SysNoviceTaskData:getTaskRewardCoins()
    return tonumber(self._taskInfo.coins) or 0
end
-- 任务是否完成
function SysNoviceTaskData:checkIsComplete()
    return self._taskInfo.complete
end
-- 任务是否已领取
function SysNoviceTaskData:checkHadCollect()
    return self._taskInfo.collect
end
-- 是否显示 quest 动画
function SysNoviceTaskData:isShowQuestOpenAct()
    return self._taskInfo.unlockSysStr == "NEWUSERQUEST"
end

-- 进度百分比
function SysNoviceTaskData:getPercent()
    local cur = self:getTaskCurV()
    local total = self:getTaskLimitV()
    if total == 0 then
        return 0
    end

    return math.floor(cur / total * 100)
end

-- 是否可以领取
function SysNoviceTaskData:checkCanCollect()
    -- 完成为领取
    if self:checkIsComplete() and not self:checkHadCollect() then
        return true
    end

    return false
end

function SysNoviceTaskData:isRunning()
    local status = self:getSysStatus()
    return status == SysNoviceTaskConfig.SYS_STATUS.OPEN
end

return SysNoviceTaskData