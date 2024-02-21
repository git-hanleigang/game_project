---
--xcyy
--2018年5月23日
--BingoldKoiSkipSpinBtn.lua

local BingoldKoiSkipSpinBtn = class("BingoldKoiSkipSpinBtn",util_require("views.gameviews.SpinBtn"))

function BingoldKoiSkipSpinBtn:setBingoldKoiMachine(_machine)
    self.m_bingoldKoiMachine     = _machine
end
function BingoldKoiSkipSpinBtn:onEnter()
    BingoldKoiSkipSpinBtn.super.onEnter(self)

    --取消全部监听，只保留spin按钮的可点击性
    gLobalNoticManager:removeAllObservers(self)
    --只展示stop按钮
    self.m_spinBtn:setVisible(false)
    self.m_autoBtn:setVisible(false)
    self.m_stopBtn:setVisible(true)
end

function BingoldKoiSkipSpinBtn:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        self:clickEndFunc(sender)
    elseif eventType == ccui.TouchEventType.canceled then
        self:clickEndFunc(sender, eventType)
    end
end

--结束监听
function BingoldKoiSkipSpinBtn:clickEndFunc(sender)
    if self.m_bingoldKoiMachine then
        local skip_click = self.m_bingoldKoiMachine.m_skip_click
        if not skip_click:isVisible() then
            return 
        end
        self.m_bingoldKoiMachine:runSkipCollect()
    end
end

return BingoldKoiSkipSpinBtn
