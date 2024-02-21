--[[
    blast任务入口按钮
]]
local ActivityTaskBottom_blast = class("ActivityTaskBottom_blast", util_require("views.Activity_Mission.ActivityTaskBottomBase"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager")

function ActivityTaskBottom_blast:initUI()
    self.BlastConfig = G_GetMgr(ACTIVITY_REF.Blast):getConfig()
    ActivityTaskBottom_blast.super.initUI(self)
end

function ActivityTaskBottom_blast:getCsbName()
    if self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.OCEAN then
        -- 海洋主题
        return "Activity_Mission/csd/COIN_BLAST_MissionEntryNode.csb"
    elseif self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.HALLOWEEN then
        -- 万圣节主题
        return "Activity_Mission/csd/COIN_BLAST_MissionHalloweenEntryNode.csb"
    elseif self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.THANKSGIVING then
        -- 感恩节主题
        return "Activity_Mission/csd/COIN_BLAST_MissionThanksgivingEntryNode.csb"
    elseif self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.CHRISTMAS then
        -- 圣诞节主题
        return "Activity_Mission/csd/COIN_BLAST_MissionChristmasEntryNode.csb"
    elseif self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.EASTER then
        -- 复活节主题
        return "Activity_Mission/csd/COIN_BLAST_MissionEasterEntryNode.csb"
    elseif self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.THREE3RD then
        -- 复活节主题
        return "Activity_Mission/csd/COIN_BLAST_Mission3RDEntryNode.csb"
    elseif self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.BLOSSOM then
        -- 阿凡达主题
        return "Activity_Mission/csd/COIN_BLAST_MissionBlossomEntryNode.csb"
    elseif self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.MERMAID then
        return "Activity_Mission/csd/COIN_BLAST_MissionMermaidEntryNode.csb"
    end
end

function ActivityTaskBottom_blast:getActivityName()
    return ACTIVITY_REF.BlastTask
end

function ActivityTaskBottom_blast:getHasProgress()
    return true
end

function ActivityTaskBottom_blast:clickFunc()
    if self.m_isCanTouch then
        return
    end
    self.m_isCanTouch = true
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- ActivityTaskManager:getInstance():openBlastTaskView()
    local msg = G_GetMgr(ACTIVITY_REF.BlastTask):showMainLayer()
    -- local taskDataObj = ActivityTaskManager:getInstance():getCurrentTaskByActivityName(self:getActivityName())
    -- if taskDataObj and taskDataObj:isRunning() then
    -- end

    self.m_isCanTouch = false
end

function ActivityTaskBottom_blast:updateTaskProgress()
    ActivityTaskBottom_blast.super.updateTaskProgress(self)
    if self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.HALLOWEEN then
        return
    end
    local activityName = self:getActivityName()
    if activityName then
        local taskDataObj = ActivityTaskManager:getInstance():getCurrentTaskByActivityName(activityName)
        if taskDataObj then
            if taskDataObj:getCompleted() then
                if self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.BLOSSOM then
                    self.m_lbProgressNum:setScale(1)
                elseif self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.MERMAID then
                    self.m_lbProgressNum:setScale(0.85)
                end
            end
        end
    end
end
return ActivityTaskBottom_blast
