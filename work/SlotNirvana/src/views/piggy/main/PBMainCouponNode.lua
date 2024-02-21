--[[
    小猪优惠券节点
]]
local PBMainCouponNode = class("PBMainCouponNode", BaseView)

-- PBTODO
function PBMainCouponNode:getCsbName()
    return "PigBank2022/csb/main/PBCoupon.csb"
end

function PBMainCouponNode:initDatas()
end

function PBMainCouponNode:initCsbNodes()
    self.m_lbCoupon = self:findChild("lb_coupon")
end

function PBMainCouponNode:initUI()
    PBMainCouponNode.super.initUI(self)
    self:initCoupon()
end

function PBMainCouponNode:initCoupon()
    local num = G_GetMgr(G_REF.PiggyBank):getCouponRate()
    if num and num > 0 then
        self:setVisible(true)
        self.m_lbCoupon:setString(num .. "%")
    else
        self:setVisible(false)
    end
end

return PBMainCouponNode
