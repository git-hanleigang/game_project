--[[--
]]
local BaseView = util_require("base.BaseView")
local InboxPage_send_chooseChip_title = class("InboxPage_send_chooseChip_title", BaseView)

function InboxPage_send_chooseChip_title:initUI(_clanId, _name)
    self:createCsbNode("InBox/FBCard/InboxPage_Send_SelCardPop_biaoqian.csb")
    self:updateUI(_clanId, _name)
end

function InboxPage_send_chooseChip_title:updateUI(_clanId, _name)
    local iconNode = self:findChild("img_kacetu")
    local titleLabel = self:findChild("lb_biaoqian")
    local icon = CardResConfig.getCardClanIcon(_clanId)
    local sp_icon = util_createSprite(icon)
    if sp_icon then 
        sp_icon:setScale(0.3)
        iconNode:addChild(sp_icon)
        local size = sp_icon:getContentSize()
        self.m_height = size.height * 0.4
    end

    titleLabel:setString(_name)
end

function InboxPage_send_chooseChip_title:getHeight()
    return self.m_height
end

return InboxPage_send_chooseChip_title