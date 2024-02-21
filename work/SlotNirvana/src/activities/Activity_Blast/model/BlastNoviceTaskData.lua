--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-27 14:20:15
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-29 10:45:50
FilePath: /SlotNirvana/src/activities/Activity_Blast/model/BlastNoviceTaskData.lua
Description: 新手blast 任务  数据
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local BlastNoviceTaskData = class("BlastNoviceTaskData", BaseActivityData)
local BlastNoviceTaskDetailData = util_require("activities.Activity_Blast.model.BlastNoviceTaskDetailData")

function BlastNoviceTaskData:ctor()
    self.m_missionList = {} -- 任务列表
    self.m_curPhaseIdx = 0
end

function BlastNoviceTaskData:parseData(_list)
    if not _list then
        return
    end

    self.m_missionList = {} -- 任务列表
    self.m_curPhaseIdx = 0
    for idx=1, #_list do
        local missionData = BlastNoviceTaskDetailData:create()
        missionData:parseData(_list[idx])

        if not missionData:checkHadSendReward() and self.m_curPhaseIdx == 0 then
            -- 没领奖
            self.m_curPhaseIdx = idx
        end

        table.insert(self.m_missionList, missionData)
    end

    if self.m_curPhaseIdx == 0 then
        self.m_curPhaseIdx = #_list
    end
    self.p_open = (#self.m_missionList > 0 and self:getThemeName() == "Activity_BlastTaskBlossom")
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_UPDATE_DATA)
end

-- 任务列表
function BlastNoviceTaskData:getMissionList()
    return self.m_missionList
end
function BlastNoviceTaskData:getMissionDataByIdx(_idx)
    return self.m_missionList[_idx]
end
function BlastNoviceTaskData:getCurMissionData()
    return self.m_missionList[self.m_curPhaseIdx]
end

-- 当前任务 阶段
function BlastNoviceTaskData:getCurPhaseIdx()
    return self.m_curPhaseIdx
end

return BlastNoviceTaskData