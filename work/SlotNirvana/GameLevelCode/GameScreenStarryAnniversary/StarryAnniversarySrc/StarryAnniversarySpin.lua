

local StarryAnniversarySpin = class("StarryAnniversarySpin", util_require("views.gameviews.SpinBtn"))

function StarryAnniversarySpin:setKangaPocketsMachine(_machine)
    self.m_machine = _machine
end
function StarryAnniversarySpin:onEnter()
    StarryAnniversarySpin.super.onEnter(self)

    --取消全部监听，只保留spin按钮的可点击性
    gLobalNoticManager:removeAllObservers(self)
    --只展示stop按钮
    self.m_spinBtn:setVisible(false)
    self.m_autoBtn:setVisible(false)
    self.m_stopBtn:setVisible(true)
end

function StarryAnniversarySpin:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        self:clickEndFunc(sender, eventType)
    elseif eventType == ccui.TouchEventType.canceled then
        self:clickEndFunc(sender, eventType)
    end
end

--结束监听
function StarryAnniversarySpin:clickEndFunc(sender)
    if self.m_machine then
        local openBonusSkip = self.m_machine.m_openBonusSkip
        if not openBonusSkip:isVisible() then
            return 
        end
        openBonusSkip:skipPanelClickCallBack()
    end
end

return StarryAnniversarySpin