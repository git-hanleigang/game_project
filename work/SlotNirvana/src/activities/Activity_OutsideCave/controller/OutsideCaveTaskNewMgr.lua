-- 任务
local OutsideCaveTaskNewMgr = class("OutsideCaveTaskNewMgr", BaseActivityControl)

function OutsideCaveTaskNewMgr:ctor()
    OutsideCaveTaskNewMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.OutsideCaveTaskNew)
    self:addPreRef(ACTIVITY_REF.OutsideCave)
end

function OutsideCaveTaskNewMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COIN_PUSHER_END)
    local taskView = util_createView("Activity.OutsideCaveTaskNew.OutsideCaveTaskMainLayer", _params)
    self:showLayer(taskView, ViewZorder.ZORDER_UI)
    return taskView
end

--打开奖励页
function OutsideCaveTaskNewMgr:showRewardLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local taskView = util_createView("Activity.OutsideCaveTaskNew.OutsideCaveTaskRewardLayer")
    self:showLayer(taskView, ViewZorder.ZORDER_UI)

    return taskView
end


return OutsideCaveTaskNewMgr
