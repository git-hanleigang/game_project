--[[
    扑克 任务入口按钮
]]
local ActivityTaskBottom_poker = class("ActivityTaskBottom_poker", util_require("views.Activity_Mission.ActivityTaskBottomBase"))

function ActivityTaskBottom_poker:initDatas()
    ActivityTaskBottom_poker.super.initDatas(self)
    self.m_cfg = G_GetMgr(ACTIVITY_REF.Poker):getConfig()
end

function ActivityTaskBottom_poker:initUI()
    ActivityTaskBottom_poker.super.initUI(self)
end

function ActivityTaskBottom_poker:getCsbName()
    return self.m_cfg.taskEntryCsbPath .. ".csb"
end

function ActivityTaskBottom_poker:getActivityName()
    return ACTIVITY_REF.PokerTask
end

function ActivityTaskBottom_poker:getHasProgress()
    return true
end

function ActivityTaskBottom_poker:canClick()
    local mainView = gLobalViewManager:getViewByName("PokerUI_Main")
    if mainView then
        if mainView:getStatusByKey("start_chapter") then
            return false
        end
        if mainView:getStatusByKey("unlock_chapter") then
            return false
        end
        if mainView:getStatusByKey("start_main") then
            return false
        end
        if mainView:getStatusByKey("deal") then
            return false
        end
        if mainView:getStatusByKey("draw") then
            return false
        end
        if mainView:getStatusByKey("complete") then
            return false
        end
    end
    return true
end

function ActivityTaskBottom_poker:clickFunc()
    if not self:canClick() then
        return
    end
    if self.m_isCanTouch then
        return
    end
    self.m_isCanTouch = true
    G_GetMgr(ACTIVITY_REF.PokerTask):showMainLayer()
    self.m_isCanTouch = false
end

return ActivityTaskBottom_poker
