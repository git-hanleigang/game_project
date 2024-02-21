--[[

    author:{author}
    time:2022-01-24 11:26:27
]]
local BaseMenuItem = require("views.menu.BaseMenuItem")
local MenuItemRatus = class("MenuItemRatus", BaseMenuItem)

function MenuItemRatus:initView(bDeluxe)
    MenuItemRatus.super.initView(self, bDeluxe)
    if bDeluxe then
        util_changeTexture(self.m_spItemN, "Option/ui/btn_rateus_up1.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_rateus_down1.png")
    else
        util_changeTexture(self.m_spItemN, "Option/ui/btn_rateus_up.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_rateus_down.png")
    end
end

function MenuItemRatus:clickFunc(sender)
    MenuItemRatus.super.clickFunc(self, sender)
    self:onClickRateUs(sender)
end

function MenuItemRatus:onClickRateUs(sender)
    globalData.rateUsData:openRateUsView(nil, "RateUs", false, sender:getTouchEndPosition())
end

return MenuItemRatus
