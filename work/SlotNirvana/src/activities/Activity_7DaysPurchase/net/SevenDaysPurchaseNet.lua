-- 新手期个人累充 网络消息处理

local BaseActivityManager = util_require("baseActivity.BaseActivityManager")
local SevenDaysPurchaseNet = class("SevenDaysPurchaseNet", BaseActivityManager)

function SevenDaysPurchaseNet:getInstance()
    if self.instance == nil then
        self.instance = SevenDaysPurchaseNet.new()
    end
    return self.instance
end

-- 发送获取字母消息
function SevenDaysPurchaseNet:requestCollect(price)
    if not price or price < 0 then
        return
    end
    gLobalViewManager:addLoadingAnima()

    local successCallBack = function(resData)
        gLobalViewManager:removeLoadingAnima()
        local buyResult = cjson.decode(resData.result)
        if buyResult then
            G_GetMgr(ACTIVITY_REF.SevenDaysPurchase):recordRewardsList(buyResult)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_SEVEN_DAYS_PURCHASE_COLLECT, {isSucc = true})
    end
    local failedCallBack = function(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_SEVEN_DAYS_PURCHASE_COLLECT, {isSucc = false})
    end
    self:sendMsgBaseFunc(ActionType.NewUserChargeCollect, "SevenDaysPurchase", {price = price}, successCallBack, failedCallBack)
end

return SevenDaysPurchaseNet
