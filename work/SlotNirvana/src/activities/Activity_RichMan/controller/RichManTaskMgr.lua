--[[
    
    author: 徐袁
    time: 2021-09-03 11:14:16
]]
local RichManTaskMgr = class("RichManTaskMgr", BaseActivityControl)

RichManTaskMgr.richmanData = nil

function RichManTaskMgr:ctor()
    RichManTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.RichManTask)
    self:addPreRef(ACTIVITY_REF.RichMan)
end

function RichManTaskMgr:showMainLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end

    local mainLayer = nil
    if gLobalViewManager:getViewByExtendData("RichManTaskMainLayer") == nil then
        mainLayer = util_createFindView("Activity/RichManTaskMainLayer")
        if mainLayer ~= nil then
            gLobalViewManager:showUI(mainLayer, ViewZorder.ZORDER_UI)
        end
    end
    return mainLayer
end

--打开奖励页
function RichManTaskMgr:showRewardLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local taskView = util_createView("Activity.RichManTaskRewardLayer")
    gLobalViewManager:showUI(taskView, ViewZorder.ZORDER_UI)
    return taskView
end

return RichManTaskMgr
