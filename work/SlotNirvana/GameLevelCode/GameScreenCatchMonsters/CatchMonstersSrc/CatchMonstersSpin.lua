

local CatchMonstersSpin = class("CatchMonstersSpin", util_require("views.gameviews.SpinBtn"))

function CatchMonstersSpin:setSelfMachine(_machine)
    self.m_machine = _machine
end
function CatchMonstersSpin:onEnter()
    CatchMonstersSpin.super.onEnter(self)

    --取消全部监听，只保留spin按钮的可点击性
    gLobalNoticManager:removeAllObservers(self)
    --只展示stop按钮
    self.m_spinBtn:setVisible(true)
    self.m_autoBtn:setVisible(false)
    self.m_stopBtn:setVisible(false)
end

function CatchMonstersSpin:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        self:clickEndFunc(sender, eventType)
    elseif eventType == ccui.TouchEventType.canceled then
        self:clickEndFunc(sender, eventType)
    end
end

--结束监听
function CatchMonstersSpin:clickEndFunc(sender)
    if self.m_machine then
        local wheelPanelSpin = self.m_machine.m_bonusWheelView.m_wheelPanelSpin
        if not wheelPanelSpin:isVisible() then
            return 
        end
        wheelPanelSpin:skipPanelClickCallBack()
    end
end

return CatchMonstersSpin