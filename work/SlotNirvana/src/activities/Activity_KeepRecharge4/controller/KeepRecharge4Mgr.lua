--[[
    4格连续充值
]]

local KeepRecharge4Net = require("activities.Activity_KeepRecharge4.net.KeepRecharge4Net")
local KeepRecharge4Mgr = class("KeepRecharge4Mgr", BaseActivityControl)

function KeepRecharge4Mgr:ctor()
    KeepRecharge4Mgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.KeepRecharge4)
    self.m_net = KeepRecharge4Net:getInstance()
end

function KeepRecharge4Mgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function KeepRecharge4Mgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. themeName .. "HallNode" 
end

function KeepRecharge4Mgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. themeName .. "SlideNode" 
end

function KeepRecharge4Mgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function KeepRecharge4Mgr:sendFreeReward(_index)
    self.m_net:sendFreeReward(_index)
end

function KeepRecharge4Mgr:buySale(_params)
    self.m_net:buySale(_params)
end

return KeepRecharge4Mgr
