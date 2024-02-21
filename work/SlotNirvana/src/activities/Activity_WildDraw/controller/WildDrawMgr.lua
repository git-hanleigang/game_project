--[[  
    wild卡转盘
]]

local WildDrawNet = require("activities.Activity_WildDraw.net.WildDrawNet")
local WildDrawMgr = class("WildDrawMgr", BaseActivityControl)

function WildDrawMgr:ctor()
    WildDrawMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.WildDraw)
    self.m_net = WildDrawNet:getInstance()
end

-- 显示主界面
function WildDrawMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local themeName = self:getThemeName()

    if gLobalViewManager:getViewByExtendData("WildDrawMainLayer") == nil then
        local view = util_createView(themeName .. "/Activity/WildDrawMainLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function WildDrawMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function WildDrawMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function WildDrawMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function WildDrawMgr:sendWildDraw()
    self.m_net:sendWildDraw()
end

function WildDrawMgr:sendBuySale(_data)
    self.m_net:buySale(_data)
end

return WildDrawMgr
