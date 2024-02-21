--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-27 14:20:15
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-29 17:55:43
FilePath: /SlotNirvana/src/activities/Activity_Blast/views/noviceTask/BlastNoviceTaskTitleUI.lua
Description: 新手blast 任务 标题UI
--]]
local BlastNoviceTaskTitleUI = class("BlastNoviceTaskTitleUI", BaseView)

function BlastNoviceTaskTitleUI:initDatas(_data)
    BlastNoviceTaskTitleUI.super.initDatas(self)

    self.m_data = _data
end

function BlastNoviceTaskTitleUI:getCsbName()
    return "Activity/BlastBlossomTask/csb/blastMission_title.csb"
end

function BlastNoviceTaskTitleUI:initUI()
    BlastNoviceTaskTitleUI.super.initUI(self)

    self:updateUI()
    self:runCsbAction("idle", true)
end

function BlastNoviceTaskTitleUI:updateUI()

    local curPhaseIdx = self.m_data:getCurPhaseIdx()

    for i=1, 3 do

        local titleSp = self:findChild("sp_title" .. i)
        if titleSp then 
            titleSp:setVisible(curPhaseIdx == i)
        end

    end
    
end

return BlastNoviceTaskTitleUI