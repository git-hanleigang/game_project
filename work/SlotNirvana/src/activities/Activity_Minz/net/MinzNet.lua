--[[
    Minz网络层
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local MinzNet = class("MinzNet", BaseNetModel)

-- 请求购买宝箱
function MinzNet:requestBuyBox(param, successCallFunc, failedCallFunc)
    local tbData = {
        data = {
            params = param or {}
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(resData)
        gLobalViewManager:removeLoadingAnima()
        if successCallFunc then
            successCallFunc(resData)
        end
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc(errorCode, errorData)
        end
    end

    self:sendActionMessage(ActionType.MinzBuyBag, tbData, successCallback, failedCallback)
end

return MinzNet
