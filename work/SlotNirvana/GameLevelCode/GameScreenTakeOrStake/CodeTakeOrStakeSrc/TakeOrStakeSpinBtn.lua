local TakeOrStakeSpinBtn = class("TakeOrStakeSpinBtn", util_require("views.gameviews.SpinBtn"))

--
function TakeOrStakeSpinBtn:btnStopTouchEnd(sender)
    self:printDebug("-------------------btnStopTouchEnd")
    if self.m_btnStopTouch then
        return
    end

    self.m_btnStopTouch = true

    if globalData.slotRunData.gameSpinStage ~= GAME_MODE_ONE_RUN then
        gLobalNoticManager:postNotification("QUICKSTOP_COLLECT")
        return
    end

    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then -- 自动 模式
        self:autoSpinOver()
    end

    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        self:printDebug("触发了 respin 按钮点击  btnStopTouchEnd")

        gLobalNoticManager:postNotification(ViewEventType.RESPIN_TOUCH_SPIN_BTN)
        return
    end

    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN then -- 表明滚动了起来。。
        gLobalNoticManager:postNotification("QUICKSTOP_RANDOMWILD")
        self:normalQuickStop()
    end

end

function TakeOrStakeSpinBtn:resetStopBtnTouch()
    self.m_btnStopTouch = false
end

return TakeOrStakeSpinBtn
