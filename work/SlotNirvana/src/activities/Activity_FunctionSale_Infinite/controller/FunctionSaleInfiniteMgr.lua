--[[
    无限促销
]]

local FunctionSaleInfiniteNet = require("activities.Activity_FunctionSale_Infinite.net.FunctionSaleInfiniteNet")
local FunctionSaleInfiniteMgr = class("FunctionSaleInfiniteMgr", BaseActivityControl)

function FunctionSaleInfiniteMgr:ctor()
    FunctionSaleInfiniteMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.FunctionSaleInfinite)
    self.m_net = FunctionSaleInfiniteNet:getInstance()
end

function FunctionSaleInfiniteMgr:showMainLayer(_data)
    local view = self:createPopLayer(_data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    elseif _data and _data.closeFunc then
        _data.closeFunc()
    end
    return view
end

function FunctionSaleInfiniteMgr:createEntryNode()
    if not self:isCanShowLayer() then
        return
    end

    local entry = util_createView("Activity_FunctionSale_Infinite.Activity.FunctionSaleInfiniteLogo")
    return entry
end

function FunctionSaleInfiniteMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function FunctionSaleInfiniteMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function FunctionSaleInfiniteMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function FunctionSaleInfiniteMgr:sendCollect()
    self.m_net:sendCollect()
end

function FunctionSaleInfiniteMgr:buySale(_data, _pickIdx)
    self.m_net:buySale(_data, _pickIdx)
end

function FunctionSaleInfiniteMgr:checkShowMainLayer(_data)
    local view = nil
    local closeFunc = _data.closeFunc
    local data = self:getRunningData()
    if data then
        view = self:showMainLayer(_data)
    else
        if closeFunc then
            closeFunc()
        end
    end

    return view
end

return FunctionSaleInfiniteMgr
