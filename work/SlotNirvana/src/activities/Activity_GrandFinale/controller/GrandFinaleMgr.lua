--[[
    赛季末返新卡
]]

local GrandFinaleNet = require("activities.Activity_GrandFinale.net.GrandFinaleNet")
local GrandFinaleMgr = class("GrandFinaleMgr", BaseActivityControl)

function GrandFinaleMgr:ctor()
    GrandFinaleMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.GrandFinale)
    self.m_net = GrandFinaleNet:getInstance()
end

function GrandFinaleMgr:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("Activity_GrandFinale") then
        if _data and _data.closeFunc then
            _data.closeFunc()
        end
        return
    end

    local view = self:createPopLayer(_data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function GrandFinaleMgr:shwoBuyLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("Activity_GrandFinaleBuyLayer") == nil then
        local view = util_createView("Activity_GrandFinale.Activity.Activity_GrandFinaleBuyLayer", _data)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function GrandFinaleMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function GrandFinaleMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function GrandFinaleMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function GrandFinaleMgr:sendCollect()
    self.m_net:sendCollect()
end

function GrandFinaleMgr:sendRefreshData()
    self.m_net:sendRefreshData()
end

function GrandFinaleMgr:buyUnlock(_data)
    self.m_net:buyUnlock(_data)
end

function GrandFinaleMgr:checkCollectReward()
    local flag = false
    local gameData = self:getRunningData()
    if gameData then
        flag = gameData:hasReward()
    end
    return flag
end

return GrandFinaleMgr
