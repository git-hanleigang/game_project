--[[

    author:{author}
    time:2022-01-24 11:26:27
]]
local BaseMenuItem = require("views.menu.BaseMenuItem")
local MenuItemGiftCode = class("MenuItemGiftCode", BaseMenuItem)

function MenuItemGiftCode:initView(bDeluxe)
    MenuItemGiftCode.super.initView(self, bDeluxe)
    if bDeluxe then
        util_changeTexture(self.m_spItemN, "Option/ui/btn_gift_up_2.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_gift_down_2.png")
    else
        util_changeTexture(self.m_spItemN, "Option/ui/btn_gift_up_1.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_gift_down_1.png")
    end
end

function MenuItemGiftCode:clickFunc(sender)
    MenuItemGiftCode.super.clickFunc(self, sender)
    self:onClickGift(sender)
end

function MenuItemGiftCode:onClickGift(sender)
    local view = util_createView("views.GiftCodes.Activity_GiftCodes")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

return MenuItemGiftCode
