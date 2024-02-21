--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-27 17:44:55
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-27 17:45:20
FilePath: /SlotNirvana/src/activities/Activity_Blast/views/noviceTask/BlastNoviceTaskEntry.lua
Description: 新手blast 任务 入口
--]]
local BlastNoviceTaskEntry = class("BlastNoviceTaskEntry", BaseView)

function BlastNoviceTaskEntry:initDatas()
    BlastNoviceTaskEntry.super.initDatas(self)

    self.m_data = G_GetMgr(ACTIVITY_REF.BlastNoviceTask):getData()
end

function BlastNoviceTaskEntry:initCsbNodes()
end

function BlastNoviceTaskEntry:getCsbName()
    return "Activity_Mission/csd/COIN_BLAST_MissionBlossomEntryNode.csb"
end

function BlastNoviceTaskEntry:initUI()
    BlastNoviceTaskEntry.super.initUI(self)

    self:updateTaskProgress()
    gLobalNoticManager:addObserver(self, "updateTaskProgress", ViewEventType.NOTIFY_ACTIVITY_TASK_UPDATE_DATA)
end

function BlastNoviceTaskEntry:updateTaskProgress()
    local missionData = self.m_data:getCurMissionData() 

    local processMax = missionData:getProcessMax()
    local curProcess = missionData:getCurProcess()
    local percent = math.floor(curProcess / processMax * 100)
    local progUI = self:findChild("prg")
    progUI:setPercent(percent)

    local lbProg = self:findChild("lb_dec")
    if missionData:checkCompleted() then
        lbProg:setString("COMPLETED")
        lbProg:setScale(0.8)
    else
        lbProg:setString(string.format("%s%%", percent))
        lbProg:setScale(1)
    end 
end

function BlastNoviceTaskEntry:clickFunc()
    G_GetMgr(ACTIVITY_REF.BlastNoviceTask):showMainLayer()
end

return BlastNoviceTaskEntry