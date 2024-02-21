local ShopItemTicketNode = class("ShopItemTicketNode",util_require("base.BaseView"))

function ShopItemTicketNode:initUI()
    self:createCsbNode("shop_title/Tittle_coupon_2022.csb")
    self:runCsbAction("animation",true)
    self.m_lb_more = self:findChild("m_lb_more")
end

function ShopItemTicketNode:updateUI(itemData)
    if itemData and itemData.p_ticketDiscount then
        self.m_lb_more:setString(itemData.p_ticketDiscount.."%")
    else
        self:setVisible(false)
    end    
end

return ShopItemTicketNode