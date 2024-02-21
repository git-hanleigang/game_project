--[[
    高倍场体验卡促销
]]

local HighClubSaleNet = require("activities.Activity_HighClubSale.net.HighClubSaleNet")
local HighClubSaleMgr = class("HighClubSaleMgr", BaseActivityControl)

function HighClubSaleMgr:ctor()
    HighClubSaleMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.HighClubSale)
    self.m_net = HighClubSaleNet:getInstance()
end

function HighClubSaleMgr:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function HighClubSaleMgr:checkShowMainLayer()
    local data = self:getRunningData()
    if data and data:isUnlock() then
        self:showMainLayer()
    end
end

function HighClubSaleMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function HighClubSaleMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function HighClubSaleMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function HighClubSaleMgr:buySale(_data)
    self.m_net:buySale(_data)
end

return HighClubSaleMgr
