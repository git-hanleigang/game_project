--[[
    旧版任务
]]
local OutsideCaveTaskMgr = class("OutsideCaveTaskMgr", BaseActivityControl)

function OutsideCaveTaskMgr:ctor()
    OutsideCaveTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.OutsideCaveTask)
    self:addPreRef(ACTIVITY_REF.OutsideCave)
    self:addExtendResList("Activity_OutsideCaveTaskCode")
end

function OutsideCaveTaskMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    local _layer = nil
    if gLobalViewManager:getViewByExtendData("OutsideCaveTaskMainLayer") == nil then
        _layer = util_createFindView("OutsideCaveTask/Activity/OutsideCaveTaskMainLayer", _params)
        if _layer ~= nil then
            self:showLayer(_layer, ViewZorder.ZORDER_UI)
        end
    end
    return _layer
end

--打开奖励页
function OutsideCaveTaskMgr:showRewardLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    local taskView = util_createView("OutsideCaveTask.Activity.OutsideCaveTaskRewardLayer")
    gLobalViewManager:showUI(taskView, ViewZorder.ZORDER_UI)

    return taskView
end

function OutsideCaveTaskMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "_loading".."/Icons/" .. themeName .. "HallNode"
end

function OutsideCaveTaskMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "_loading".."/Icons/" .. themeName .. "SlideNode"
end

function OutsideCaveTaskMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "_loading".. "/Activity/" .. themeName 
end


return OutsideCaveTaskMgr
