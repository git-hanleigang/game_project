--[[
    CoinPusher任务
    author: 徐袁
    time: 2021-09-05 11:34:35
]]
local CoinPusherTaskMgr = class("CoinPusherTaskMgr", BaseActivityControl)

function CoinPusherTaskMgr:ctor()
    CoinPusherTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinPusherTask)
    self:addPreRef(ACTIVITY_REF.CoinPusher)

    self:addExtendResList("Activity_CoinPusherTaskCode")
end

function CoinPusherTaskMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local _layer = nil
    if gLobalViewManager:getViewByExtendData("CoinPusherTaskMainLayer") == nil then
        _layer = util_createFindView("Activity/CoinPusherTask/CoinPusherTaskMainLayer", _params)
        if _layer ~= nil then
            gLobalViewManager:showUI(_layer, ViewZorder.ZORDER_UI)
        end
    end
    return _layer
end

--打开奖励页
function CoinPusherTaskMgr:showRewardLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local taskView = util_createView("Activity.CoinPusherTask.CoinPusherTaskRewardLayer")
    gLobalViewManager:showUI(taskView, ViewZorder.ZORDER_UI)

    return taskView
end

return CoinPusherTaskMgr
