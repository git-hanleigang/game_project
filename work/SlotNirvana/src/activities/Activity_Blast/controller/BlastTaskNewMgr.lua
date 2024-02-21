--[[
    blast任务
    author: 徐袁
    time: 2021-09-05 11:34:35
]]
local BlastTaskNewMgr = class("BlastTaskNewMgr", BaseActivityControl)

function BlastTaskNewMgr:ctor()
    BlastTaskNewMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BlastTaskNew)
    self:addPreRef(ACTIVITY_REF.Blast)

    self:addExtendResList("Activity_BlastTaskCode")
end

function BlastTaskNewMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if not util_IsFileExist("Activity/BlastTaskMainLayerNew.lua") and not util_IsFileExist("Activity/BlastTaskMainLayerNew.luac") then
        return nil
    end
    local uiView = nil
    if gLobalViewManager:getViewByExtendData("BlastTaskMainLayerNew") == nil then
        uiView = util_createFindView("Activity/BlastTaskMainLayerNew")
        if uiView ~= nil then
            gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
        end
    end

    return uiView
end

return BlastTaskNewMgr
