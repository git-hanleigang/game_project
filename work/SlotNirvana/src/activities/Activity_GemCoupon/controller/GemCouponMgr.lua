--[[
    第二货币商城折扣送道具
]]
local GemCouponMgr = class("GemCouponMgr", BaseActivityControl)

function GemCouponMgr:ctor()
    GemCouponMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.GemCoupon)
end

function GemCouponMgr:showMainLayer()
    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function GemCouponMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function GemCouponMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function GemCouponMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return GemCouponMgr
