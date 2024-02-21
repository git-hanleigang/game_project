--[[
    装修活动 任务入口按钮
]]
local RedecorProcessControl = util_require("Activity.RedecorCode.RedecorProcessControl")
local ActivityTaskBottom_redecor = class("ActivityTaskBottom_redecor", util_require("views.Activity_Mission.ActivityTaskBottomBase"))
function ActivityTaskBottom_redecor:ctor()
    local themeLogic = G_GetMgr(ACTIVITY_REF.Redecor):getThemeLogic()
    self.m_themeCsbCfg = themeLogic:getCsbCfg()
    ActivityTaskBottom_redecor.super.ctor(self)
end

function ActivityTaskBottom_redecor:initUI()
    ActivityTaskBottom_redecor.super.initUI(self)
end

function ActivityTaskBottom_redecor:getCsbName()
    return self.m_themeCsbCfg.mainTaskNode
end

function ActivityTaskBottom_redecor:getActivityName()
    return ACTIVITY_REF.RedecorTask
end

function ActivityTaskBottom_redecor:getHasProgress()
    return true
end

function ActivityTaskBottom_redecor:clickFunc()
    if RedecorProcessControl and RedecorProcessControl:getInstance():getClickDisabled() then
        return
    end
    if self.m_isCanTouch then
        return
    end
    self.m_isCanTouch = true
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- ActivityTaskManager:getInstance():openRedecorTaskView()
    G_GetMgr(ACTIVITY_REF.RedecorTask):showMainLayer()
    self.m_isCanTouch = false
end

return ActivityTaskBottom_redecor
