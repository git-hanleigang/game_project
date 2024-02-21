--[[
    排行榜 mgr
]]
local OutsideCaveShowTopManager = class("OutsideCaveShowTopManager", BaseActivityControl)

function OutsideCaveShowTopManager:ctor()
    OutsideCaveShowTopManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.OutsideCaveShowTop)
    self:addPreRef(ACTIVITY_REF.OutsideCave)
end

function OutsideCaveShowTopManager:showMainLayer(...)
    return G_GetMgr(ACTIVITY_REF.OutsideCave):showRankLayer(...)
end

function OutsideCaveShowTopManager:getHallPath(hallName)
    return "" .. hallName .. "/" .. hallName .. "HallNode"
end

function OutsideCaveShowTopManager:getSlidePath(slideName)
    return "" .. slideName .. "/" .. slideName .. "SlideNode"
end

function OutsideCaveShowTopManager:getPopPath(popName)
    return "" .. popName .. "/" .. popName
end

function OutsideCaveShowTopManager:showInfoLayer(...)
    return G_GetMgr(ACTIVITY_REF.OutsideCave):showRankInfoLayer(...)
end

return OutsideCaveShowTopManager
