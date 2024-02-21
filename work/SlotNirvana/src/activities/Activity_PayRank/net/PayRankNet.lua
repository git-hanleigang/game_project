--[[
    -- 活动网络通信模块
]]

local PayRankConfig = require("activities.Activity_PayRank.config.PayRankConfig")
local BaseNetModel = require("net.netModel.BaseNetModel")
local PayRankNet = class("PayRankNet", BaseNetModel)

function PayRankNet:sendRefreshData()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()        
        gLobalNoticManager:postNotification(PayRankConfig.notify_refresh_data)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(PayRankConfig.notify_refresh_data)
    end

    self:sendActionMessage(ActionType.PayRankRefresh,tbData,successCallback,failedCallback)
end

return PayRankNet