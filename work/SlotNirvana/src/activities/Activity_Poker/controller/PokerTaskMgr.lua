--[[
    videopoker任务
]]
local PokerTaskMgr = class("PokerTaskMgr", BaseActivityControl)

function PokerTaskMgr:ctor()
    PokerTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PokerTask)
    self:addPreRef(ACTIVITY_REF.Poker)
end

-- 检查任务是否完成弹出任务面板
function PokerTaskMgr:checkTaskCompleted()
    local taskMgr = util_require("manager.ActivityTaskManager"):getInstance()
    local bOpenTask = taskMgr:checkTaskData(ACTIVITY_REF.PokerTask)
    local bComplete = taskMgr:checkTaskCompleted(ACTIVITY_REF.PokerTask)
    if bOpenTask and bComplete then
        return true
    end
    return false
end

function PokerTaskMgr:showMainLayer(_isCompleted, _overCallFunc)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("PokerTaskMainLayer") ~= nil then
        return nil
    end
    local params = {}
    if _isCompleted then
        params.isCompleted = true
    end
    if _overCallFunc then
        params.overCallFunc = _overCallFunc
    end
    local view = util_createFindView("PokerTaskMainLayer", params)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function PokerTaskMgr:showRewardLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("PokerTaskRewardLayer") ~= nil then
        return nil
    end
    local view = util_createView("PokerTaskRewardLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

return PokerTaskMgr
