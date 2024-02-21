---
--xcyy
--2018年5月23日
--LottoPartyJackPotSymbolTouchView.lua

local LottoPartyJackPotSymbolTouchView = class("LottoPartyJackPotSymbolTouchView", util_require("base.BaseView"))

function LottoPartyJackPotSymbolTouchView:initUI()
    self:createCsbNode("LottoParty_click.csb")
    self.m_touchPanel = self:findChild("touchPanel")
    self:addClick( self.m_touchPanel)
    self:setPanelTouch(false)
end

function LottoPartyJackPotSymbolTouchView:onEnter()
end

function LottoPartyJackPotSymbolTouchView:onExit()
end

function LottoPartyJackPotSymbolTouchView:setClickFunc( _func )
    self.m_func = _func
end
function LottoPartyJackPotSymbolTouchView:setPanelTouch(_enable)
    self.m_touchPanel:setTouchEnabled(_enable)
end
--默认按钮监听回调
function LottoPartyJackPotSymbolTouchView:clickFunc(sender)
    local name = sender:getName()
    if name == "touchPanel" then
        self:setPanelTouch(false)
        local tag = self:getTag()
        if self.m_func then
            self.m_func(tag)
        end
    end
end

return LottoPartyJackPotSymbolTouchView
