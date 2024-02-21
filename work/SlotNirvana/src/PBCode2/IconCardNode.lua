--集卡特殊道具
local IconCardNode = class("IconCardNode", util_require("base.BaseView"))
function IconCardNode:initUI(data,newIcon,mul)
    self:initView()
    self:updateIcon(newIcon)
    self:updateValue(data,mul)
end
function IconCardNode:initView()
    self:createCsbNode("PBRes/CommonItemRes/IconNodeCard.csb")
    self.m_node_icon = self:findChild("node_icon")
    self.m_lb_value = self:findChild("lb_value")
    self.m_lb_num = self:findChild("lb_num")
end
function IconCardNode:updateIcon(newIcon)
    self.m_node_icon:removeAllChildren()
    local path = "PBRes/CommonItemRes/icon/"..newIcon..".png"
    local spIcon = util_createSprite(path)
    if spIcon then
        self.m_node_icon:addChild(spIcon)
    end
end
function IconCardNode:updateValue(data,mul)
    if not data or not data.p_mark or #data.p_mark<4 then
        self.m_lb_value:setVisible(false)
        self.m_lb_num:setVisible(false)
        return
    end

    local min = data.p_mark[4]
    -- local star = data.p_mark[3] --暂时用不上
    local num = data.p_mark[2]
    self.m_lb_value:setString("MIN "..min.." OF")
    self.m_lb_num:setString("X"..num)
end
return IconCardNode