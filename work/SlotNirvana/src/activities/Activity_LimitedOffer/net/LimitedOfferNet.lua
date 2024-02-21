--[[
    限时促销
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local LimitedOfferNet = class("LimitedOfferNet", BaseNetModel)

function LimitedOfferNet:getInstance()
    if self.instance == nil then
        self.instance = LimitedOfferNet.new()
    end
    return self.instance
end

function LimitedOfferNet:sendFreeGift(_index, _bNovice)
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
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_LIMITEDOFFER_BUY_SALE, {index = _index})
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_LIMITEDOFFER_BUY_SALE, {index = _index, success = true})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_LIMITEDOFFER_BUY_SALE, {index = _index})
    end

    local actionType = ActionType.LimitedGiftCollect
    if _bNovice then
        actionType = ActionType.NewUserLimitedGiftCollect
    end
    self:sendActionMessage(actionType,tbData,successCallback,failedCallback)
end

return LimitedOfferNet
