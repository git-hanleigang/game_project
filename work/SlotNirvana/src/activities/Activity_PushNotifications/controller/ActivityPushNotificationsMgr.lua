--[[
    本地推送开启设置活动
]]

local ActivityPushNotificationsMgr = class("ActivityPushNotificationsMgr", BaseActivityControl)

function ActivityPushNotificationsMgr:ctor()
    ActivityPushNotificationsMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ActivityPushNotifications)
end
function ActivityPushNotificationsMgr:showMainLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end
    local uiView = util_createFindView("Activity/Activity_PushNotifications", data)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_POPUI)
    return uiView
end

return ActivityPushNotificationsMgr