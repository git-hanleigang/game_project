--[[
    word任务入口按钮
]]
local ActivityTaskBottom_word = class("ActivityTaskBottom_word", util_require("views.Activity_Mission.ActivityTaskBottomBase"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager")

function ActivityTaskBottom_word:initUI()
    ActivityTaskBottom_word.super.initUI(self)
end

function ActivityTaskBottom_word:getCsbName()
    return "Activity_Mission/csd/COIN_WORD_MissionEntryNode.csb"
end

function ActivityTaskBottom_word:getActivityName()
    return ACTIVITY_REF.WordTask
end

function ActivityTaskBottom_word:getHasProgress()
    return true
end

function ActivityTaskBottom_word:clickFunc()
    if self.m_isCanTouch then
        return
    end
    self.m_isCanTouch = true
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- ActivityTaskManager:getInstance():openWordTaskView()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WORD_QUIT_AUTO)
    G_GetMgr(ACTIVITY_REF.WordTask):showMainLayer()
    -- local taskDataObj = ActivityTaskManager:getInstance():getCurrentTaskByActivityName(self:getActivityName())
    -- if taskDataObj and taskDataObj:isRunning() then
    -- end
    self.m_isCanTouch = false
end

return ActivityTaskBottom_word
