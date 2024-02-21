--礼物兑换
local BaseNetModel = require("net.netModel.BaseNetModel")
local GiftCodesNet = class("GiftCodesNet", BaseNetModel)

--领奖
function GiftCodesNet:requestExchange(successFunc, fileFunc, _code)
    gLobalViewManager:addLoadingAnima()
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if successFunc then
            successFunc(resJson)
        end
    end
    local tbData = {
        data = {
            params = {
                code = _code
            }
        }
    }
    self:sendActionMessage(ActionType.ExchangeCodeCollectReward, tbData, successFunc, failedFunc)
end

return GiftCodesNet
