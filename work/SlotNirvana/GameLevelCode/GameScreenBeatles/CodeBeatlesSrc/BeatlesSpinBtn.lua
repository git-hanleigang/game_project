local BeatlesSpinBtn = class("BeatlesSpinBtn", util_require("views.gameviews.SpinBtn"))

--
function BeatlesSpinBtn:btnStopTouchEnd(sender)
    self:printDebug("-------------------btnStopTouchEnd")
    local name = sender:getName()
    if self.m_btnStopTouch then
        return
    end

    self.m_btnStopTouch = true

    if globalData.slotRunData.gameSpinStage ~= GAME_MODE_ONE_RUN then
        gLobalNoticManager:postNotification("QUICKSTOP_BEATLES")
        return
    else
        gLobalNoticManager:postNotification("QUICKSTOP_BEATLES1")
    end

    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then              -- 自动 模式
        self:autoSpinOver()
    end

    if globalData.slotRunData.currSpinMode == RESPIN_MODE then

        self:printDebug("触发了 respin 按钮点击  btnStopTouchEnd")

        gLobalNoticManager:postNotification(ViewEventType.RESPIN_TOUCH_SPIN_BTN)
        return
    end

    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN  then  -- 表明滚动了起来。。
        self:normalQuickStop()
    end

end

function BeatlesSpinBtn:resetStopBtnTouch()
    self.m_btnStopTouch = false
end

return BeatlesSpinBtn
