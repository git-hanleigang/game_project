--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local SevenDaySignNet = class("SevenDaySignNet", BaseNetModel)

function SevenDaySignNet:sendCollectReward()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_2YEARS_COLLECT, false)
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_2YEARS_COLLECT, _result)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_2YEARS_COLLECT, false)
    end

    self:sendActionMessage(ActionType.TwoYearsSignCollect,tbData,successCallback,failedCallback)
end

return SevenDaySignNet