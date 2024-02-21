local BaseNetModel = require("net.netModel.BaseNetModel")
local Promotion_OnePlusOneNet = class("Promotion_OnePlusOneNet", BaseNetModel)

function Promotion_OnePlusOneNet:getInstance()
    if self.instance == nil then
        self.instance = Promotion_OnePlusOneNet.new()
    end
    return self.instance
end

-- 发射
function Promotion_OnePlusOneNet:sendGetRewards(reward)
    local tbData = {
        data = {
            params = {
                
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ONEPLUSONE_GETREWARDS, {
                res = false,
            })
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ONEPLUSONE_GETREWARDS, {
            res = true,
            reward = reward,
        })
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ONEPLUSONE_GETREWARDS, {
            res = false,
        })
    end

    self:sendActionMessage(ActionType.OnePlusOneSaleCollectFreeReward,tbData,successCallback,failedCallback)
end

return Promotion_OnePlusOneNet