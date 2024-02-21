-- 新版大富翁 任务管理器

local WorldTripTaskMgr = class("WorldTripTaskMgr", BaseActivityControl)

WorldTripTaskMgr.richmanData = nil

function WorldTripTaskMgr:ctor()
    WorldTripTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.WorldTripTask)
    self:addPreRef(ACTIVITY_REF.WorldTrip)
end

function WorldTripTaskMgr:showMainLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end

    local mainLayer = nil
    if gLobalViewManager:getViewByExtendData("WorldTripTaskMainLayer") == nil then
        mainLayer = util_createFindView("Activity/WorldTripTaskMainLayer")
        if mainLayer ~= nil then
            gLobalViewManager:showUI(mainLayer, ViewZorder.ZORDER_UI)
        end
    end
    return mainLayer
end

--打开奖励页
function WorldTripTaskMgr:showRewardLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local taskView = util_createView("Activity.WorldTripTaskRewardLayer")
    gLobalViewManager:showUI(taskView, ViewZorder.ZORDER_UI)
    return taskView
end

return WorldTripTaskMgr
