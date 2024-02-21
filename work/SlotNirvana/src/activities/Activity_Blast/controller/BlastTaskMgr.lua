--[[
    blast任务
    author: 徐袁
    time: 2021-09-05 11:34:35
]]
local BlastTaskMgr = class("BlastTaskMgr", BaseActivityControl)

function BlastTaskMgr:ctor()
    BlastTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BlastTask)
    self:addPreRef(ACTIVITY_REF.Blast)

    self:addExtendResList("Activity_BlastTaskCode")
end

function BlastTaskMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local uiView = nil
    if gLobalViewManager:getViewByExtendData("BlastTaskMainLayer") == nil then
        uiView = util_createFindView("Activity/BlastTaskMainLayer")
        if uiView ~= nil then
            gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
        end
    end

    return uiView
end

return BlastTaskMgr
