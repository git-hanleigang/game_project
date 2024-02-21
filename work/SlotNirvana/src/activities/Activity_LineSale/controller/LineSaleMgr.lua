--[[
    bingo连线
]]

local LineSaleNet = require("activities.Activity_LineSale.net.LineSaleNet")
local LineSaleMgr = class("LineSaleMgr", BaseActivityControl)

function LineSaleMgr:ctor()
    LineSaleMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.LineSale)
    self.m_net = LineSaleNet:getInstance()
end

function LineSaleMgr:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("Activity_LineSale") == nil then
        local view = util_createView("Activity_LineSale.Activity.Activity_LineSale", _data)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function LineSaleMgr:showInfoLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("LineSaleInfo") == nil then
        local view = util_createView("Activity_LineSale.Activity.LineSaleInfo")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function LineSaleMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function LineSaleMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function LineSaleMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

-- 付费
function LineSaleMgr:buySale(_data)
    self.m_net:buySale(_data)
end

return LineSaleMgr
