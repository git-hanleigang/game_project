--新版
local CoinPusherTaskNewMgr = class("CoinPusherTaskNewMgr", BaseActivityControl)

function CoinPusherTaskNewMgr:ctor()
    CoinPusherTaskNewMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinPusherTaskNew)
    self:addPreRef(ACTIVITY_REF.CoinPusher)
end

function CoinPusherTaskNewMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COIN_PUSHER_END)
    local taskView = util_createView("Activity.CoinPusherTask.CoinPusherTaskMainLayerNew", _params)
    gLobalViewManager:showUI(taskView, ViewZorder.ZORDER_UI)
    return taskView
end

--打开奖励页
function CoinPusherTaskNewMgr:showRewardLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local taskView = util_createView("Activity.CoinPusherTask.CoinPusherTaskRewardLayer")
    gLobalViewManager:showUI(taskView, ViewZorder.ZORDER_UI)

    return taskView
end

return CoinPusherTaskNewMgr
