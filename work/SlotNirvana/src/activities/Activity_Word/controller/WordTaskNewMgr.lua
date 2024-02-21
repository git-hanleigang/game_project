--[[
    word任务
    author: maqun
    time: 2021-09-05 11:34:35
]]
local WordTaskNewMgr = class("WordTaskNewMgr", BaseActivityControl)

function WordTaskNewMgr:ctor()
    WordTaskNewMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.WordTaskNew)
    self:addPreRef(ACTIVITY_REF.Word)
end

function WordTaskNewMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if not util_IsFileExist("Activity/WordTaskMainLayerNew.lua") and not util_IsFileExist("Activity/WordTaskMainLayerNew.luac") then
        return nil
    end
    local uiView = nil
    if gLobalViewManager:getViewByExtendData("WordTaskMainLayerNew") == nil then
        uiView = util_createFindView("Activity/WordTaskMainLayerNew")
        if uiView ~= nil then
            gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
        end
    end

    return uiView
end

return WordTaskNewMgr
