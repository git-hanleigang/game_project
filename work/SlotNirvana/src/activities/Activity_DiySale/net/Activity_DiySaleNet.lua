--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local Activity_DiySaleNet = class("Activity_DiySaleNet", BaseNetModel)

-- 抽取buf
function Activity_DiySaleNet:requestCancleBack(successCallFunc, failedCallFunc)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function(_result)
        dump(_result)
        gLobalViewManager:removeLoadingAnima()
        if successCallFunc then
            successCallFunc(_result)
        end
    end
    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.DiyFeatureBuffSaleClear, tbData, successCallback, failedCallback)
end

return Activity_DiySaleNet