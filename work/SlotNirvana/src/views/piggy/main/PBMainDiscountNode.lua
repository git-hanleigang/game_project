--[[
    折扣 挂在小猪肚子位置
]]
local PBMainDiscountNode = class("PBMainDiscountNode", BaseView)

function PBMainDiscountNode:initDatas()
end

function PBMainDiscountNode:getCsbName()
    return "PigBank2022/csb/main/PBDiscount.csb"
end

function PBMainDiscountNode:initCsbNodes()
    self.m_lbDiscount = self:findChild("lb_discount")
end

function PBMainDiscountNode:initUI()
    PBMainDiscountNode.super.initUI(self)
    self:initView()
end

function PBMainDiscountNode:initView()
    self:initDiscount()
end

function PBMainDiscountNode:initDiscount()
    local upperRate = G_GetMgr(G_REF.PiggyBank):getDiscountRate()
    if upperRate and upperRate > 0 then
        self.m_lbDiscount:setString(upperRate .. "%")
    end
end

return PBMainDiscountNode
