---
--xcyy
--2018年5月23日
--LottoPartyMailTip.lua

local LottoPartyMailTip = class("LottoPartyMailTip", util_require("base.BaseView"))

function LottoPartyMailTip:initUI()
    self:createCsbNode("LottoParty_Mail.csb")
    self.m_touchPanel = self:findChild("touchPanel")
    self:addClick(self.m_touchPanel)
end

function LottoPartyMailTip:onEnter()
end

function LottoPartyMailTip:onExit()
end

function LottoPartyMailTip:setClickEnable(_enabled)
    self.m_touchPanel:setTouchEnabled(_enabled)

end

--默认按钮监听回调
function LottoPartyMailTip:clickFunc(sender)
    local name = sender:getName()
    if name == "touchPanel" then
        self:setClickEnable(false)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_SHOW_MAIL_WIN)
    end
end


return LottoPartyMailTip
