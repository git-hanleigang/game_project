---
--xcyy
--2018年5月23日
--GeminiJourneySkipSpinBtn.lua

local GeminiJourneySkipSpinBtn = class("GeminiJourneySkipSpinBtn",util_require("views.gameviews.SpinBtn"))

function GeminiJourneySkipSpinBtn:setGeminiJourneMachine(_machine)
    self.m_GeminiJourneyMachine = _machine
end
function GeminiJourneySkipSpinBtn:onEnter()
    GeminiJourneySkipSpinBtn.super.onEnter(self)

    --取消全部监听，只保留spin按钮的可点击性
    gLobalNoticManager:removeAllObservers(self)
    --只展示stop按钮
    self.m_spinBtn:setVisible(false)
    self.m_autoBtn:setVisible(false)
    self.m_stopBtn:setVisible(true)
end

function GeminiJourneySkipSpinBtn:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        self:clickEndFunc(sender)
    elseif eventType == ccui.TouchEventType.canceled then
        self:clickEndFunc(sender, eventType)
    end
end

--结束监听
function GeminiJourneySkipSpinBtn:clickEndFunc(sender)
    if self.m_GeminiJourneyMachine then
        local skip_click = self.m_GeminiJourneyMachine.m_skip_click
        if not skip_click:isVisible() then
            return 
        end
        self.m_GeminiJourneyMachine:runSkipCollect()
    end
end

return GeminiJourneySkipSpinBtn
