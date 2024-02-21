local BaseNetModel = require("net.netModel.BaseNetModel")
local PromotionTornadoMagicStoreDataNet = class("PromotionTornadoMagicStoreDataNet", BaseNetModel)

function PromotionTornadoMagicStoreDataNet:getInstance()
    if self.instance == nil then
        self.instance = PromotionTornadoMagicStoreDataNet.new()
    end
    return self.instance
end

-- 发射
function PromotionTornadoMagicStoreDataNet:sendGetRewards(index)
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
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TORNADOMAGICSTORE_GETREWARDS, {
                res = false,
                index = index
            })
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TORNADOMAGICSTORE_GETREWARDS, {
            res = true,
            index = index
        })
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TORNADOMAGICSTORE_GETREWARDS, {
            res = false,
            index = index
        })
    end

    self:sendActionMessage(ActionType.TwoChooseOneGiftCollectReward,tbData,successCallback,failedCallback)
end

return PromotionTornadoMagicStoreDataNet