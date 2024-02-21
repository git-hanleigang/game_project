--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local FBShareNet = class("FBShareNet", BaseNetModel)

function FBShareNet:requestCollectCoins(successFunc, failedFunc)
    gLobalViewManager:addLoadingAnimaDelay(1)
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        if _result and _result.error then
            failedFunc()
            return
        end
        successFunc()
    end
    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        failedFunc()
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.FacebookShareCollect, tbData, successCallback, failedCallback)
end

return FBShareNet
