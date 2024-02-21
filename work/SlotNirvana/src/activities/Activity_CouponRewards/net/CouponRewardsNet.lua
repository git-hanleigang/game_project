--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local CouponRewardsNet = class("CouponRewardsNet", BaseNetModel)

function CouponRewardsNet:collectReward(_index)
    local tbData = {
        data = {
            params = {
                index = _index
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COUPON_REWARD_COLLECT, true)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COUPON_REWARD_COLLECT, false)
    end

    self:sendActionMessage(ActionType.CouponRewardsCollect,tbData,successCallback,failedCallback)
end

return CouponRewardsNet