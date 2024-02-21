--[[
    
    author:{author}
    time:2021-09-28 17:58:50
]]
local WordTaskMgr = class("WordTaskMgr", BaseActivityControl)

function WordTaskMgr:ctor()
    WordTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.WordTask)
    self:addPreRef(ACTIVITY_REF.Word)
end

function WordTaskMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local WordTaskMainLayer = nil
    if gLobalViewManager:getViewByExtendData("WordTaskMainLayer") == nil then
        WordTaskMainLayer = util_createFindView("Activity/WordTaskMainLayer")
        if WordTaskMainLayer ~= nil then
            gLobalViewManager:showUI(WordTaskMainLayer, ViewZorder.ZORDER_UI)
        end
    end
    return WordTaskMainLayer
end

function WordTaskMgr:showRewardLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local taskView = util_createView("Activity.WordTaskRewardLayer")
    gLobalViewManager:showUI(taskView, ViewZorder.ZORDER_UI)
    return taskView
end

return WordTaskMgr
