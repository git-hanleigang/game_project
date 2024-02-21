local TrainYourDragonSpin = class("TrainYourDragonSpin",util_require("views.gameviews.SpinBtn"))

function TrainYourDragonSpin:btnStopTouchEnd()
    if self.m_btnStopTouch then
        return
    end

    self.m_btnStopTouch = true

    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.RESPIN_TOUCH_SPIN_BTN)
        return
    end

    if globalData.slotRunData.gameSpinStage ~= GAME_MODE_ONE_RUN then
        return
    end

    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
        self:autoSpinOver()
    end

    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN  then
        self:normalQuickStop()
    end

end

return TrainYourDragonSpin