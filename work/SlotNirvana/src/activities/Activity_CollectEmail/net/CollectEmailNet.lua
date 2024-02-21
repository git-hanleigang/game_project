--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local CollectEmailNet = class("CollectEmailNet", BaseNetModel)

function CollectEmailNet:saveEmail(_email, _openPos)
    local tbData = {
        data = {
            params = {
                mail = _email,
                openPos = _openPos
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_EMAIL_COLLECT, false)
            return
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_EMAIL_COLLECT, true)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_EMAIL_COLLECT, false)
    end

    self:sendActionMessage(ActionType.MailRewardData,tbData,successCallback,failedCallback)
end

return CollectEmailNet