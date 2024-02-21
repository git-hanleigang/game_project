--[[
    限时膨胀
]]
local TimeLimitExpansionMgr = class("TimeLimitExpansionMgr", BaseActivityControl)

function TimeLimitExpansionMgr:ctor()
    TimeLimitExpansionMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TimeLimitExpansion)
    self:setDataModule("activities.Activity_TimeLimitExpansion.model.TimeLimitExpansionData")
end

function TimeLimitExpansionMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function TimeLimitExpansionMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function TimeLimitExpansionMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

function TimeLimitExpansionMgr:parseData(_data)
    TimeLimitExpansionMgr.super.parseData(self, _data)
end

-- 活动膨胀系数
function TimeLimitExpansionMgr:getExpansionRatio()
    if not self:isCanShowLayer() then
        return 0
    end
    local data = self:getRunningData()
    return data:getTotalExpansion() / 100 or 0
end

-- 检测是否完成付费任务
function TimeLimitExpansionMgr:checkIsCompletePayTask()
    local data = self:getRunningData()
    if data then
        local isComplete = data:getLastAndFinishTask("pay")
        return isComplete
    end
    return false
end

-- 检测是否完成活跃任务
function TimeLimitExpansionMgr:checkIsCompleteActiveTask()
    local data = self:getRunningData()
    if data then
        local isComplete = data:getLastAndFinishTask("active")
        return isComplete
    end
    return false
end

function TimeLimitExpansionMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByExtendData("Activity_TimeLimitExpansion") ~= nil then
        return
    end
    local uiView = util_createView("Activity_TimeLimitExpansion.Activity_TimeLimitExpansion", _params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function TimeLimitExpansionMgr:showLogoLayer()
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByExtendData("TimeLimitExpansionLogoLayer") ~= nil then
        return
    end
    local view = util_createView("Activity_TimeLimitExpansion.TimeLimitExpansionLogoLayer")
    if view then
        view:setName("TimeLimitExpansionLogoLayer")
        self:showLayer(view, ViewZorder.ZORDER_POPUI)
    end
    return view
end

function TimeLimitExpansionMgr:getLogoLayer()
    return gLobalViewManager:getViewByName("TimeLimitExpansionLogoLayer")
end

function TimeLimitExpansionMgr:playStartAction(_over)
    local layer = self:getLogoLayer()
    if layer then
        layer:playStartAction(_over)
    end
end

function TimeLimitExpansionMgr:getTimeLimitExpansionIcon()
    if not self:isCanShowLayer() then
        return
    end
    return util_createView("Activity_TimeLimitExpansion.TimeLimitExpansionIcon")
end

return TimeLimitExpansionMgr
