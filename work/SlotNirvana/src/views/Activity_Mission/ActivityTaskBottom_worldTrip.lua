--[[
    大富翁任务入口按钮
]]
local ActivityTaskBottom_worldTrip = class("ActivityTaskBottom_worldTrip", util_require("views.Activity_Mission.ActivityTaskBottomBase"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager")

function ActivityTaskBottom_worldTrip:initUI()
    ActivityTaskBottom_worldTrip.super.initUI(self)
end

function ActivityTaskBottom_worldTrip:getCsbName()
    return "Activity_Mission/csd/COIN_WORLDTRIP_MissionEntryNode.csb"
end

function ActivityTaskBottom_worldTrip:getActivityName()
    return ACTIVITY_REF.WorldTripTask
end

function ActivityTaskBottom_worldTrip:getHasProgress()
    return true
end

function ActivityTaskBottom_worldTrip:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_mission" then
        G_GetMgr(ACTIVITY_REF.WorldTripTask):showMainLayer()
    end
end

return ActivityTaskBottom_worldTrip
