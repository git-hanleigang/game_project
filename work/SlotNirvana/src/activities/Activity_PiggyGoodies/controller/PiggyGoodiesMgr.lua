--[[
    新版小猪挑战
]]

local PiggyGoodiesNet = require("activities.Activity_PiggyGoodies.net.PiggyGoodiesNet")
local PiggyGoodiesMgr = class("PiggyGoodiesMgr", BaseActivityControl)

function PiggyGoodiesMgr:ctor()
    PiggyGoodiesMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.PiggyGoodies)
    self.m_netModel = PiggyGoodiesNet:getInstance()   -- 网络模块
end

function PiggyGoodiesMgr:showMainLayer(_data)
    local view = self:createPopLayer(_data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function PiggyGoodiesMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function PiggyGoodiesMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function PiggyGoodiesMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function PiggyGoodiesMgr:sendCollect(_pickIndex)
    self.m_netModel:sendCollect(_pickIndex)
end

function PiggyGoodiesMgr:checkOpenMainLayer()
    local data = self:getRunningData()
    if data then
        local stageList = data:getStageList()
        local curStage = data:getCurStageData()
        local stage = stageList[curStage]
        if stage.p_curProgress >= stage.p_params and stage.p_collectTimes > 0 then
            return true
        end
    end

    return false
end

function PiggyGoodiesMgr:hasReward()
    local flag = false
    local data = self:getRunningData()
    if data then
        local curStage = data:getCurStageData()
        local stageList = data:getStageList()
        local stageData = stageList[curStage]
        flag = stageData.p_curProgress >= stageData.p_params and not stageData.p_finished
    end
    return flag
end

return PiggyGoodiesMgr
