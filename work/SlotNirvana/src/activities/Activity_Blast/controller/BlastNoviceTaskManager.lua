--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-26 12:16:14
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-26 12:16:19
FilePath: /SlotNirvana/src/activities/Activity_Blast/controller/BlastNoviceTaskManager.lua
Description: 新手blast 任务 mgr
--]]
local BlastNoviceTaskManager = class("BlastNoviceTaskManager", BaseActivityControl)
local BlastNet = require("activities.Activity_Blast.net.BlastNet")

function BlastNoviceTaskManager:ctor()
    BlastNoviceTaskManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BlastNoviceTask)
    self:addPreRef(ACTIVITY_REF.Blast)

    self.m_blastNet = BlastNet:getInstance()
end

function BlastNoviceTaskManager:parseData(_data)
    local actData = self:getData()
    if not actData then
        return
    end

    actData:parseData(_data)
end

-- 检查当前任务是否完成但未领奖
function BlastNoviceTaskManager:checkTaskCompletedAndGoReward()
    if not self:isRunning() then
        return false
    end

    local data = self:getData()
    local missionData = data:getCurMissionData() 
    if not missionData then
        return false
    end
    return missionData:checkCompleted() and not missionData:checkHadSendReward()
end

-- 显示主界面
function BlastNoviceTaskManager:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByName("BlastNoviceTaskMainLayer") then
        return
    end

    local view = util_createView("activities.Activity_Blast.views.noviceTask.BlastNoviceTaskMainLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示奖励界面
function BlastNoviceTaskManager:showRewardLayer(_missionData)
    if not self:isCanShowLayer() or not _missionData then
        return
    end

    if gLobalViewManager:getViewByName("BlastNoviceTaskRewardLayer") then
        return
    end

    local view = util_createView("activities.Activity_Blast.views.noviceTask.BlastNoviceTaskRewardLayer", _missionData)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function BlastNoviceTaskManager:sendNoviceTaskCollectReq(_activityType, _phaseIdx)
    self.m_blastNet:sendNoviceTaskCollectReq(_activityType, _phaseIdx)
end

-- 弹板名
function BlastNoviceTaskManager:getPopModule()
    return "activities.Activity_Blast.views.noviceTask.BlastNoviceTaskMainLayer"
end

return BlastNoviceTaskManager
