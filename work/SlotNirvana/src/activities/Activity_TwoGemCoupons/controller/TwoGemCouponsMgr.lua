--[[  
    第二货币两张优惠券
]]

local TwoGemCouponsMgr = class("TwoGemCouponsMgr", BaseActivityControl)

function TwoGemCouponsMgr:ctor()
    TwoGemCouponsMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.TwoGemCoupons)
end

-- 显示主界面
function TwoGemCouponsMgr:showMainLayer()
    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function TwoGemCouponsMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function TwoGemCouponsMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function TwoGemCouponsMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return TwoGemCouponsMgr
