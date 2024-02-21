--[[
    大富翁旧版任务入口按钮
]]

local ActivityTaskBottom_OutsideCave = class("ActivityTaskBottom_OutsideCave", util_require("views.Activity_Mission.ActivityTaskBottomBase"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager")

-- function ActivityTaskBottom_OutsideCave:initUI()
--     ActivityTaskBottom_OutsideCave.super.initUI(self)
-- end

function ActivityTaskBottom_OutsideCave:getCsbName()
    return "Activity_Mission/csd/COIN_OUTSIDECAVE_MissionEntryNode.csb"
end

function ActivityTaskBottom_OutsideCave:getActivityName()
    return ACTIVITY_REF.OutsideCaveTask
end

function ActivityTaskBottom_OutsideCave:getHasProgress()
    return true    
end

function ActivityTaskBottom_OutsideCave:clickFunc()
    if G_GetMgr(ACTIVITY_REF.OutsideCave):isInSpin() then
        return
    end
    if self.m_isCanTouch then 
        return 
    end
    self.m_isCanTouch = true
    --取消自动spin
    --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OutsideCave_PLAYAUTO)
    G_GetMgr(ACTIVITY_REF.OutsideCaveTask):showMainLayer()
    self.m_isCanTouch = false
end

function ActivityTaskBottom_OutsideCave:setTouchFlag(_flag)
    self.m_isCanTouch = _flag
end

--更新任务进度显示
function ActivityTaskBottom_OutsideCave:updateTaskProgress()
    ActivityTaskBottom_OutsideCave.super.updateTaskProgress(self)
    local taskDataObj = ActivityTaskManager:getInstance():getCurrentTaskByActivityName(self:getActivityName())
    if taskDataObj then
        if taskDataObj:getCompleted() then
            self.m_lbProgressNum:setScale(0.8)
        else
            self.m_lbProgressNum:setScale(1)
        end
    end
end
function ActivityTaskBottom_OutsideCave:registerListener()
    ActivityTaskBottom_OutsideCave.super.registerListener(self)
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         self.m_isCanTouch = true
    --     end,
    --     ViewEventType.NOTIFY_OutsideCave_ZHUANSTART
    -- )

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         if not params then
    --             self.m_isCanTouch = false
    --         end
    --     end,
    --     ViewEventType.NOTIFY_OutsideCave_SLOTRESULT
    -- )
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         if tolua.isnull(self) then
    --             return
    --         end
    --         self.m_isCanTouch = false
    --     end,
    --     ViewEventType.NOTIFY_OutsideCave_FLYOVER
    -- )
end

return ActivityTaskBottom_OutsideCave
