---
--xcyy
--2018年5月23日
--CoinConiferSkipSpinBtn.lua

local CoinConiferSkipSpinBtn = class("CoinConiferSkipSpinBtn",util_require("views.gameviews.SpinBtn"))

function CoinConiferSkipSpinBtn:setGeminiJourneMachine(_machine)
    self.m_machine = _machine
end
function CoinConiferSkipSpinBtn:onEnter()
    CoinConiferSkipSpinBtn.super.onEnter(self)

    --取消全部监听，只保留spin按钮的可点击性
    gLobalNoticManager:removeAllObservers(self)
    --只展示stop按钮
    self.m_spinBtn:setVisible(false)
    self.m_autoBtn:setVisible(false)
    self.m_stopBtn:setVisible(true)
end

function CoinConiferSkipSpinBtn:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        self:clickEndFunc(sender)
    elseif eventType == ccui.TouchEventType.canceled then
        -- self:clickEndFunc(sender, eventType)
    end
end

--结束监听
function CoinConiferSkipSpinBtn:clickEndFunc(sender)
    if self.m_machine then
        if self.m_machine.stopBtnIndex == 2 then
            self.m_machine.isClickQuickStop2 = true
            self.m_machine:showQuickStopEffect()
        elseif self.m_machine.stopBtnIndex == 1 then
            self.m_machine.isClickQuickStop1 = true
            self.m_machine:showQuickStopEffectForFan()
        end
        
    end
end

return CoinConiferSkipSpinBtn
