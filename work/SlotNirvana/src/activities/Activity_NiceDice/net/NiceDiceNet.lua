--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local NiceDiceNet = class("NiceDiceNet", BaseNetModel)

function NiceDiceNet:sendCollectReward()
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
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_NICE_DICE_COLLECT, false)
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_NICE_DICE_COLLECT, true)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_NICE_DICE_COLLECT, false)
    end

    self:sendActionMessage(ActionType.NiceDiceCollect,tbData,successCallback,failedCallback)
end

return NiceDiceNet