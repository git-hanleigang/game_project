--[[
    -- 商城停留送优惠券
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local StayCouponNet = class("StayCouponNet", BaseNetModel)

function StayCouponNet:getInstance()
    if self.instance == nil then
        self.instance = StayCouponNet.new()
    end
    return self.instance
end

function StayCouponNet:sendredeemTicket()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STAY_COUPON_REDEEM_TICKET, {success = true})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STAY_COUPON_REDEEM_TICKET)
    end

    self:sendActionMessage(ActionType.StoreStayCouponActivate,tbData,successCallback,failedCallback)
end

return StayCouponNet