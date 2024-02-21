

local PenguinsBoomsSpin = class("PenguinsBoomsSpin", util_require("views.gameviews.SpinBtn"))

function PenguinsBoomsSpin:setPenguinsBoomsMachine(_machine)
    self.m_PenguinsBoomsMachine     = _machine
end
function PenguinsBoomsSpin:onEnter()
    PenguinsBoomsSpin.super.onEnter(self)

    --取消全部监听，只保留按钮的可点击性
    gLobalNoticManager:removeAllObservers(self)
    --只展示一个按钮
    self.m_spinBtn:setVisible(false)
    self.m_autoBtn:setVisible(false)
    self.m_stopBtn:setVisible(true)
end

function PenguinsBoomsSpin:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        self:clickEndFunc(sender)
    elseif eventType == ccui.TouchEventType.canceled then
        self:clickEndFunc(sender, eventType)
    end
end

--结束监听
function PenguinsBoomsSpin:clickEndFunc(sender)
    local sMsg = "[PenguinsBoomsSpin:clickEndFunc] 111"
    util_printLog(sMsg, true)
    if self.m_PenguinsBoomsMachine then
        sMsg = "[PenguinsBoomsSpin:clickEndFunc] 222"
        util_printLog(sMsg, true)
        local openBonusSkip = self.m_PenguinsBoomsMachine.m_skipPanelCsb
        if not openBonusSkip:isVisible() then
            return 
        end
        sMsg = "[PenguinsBoomsSpin:clickEndFunc] 333"
        util_printLog(sMsg, true)
        openBonusSkip:skipPanelClickCallBack()
    end
end

return PenguinsBoomsSpin