
local PipeConnectTaskMgr = class("PipeConnectTaskMgr", BaseActivityControl)

function PipeConnectTaskMgr:ctor()
    PipeConnectTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PipeConnectTask)
    self:addPreRef(ACTIVITY_REF.PipeConnect)
end

function PipeConnectTaskMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local uiView = nil
    if gLobalViewManager:getViewByExtendData("PipeConnectTaskMainLayer") == nil then
        uiView = util_createFindView("Activity/PipeConnectTaskMainLayer")
        if uiView ~= nil then
            self:showLayer(uiView, ViewZorder.ZORDER_UI)
        end
    end

    return uiView
end

return PipeConnectTaskMgr
