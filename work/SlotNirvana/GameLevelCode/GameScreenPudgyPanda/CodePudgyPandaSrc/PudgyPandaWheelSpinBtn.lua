---
--xcyy
--2018年5月23日
--PudgyPandaWheelSpinBtn.lua

local PudgyPandaWheelSpinBtn = class("PudgyPandaWheelSpinBtn",util_require("views.gameviews.SpinBtn"))

function PudgyPandaWheelSpinBtn:setPudgyPandaMachine(_machine)
    self.m_PudgyPandaMachine = _machine
end
function PudgyPandaWheelSpinBtn:onEnter()
    PudgyPandaWheelSpinBtn.super.onEnter(self)

    --取消全部监听，只保留spin按钮的可点击性
    gLobalNoticManager:removeAllObservers(self)
    --只展示spin按钮
    self.m_spinBtn:setVisible(true)
    self.m_autoBtn:setVisible(false)
    self.m_stopBtn:setVisible(false)
end

function PudgyPandaWheelSpinBtn:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        self:clickEndFunc(sender)
    elseif eventType == ccui.TouchEventType.canceled then
        self:clickEndFunc(sender, eventType)
    end
end

--结束监听
function PudgyPandaWheelSpinBtn:clickEndFunc(sender)
    if self.m_PudgyPandaMachine then
        local m_wheelReel = self.m_PudgyPandaMachine.m_wheelReel
        if tolua.isnull(m_wheelReel)then
            return
        end
        self.m_PudgyPandaMachine:sendSelectWheelData()
    end
end

return PudgyPandaWheelSpinBtn
