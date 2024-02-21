--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local DiyFeatureNet = class("DiyFeatureNet", BaseNetModel)

-- 抽取buf
function DiyFeatureNet:requestSpinReward(successCallFunc, failedCallFunc)
    gLobalViewManager:addLoadingAnima(false)
    local successCallback = function(_result)
        if successCallFunc then
            successCallFunc(_result)
        end
        gLobalViewManager:removeLoadingAnima()
    end
    local failedCallback = function(errorCode, errorData)
        if failedCallFunc then
            failedCallFunc(errorCode, errorData)
        end
        gLobalViewManager:removeLoadingAnima()
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.DiyFeaturePlay, tbData, successCallback, failedCallback)
end

return DiyFeatureNet