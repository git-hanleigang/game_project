--[[
    NewCoinPusher任务
    author: 徐袁
    time: 2021-09-05 11:34:35
]]
local NewCoinPusherTaskMgr = class("NewCoinPusherTaskMgr", BaseActivityControl)

function NewCoinPusherTaskMgr:ctor()
    NewCoinPusherTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewCoinPusherTask)
    self:addPreRef(ACTIVITY_REF.NewCoinPusher)
end

function NewCoinPusherTaskMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local _layer = nil
    if gLobalViewManager:getViewByExtendData("NewCoinPusherTaskMainLayer") == nil then
        _layer = util_createFindView("Activity/NewCoinPusherTask/NewCoinPusherTaskMainLayer", _params)
        if _layer ~= nil then
            gLobalViewManager:showUI(_layer, ViewZorder.ZORDER_UI)
        end
    end
    return _layer
end

--打开奖励页
function NewCoinPusherTaskMgr:showRewardLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local taskView = util_createView("Activity.NewCoinPusherTask.NewCoinPusherTaskRewardLayer")
    gLobalViewManager:showUI(taskView, ViewZorder.ZORDER_UI)

    return taskView
end

return NewCoinPusherTaskMgr
