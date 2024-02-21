--[[
    bingo任务入口按钮
]]

local ActivityTaskBottom_bingo = class("ActivityTaskBottom_bingo",util_require("views.Activity_Mission.ActivityTaskBottomBase"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager")

function ActivityTaskBottom_bingo:initUI()
    ActivityTaskBottom_bingo.super.initUI(self)
end

function ActivityTaskBottom_bingo:getCsbName()
    return "Activity_Mission/csd/COIN_BINGO_MissionEntryNode.csb"
end

function ActivityTaskBottom_bingo:getActivityName()
    return ACTIVITY_REF.BingoTask
end

function ActivityTaskBottom_bingo:getHasProgress()
    return true    
end

function ActivityTaskBottom_bingo:updateTaskProgress()
    ActivityTaskBottom_bingo.super.updateTaskProgress(self)
    self.m_lbProgressNum:setScale(1)
end

function ActivityTaskBottom_bingo:clickFunc()
    if self.m_isCanTouch then 
        return 
    end
    self.m_isCanTouch = true
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BINGO_JACKPOT_HIDE)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_PAUSE_AUTO_PLAY)
    ActivityTaskManager:getInstance():openBingoTaskView()

    self.m_isCanTouch = false
end

function ActivityTaskBottom_bingo:setTouchFlag(_flag)
    self.m_isCanTouch = _flag
end

return ActivityTaskBottom_bingo
