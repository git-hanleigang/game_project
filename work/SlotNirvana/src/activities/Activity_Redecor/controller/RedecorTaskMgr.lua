--[[
    装修任务
    author: 徐袁
    time: 2021-09-09 14:57:13
]]
local activityTaskManager = util_require("manager.ActivityTaskManager")
local RedecorTaskMgr = class("RedecorTaskMgr", BaseActivityControl)

function RedecorTaskMgr:ctor()
    RedecorTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.RedecorTask)
    self:addPreRef(ACTIVITY_REF.Redecor)
end

-- function RedecorTaskMgr:getData()
--     return activityTaskManager:getInstance():getTaskListByActivityName("REDECORATE")
-- end

-- function RedecorTaskMgr:getRunningData()
--     if not self:checkPreRefName() then
--         return nil
--     end

--     return self:getData()
-- end

function RedecorTaskMgr:showMainLayer(_isResumeCor)
    if not self:isCanShowLayer() then
        return nil
    end

    if not self:checkPreRefName() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("RedecorTaskMainLayer") == nil then
        local ui = util_createFindView("Activity/RedecorTaskMainLayer", _isResumeCor)
        if ui ~= nil then
            gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
        end
    end

    return uiView
end

return RedecorTaskMgr
