local ZQCoinStoreItemTicket = class("ZQCoinStoreItemTicket",util_require("base.BaseView"))

function ZQCoinStoreItemTicket:initUI()
    self:createCsbNode("shop_title/Tittle_coupon.csb")
    self:runCsbAction("animation",true)
    self.m_lb_more = self:findChild("m_lb_more")
end

function ZQCoinStoreItemTicket:updateUI(itemData)
    if itemData and itemData.p_ticketDiscount then
        self.m_lb_more:setString(itemData.p_ticketDiscount.."%")
    else
        self:setVisible(false)
    end    
end

return ZQCoinStoreItemTicket