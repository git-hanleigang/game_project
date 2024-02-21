--[[
    接水管任务入口按钮
]]

local ActivityTaskBottom_pipe = class("ActivityTaskBottom_pipe", util_require("views.Activity_Mission.ActivityTaskBottomBase"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager")

function ActivityTaskBottom_pipe:initUI()
    ActivityTaskBottom_pipe.super.initUI(self)
end

function ActivityTaskBottom_pipe:getCsbName()
    return "Activity_Mission/csd/COIN_PIPECONNECT_MissionEntryNode.csb"
end

function ActivityTaskBottom_pipe:getActivityName()
    return ACTIVITY_REF.PipeConnectTask
end

function ActivityTaskBottom_pipe:getHasProgress()
    return true    
end

function ActivityTaskBottom_pipe:clickFunc()
    if self.m_isCanTouch then 
        return 
    end
    self.m_isCanTouch = true
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIPECONNECT_PLAYAUTO)
    G_GetMgr(ACTIVITY_REF.PipeConnectTask):showMainLayer()
    self.m_isCanTouch = false
end

function ActivityTaskBottom_pipe:setTouchFlag(_flag)
    self.m_isCanTouch = _flag
end

--更新任务进度显示
function ActivityTaskBottom_pipe:updateTaskProgress()
    ActivityTaskBottom_pipe.super.updateTaskProgress(self)
    local taskDataObj = ActivityTaskManager:getInstance():getCurrentTaskByActivityName(self:getActivityName())
    if taskDataObj then
        if taskDataObj:getCompleted() then
            self.m_lbProgressNum:setScale(0.8)
        else
            self.m_lbProgressNum:setScale(1)
        end
    end
end
function ActivityTaskBottom_pipe:registerListener()
    ActivityTaskBottom_pipe.super.registerListener(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_isCanTouch = true
        end,
        ViewEventType.NOTIFY_PIPECONNECT_ZHUANSTART
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not params then
                self.m_isCanTouch = false
            end
        end,
        ViewEventType.NOTIFY_PIPECONNECT_SLOTRESULT
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if tolua.isnull(self) then
                return
            end
            self.m_isCanTouch = false
        end,
        ViewEventType.NOTIFY_PIPECONNECT_FLYOVER
    )
end

return ActivityTaskBottom_pipe
