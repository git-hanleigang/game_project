--[[
    限时膨胀
]]
local TimeLimitExpansionLoadingMgr = class("TimeLimitExpansionLoadingMgr", BaseActivityControl)

function TimeLimitExpansionLoadingMgr:ctor()
    TimeLimitExpansionLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TimeLimitExpansionLoading)
end

function TimeLimitExpansionLoadingMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function TimeLimitExpansionLoadingMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function TimeLimitExpansionLoadingMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

function TimeLimitExpansionLoadingMgr:showMainLayer()
    -- if not self:isCanShowLayer() then
    --     return nil
    -- end
    if gLobalViewManager:getViewByExtendData("Activity_TimeLimitExpansion_loading") ~= nil then
        return nil
    end
    local uiView = util_createView("Activity_TimeLimitExpansion_loading.Activity_TimeLimitExpansion_loading")
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function TimeLimitExpansionLoadingMgr:showRuleLayer()
    if gLobalViewManager:getViewByExtendData("Activity_TimeLimitExpansionRuleLayer") ~= nil then
        return nil
    end
    local view = util_createView("Activity_TimeLimitExpansion_loading.Activity_TimeLimitExpansionRuleLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

return TimeLimitExpansionLoadingMgr
