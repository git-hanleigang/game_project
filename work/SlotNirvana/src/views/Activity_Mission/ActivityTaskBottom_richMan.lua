--[[
    大富翁任务入口按钮
]]
local ActivityTaskBottom_richMan = class("ActivityTaskBottom_richMan", util_require("views.Activity_Mission.ActivityTaskBottomBase"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager")

function ActivityTaskBottom_richMan:initUI()
    ActivityTaskBottom_richMan.super.initUI(self)
end

function ActivityTaskBottom_richMan:getCsbName()
    return "Activity_Mission/csd/COIN_TREASURERACE_MissionEntryNode.csb"
end

function ActivityTaskBottom_richMan:getActivityName()
    return ACTIVITY_REF.RichManTask
end

function ActivityTaskBottom_richMan:getHasProgress()
    return true
end

function ActivityTaskBottom_richMan:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_mission" then
    -- if self.m_isCanTouch then
    --     return
    -- end
    -- self.m_isCanTouch = true
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- ActivityTaskManager:getInstance():openRichManTaskView()
    G_GetMgr(ACTIVITY_REF.RichManTask):showMainLayer()
    -- local taskDataObj = ActivityTaskManager:getInstance():getCurrentTaskByActivityName(self:getActivityName())
    -- if taskDataObj and taskDataObj:isRunning() then
    -- end
    -- self.m_isCanTouch = false
    end
end

return ActivityTaskBottom_richMan
