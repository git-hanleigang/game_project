--[[
    新版餐厅任务入口按钮
]]

local ActivityTaskBottom_diningRoom = class("ActivityTaskBottom_diningRoom",util_require("views.Activity_Mission.ActivityTaskBottomBase"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager")

function ActivityTaskBottom_diningRoom:initUI()
    ActivityTaskBottom_diningRoom.super.initUI(self)
end

function ActivityTaskBottom_diningRoom:getCsbName()
    return "Activity_Mission/csd/COIN_DININGROOM_MissionEntryNode.csb"
end

function ActivityTaskBottom_diningRoom:getActivityName()
    return ACTIVITY_REF.DiningRoomTask
end

function ActivityTaskBottom_diningRoom:getHasProgress()
    return true    
end

function ActivityTaskBottom_diningRoom:clickFunc()
    if self.m_isCanTouch then 
        return 
    end
    self.m_isCanTouch = true
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    ActivityTaskManager:getInstance():openDiningRoomTaskView()
    self.m_isCanTouch = false
end


return ActivityTaskBottom_diningRoom