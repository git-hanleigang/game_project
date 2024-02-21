--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local PiggyGoodiesNet = class("PiggyGoodiesNet", BaseNetModel)

function PiggyGoodiesNet:sendCollect(_pickIndex)
    local tbData = {
        data = {
            params = {
                index = _pickIndex
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIGGY_COODIES_COLLECT, {success = true})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIGGY_COODIES_COLLECT)
    end

    self:sendActionMessage(ActionType.PiggyGoodiesReward,tbData,successCallback,failedCallback)
end

return PiggyGoodiesNet