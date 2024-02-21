--[[
    红蓝对决
]]
local FactionFightNet = require("activities.Activity_FactionFight.net.FactionFightNet")
local FactionFightControl = class("FactionFightControl", BaseActivityControl)

function FactionFightControl:ctor()
    FactionFightControl.super.ctor(self)

    self:setRefName(ACTIVITY_REF.FactionFight)

    self.m_netModel = FactionFightNet:getInstance() -- 网络模块
end

function FactionFightControl:showCampSelectLayer()
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity.FactionFight_Choice")
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function FactionFightControl:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity.FactionFight_Main")
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function FactionFightControl:showInfoLayer(_index)
    local view = util_createView("Activity.FactionFight_Help", _index)
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function FactionFightControl:showCollectLayer(_params)
    local view = util_createView("Activity.FactionFight_Pass_Collect", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function FactionFightControl:showBuyBuffLayer()
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity.FactionFight_Buff_Layer")
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

-- 显示飞分数
function FactionFightControl:showGetScoreLayer()
    local activityData = self:getRunningData()
    if activityData then
        if not self:isCanShowLayer() then
            return false
        end

        local score = activityData:getSpinScore()
        if not score or score <= 0 then
            return false
        end
        -- 获取要飞到的坐标
        local _node = gLobalActivityManager:getEntryNode(ACTIVITY_REF.FactionFight)
        if not _node then
            return false
        end

        local flyDesPos = _node:getFlyPos()
        local _isVisible = gLobalActivityManager:getEntryNodeVisible(ACTIVITY_REF.FactionFight)
        if not _isVisible then
            -- 隐藏图标的时候使用箭头坐标
            flyDesPos = gLobalActivityManager:getEntryArrowWorldPos()
        end

        if not flyDesPos then
            return false
        end
        local mySide = activityData:getMySide()
        local buffMultiple = 1
        local buffData = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_FACTION_FIGHT)
        if buffData then
            buffMultiple = tonumber(buffData.buffMultiple)
        end

        local layer = util_createView("Activity.Activity_FactionFight_Scroe")
        gLobalViewManager:showUI(layer, ViewZorder.ZORDER_GUIDE, false)
        layer:playFlyAction(score, flyDesPos, mySide, buffMultiple)
        activityData:setSpinScore(0)

        return true
    else
        return false
    end
end

-- 弹窗逻辑
function FactionFightControl:showPopLayer(popInfo, callback)
    if popInfo and popInfo.clickFlag then
        local gameData = self:getRunningData()
        if gameData then
            local mySide = gameData:getMySide()

            if mySide and mySide ~= "" then
                return self:showMainLayer()
            end
        end
    end

    return FactionFightControl.super.showPopLayer(self, popInfo, callback)
end

function FactionFightControl:selectCamp(_side, _pos)
    self.m_netModel:selectCamp(_side, _pos)
end

function FactionFightControl:passCollect(_index)
    self.m_netModel:passCollect(_index)
end

function FactionFightControl:requestRankData()
    self.m_netModel:requestRankData()
end

function FactionFightControl:buyBuff(_data)
    self.m_netModel:buyBuff(_data)
end

function FactionFightControl:dataRefresh(_data)
    self.m_netModel:dataRefresh()
end

function FactionFightControl:parseSpinData(_data)
    local gameData = self:getRunningData()
    if gameData then
        gameData:parseSpinData(_data)
    end
end

function FactionFightControl:setBubbleStats(_stats)
    self.m_bubbleStats = _stats
end

function FactionFightControl:getBubbleStats()
    return self.m_bubbleStats
end

return FactionFightControl
