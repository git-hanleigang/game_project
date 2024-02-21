--[[

    author:{author}
    time:2022-01-24 11:26:27
]]
local BaseMenuItem = require("views.menu.BaseMenuItem")
local MenuItemSetting = class("MenuItemSetting", BaseMenuItem)

function MenuItemSetting:initView(bDeluxe)
    MenuItemSetting.super.initView(self, bDeluxe)
    if bDeluxe then
        util_changeTexture(self.m_spItemN, "Option/ui/btn_setting_up1.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_setting_down1.png")
    else
        util_changeTexture(self.m_spItemN, "Option/ui/btn_setting_up.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_setting_down.png")
    end
end

function MenuItemSetting:clickFunc(sender)
    MenuItemSetting.super.clickFunc(self, sender)
    self:onClickSetting(sender)
end

function MenuItemSetting:onClickSetting(sender)
    local view = util_createView("views.setting.SettingsLayerNew")
    local type = DotEntryType.Lobby
    if not gLobalViewManager:isLobbyView() then
        type = DotEntryType.Game
    end
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view, sBtnName, DotUrlType.UrlName, true, DotEntrySite.UpView, type)
    end
    view:setActionType("Curve", sender:getTouchEndPosition())
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

return MenuItemSetting
