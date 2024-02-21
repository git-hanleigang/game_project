--折扣卷特殊道具
local IconCashBackNode = class("IconCashBackNode", util_require("base.BaseView"))
function IconCashBackNode:initUI(data,newIcon,mul)
    self:initView()
    self:updateIcon(newIcon)
    self:updateValue(data,mul)
end
function IconCashBackNode:initView()
    self:createCsbNode("PBRes/CommonItemRes/IconNodeCashBack.csb")
    self.m_node_icon = self:findChild("node_icon")
    self.m_lb_value = self:findChild("lb_value")
end
function IconCashBackNode:updateIcon(newIcon)
    self.m_node_icon:removeAllChildren()
    local path = "PBRes/CommonItemRes/icon/"..newIcon..".png"
    local spIcon = util_createSprite(path)
    if spIcon then
        self.m_node_icon:addChild(spIcon)
    end
end
function IconCashBackNode:updateValue(data, mul)
    local value = data:getBuffValue(mul)
    self.m_lb_value:setString(value)
end
return IconCashBackNode