--[[
    鲨鱼游戏道具化促销
]]

local MythicGameSaleNet = require("activities.Activity_CardGame_Sale.net.MythicGameSaleNet")
local MythicGameSaleMgr = class("MythicGameSaleMgr", BaseActivityControl)

function MythicGameSaleMgr:ctor()
    MythicGameSaleMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.MythicGameSale)
    self.m_net = MythicGameSaleNet:getInstance()
end

function MythicGameSaleMgr:showMainLayer(_data)
    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function MythicGameSaleMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function MythicGameSaleMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function MythicGameSaleMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

-- 付费
function MythicGameSaleMgr:buySale(_data)
    self.m_net:buySale(_data)
end

return MythicGameSaleMgr
