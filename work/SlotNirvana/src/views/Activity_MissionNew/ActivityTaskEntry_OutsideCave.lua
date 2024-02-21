
local ActivityTaskEntry_OutsideCave = class("ActivityTaskEntry_OutsideCave", util_require("views.Activity_MissionNew.ActivityTaskEntryBase"))

function ActivityTaskEntry_OutsideCave:initUI()
    ActivityTaskEntry_OutsideCave.super.initUI(self)
end

function ActivityTaskEntry_OutsideCave:getCsbName()
    return "Activity/Activity_MissionNew/csd/COIN_OUTSIDECAVE_MissionEntryNode.csb"
end

function ActivityTaskEntry_OutsideCave:getActivityName()
    return ACTIVITY_REF.OutsideCaveTaskNew
end

function ActivityTaskEntry_OutsideCave:openTaskView()
    if G_GetMgr(ACTIVITY_REF.OutsideCave):isInSpin() then
        return
    end    
    G_GetMgr(ACTIVITY_REF.OutsideCaveTaskNew):showMainLayer()
end

return ActivityTaskEntry_OutsideCave
