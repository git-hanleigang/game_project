--[[
    跳过按钮
]]
local CherryBountyBottomSkipBtn = class("CherryBountyBottomSkipBtn",util_require("views.gameviews.SpinBtn"))

function CherryBountyBottomSkipBtn:onEnter()
    CherryBountyBottomSkipBtn.super.onEnter(self)

    --取消全部监听，只保留spin按钮的可点击性
    gLobalNoticManager:removeAllObservers(self)
    --只展示指定按钮
    self.m_spinBtn:setVisible(false)
    self.m_autoBtn:setVisible(false)
    self.m_stopBtn:setVisible(true)
end

function CherryBountyBottomSkipBtn:setCherryBountyMachine(_machine)
    self.m_CherryBountyMachine = _machine
end
--重写-点击回调
function CherryBountyBottomSkipBtn:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        self:clickEndFunc(sender)
    elseif eventType == ccui.TouchEventType.canceled then
        self:clickEndFunc(sender, eventType)
    end
end
--重写-点击回调
function CherryBountyBottomSkipBtn:clickEndFunc(sender)
    if self.m_CherryBountyMachine then
        local skipLayer = self.m_CherryBountyMachine.m_skipLayer
        skipLayer:clickSkipLayer()
    end
end

return CherryBountyBottomSkipBtn