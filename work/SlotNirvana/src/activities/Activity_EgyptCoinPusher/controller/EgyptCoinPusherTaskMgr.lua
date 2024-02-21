--[[
    EgyptCoinPusher任务
    author: 徐袁
    time: 2021-09-05 11:34:35
]]
local EgyptCoinPusherTaskMgr = class("EgyptCoinPusherTaskMgr", BaseActivityControl)

function EgyptCoinPusherTaskMgr:ctor()
    EgyptCoinPusherTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.EgyptCoinPusherTask)
    self:addPreRef(ACTIVITY_REF.EgyptCoinPusher)
end

function EgyptCoinPusherTaskMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function EgyptCoinPusherTaskMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function EgyptCoinPusherTaskMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "Loading/" .. popName
end

function EgyptCoinPusherTaskMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("EgyptCoinPusherTaskMainLayer") then
        return nil
    end

    local view = util_createView("Activity/EgyptCoinPusherTask/EgyptCoinPusherTaskMainLayer", _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--打开奖励页
function EgyptCoinPusherTaskMgr:showRewardLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("EgyptCoinPusherTaskRewardLayer") then
        return nil
    end

    local view = util_createView("Activity.EgyptCoinPusherTask.EgyptCoinPusherTaskRewardLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

return EgyptCoinPusherTaskMgr
