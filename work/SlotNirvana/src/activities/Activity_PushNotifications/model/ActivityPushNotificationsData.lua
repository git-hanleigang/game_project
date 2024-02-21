--[[
    提醒玩家打开推送开关 活动数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ActivityPushNotificationsData = class("ActivityPushNotificationsData", BaseActivityData)

function ActivityPushNotificationsData:ctor()
    ActivityPushNotificationsData.super.ctor(self)
    self.p_open = true
end

return ActivityPushNotificationsData
