--[[
Author: ZKK
Description: 比赛聚合 宣传
--]]
local BattleMatchRuleManager = class("BattleMatchRuleManager", BaseActivityControl)

function BattleMatchRuleManager:ctor()
    BattleMatchRuleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BattleMatch_Rule)
    self:addPreRef(ACTIVITY_REF.BattleMatch)
end

function BattleMatchRuleManager:isCanShowPop()
    local result = true
    local mrg = G_GetMgr(ACTIVITY_REF.BattleMatch_Rule)
    if mrg then
        result = result and mrg:isRunning() 
    end

    local mrg = G_GetMgr(ACTIVITY_REF.BattleMatch)
    if mrg then
        result = result and mrg:isRunning() 
    end

    return true
end
function BattleMatchRuleManager:getTaskData(_ignoreComingsoon)
    local taskData = {}
    local mrg = G_GetMgr(ACTIVITY_REF.BattleMatch)
    if mrg and mrg:getRunningData() then
        taskData = clone(mrg:getRunningData():getTaskData())
    end

    return taskData
end

function BattleMatchRuleManager:checkShowResultLayer(_overFunc)
    local battleMatchData = G_GetMgr(ACTIVITY_REF.BattleMatch):getData()
    if battleMatchData and battleMatchData.m_collect then
        if not self:isDownloadRes() then
            if _overFunc then
                _overFunc()
            end
        end
        
        local uiView = util_createFindView("Activity/Activity_BattleMatch_ResultLayer",_overFunc)
        if uiView ~= nil then
            gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
            return true
        end
    else
        if _overFunc then
            _overFunc()
        end
    end
    return false
end

function BattleMatchRuleManager:showRuleLayer(info,_overFunc)
    local battleMatchData = G_GetMgr(ACTIVITY_REF.BattleMatch):getData()
    if battleMatchData then
        if not self:isDownloadRes() then
            if _overFunc then
                _overFunc()
            end
        end
        
        local uiView = util_createFindView("Activity/Activity_BattleMatch_Rule",nil,_overFunc)
        if uiView ~= nil then
            gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
            return true
        end
    else
        if _overFunc then
            _overFunc()
        end
    end
end


return BattleMatchRuleManager
