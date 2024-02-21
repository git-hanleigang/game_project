---
--xcyy
--2018年5月23日
--LuckyRacingMailTip.lua

local LuckyRacingMailTip = class("LuckyRacingMailTip", util_require("base.BaseView"))

function LuckyRacingMailTip:initUI(params)
    self:createCsbNode("LuckyRacing_Mail.csb")
    self.m_touchPanel = self:findChild("touchPanel")
    self:addClick(self.m_touchPanel)

    self.m_machine = params.machine
end

function LuckyRacingMailTip:onEnter()
end

function LuckyRacingMailTip:onExit()
end

function LuckyRacingMailTip:setClickEnable(_enabled)
    self.m_touchPanel:setTouchEnabled(_enabled)

end

--默认按钮监听回调
function LuckyRacingMailTip:clickFunc(sender)
    local name = sender:getName()
    if name == "touchPanel" then
        self:setClickEnable(false)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_machine:openMail()
    end
end


return LuckyRacingMailTip
