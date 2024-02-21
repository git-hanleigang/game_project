--[[
    打开推送通知送奖
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local NotificationNet = class("NotificationNet", BaseNetModel)

function NotificationNet:sendCollect()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFICATION_COLLECT_REWARD, {success = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFICATION_COLLECT_REWARD, {success = false})
    end

    self:sendActionMessage(ActionType.MessagePushCollectReward,tbData,successCallback,failedCallback)
end

return NotificationNet
