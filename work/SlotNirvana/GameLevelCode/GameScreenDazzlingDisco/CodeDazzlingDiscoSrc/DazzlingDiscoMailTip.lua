---
--xcyy
--2018年5月23日
--DazzlingDiscoMailTip.lua

local DazzlingDiscoMailTip = class("DazzlingDiscoMailTip", util_require("base.BaseView"))

function DazzlingDiscoMailTip:initUI(params)
    self:createCsbNode("DazzlingDisco_Mail.csb")
    self.m_touchPanel = self:findChild("touchPanel")
    self:addClick(self.m_touchPanel)

    self.m_machine = params.machine
end

function DazzlingDiscoMailTip:onEnter()
end

function DazzlingDiscoMailTip:onExit()
end

function DazzlingDiscoMailTip:setClickEnable(_enabled)
    self.m_touchPanel:setTouchEnabled(_enabled)

end

--默认按钮监听回调
function DazzlingDiscoMailTip:clickFunc(sender)
    local name = sender:getName()
    if name == "touchPanel" then
        self:setClickEnable(false)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_machine:openMail()
    end
end


return DazzlingDiscoMailTip
