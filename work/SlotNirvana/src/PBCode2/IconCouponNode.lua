--折扣卷特殊道具
local IconCouponNode = class("IconCouponNode", util_require("base.BaseView"))
function IconCouponNode:initUI(data,newIcon,mul)
    self:initView()
    self:updateIcon(newIcon)
    self:updateValue(data,mul)
end
function IconCouponNode:initView()
    self:createCsbNode("PBRes/CommonItemRes/IconNodeCoupon.csb")
    self.m_node_icon = self:findChild("node_icon")
    self.m_lb_value = self:findChild("lb_value")
end
function IconCouponNode:updateIcon(newIcon)
    self.m_node_icon:removeAllChildren()
    local path = "PBRes/CommonItemRes/icon/"..newIcon..".png"
    local spIcon = util_createSprite(path)
    if spIcon then
        self.m_node_icon:addChild(spIcon)
    end
end
function IconCouponNode:updateValue(data,mul)
    self.m_lb_value:setString(data.p_num.."%")
end
return IconCouponNode