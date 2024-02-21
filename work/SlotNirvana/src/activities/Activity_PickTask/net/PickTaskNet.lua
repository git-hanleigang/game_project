--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local PickTaskNet = class("PickTaskNet", BaseNetModel)

function PickTaskNet:sendCollectReward()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if _result and _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PICK_TASK_COLLECT, false)
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PICK_TASK_COLLECT, true)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PICK_TASK_COLLECT, false)
    end

    self:sendActionMessage(ActionType.OptionalTaskCollect,tbData,successCallback,failedCallback)
end

function PickTaskNet:sendGetConfig()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if _result and _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PICK_TASK_GET_CONFIG, false)
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PICK_TASK_GET_CONFIG, true)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PICK_TASK_GET_CONFIG, false)
    end

    self:sendActionMessage(ActionType.OptionalTaskGetConfig,tbData,successCallback,failedCallback)
end

return PickTaskNet