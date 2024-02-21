local Christmas2021SpinBtn = class("Christmas2021SpinBtn", util_require("views.gameviews.SpinBtn"))
Christmas2021SpinBtn.m_isShowQuickStopBtn = false -- 是否正在显示快停按钮
--
function Christmas2021SpinBtn:btnStopTouchEnd(sender)
    self:printDebug("-------------------btnStopTouchEnd")
    local name = sender:getName()
    if self.m_btnStopTouch then
        return
    end

    self.m_btnStopTouch = true

    if globalData.slotRunData.gameSpinStage ~= GAME_MODE_ONE_RUN then
        -- gLobalNoticManager:postNotification("QUICKSTOP_BEATLES")
        return
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
        -- if self.m_isShowQuickStopBtn then
        --     gLobalNoticManager:postNotification("QUICKSTOP_BEATLES")
        -- else
            self:normalQuickStop()
        -- end
    end

end

function Christmas2021SpinBtn:isShowQuickStopBtn(touch)
    self.m_isShowQuickStopBtn = touch
end

function Christmas2021SpinBtn:resetStopBtnTouch()
    self.m_btnStopTouch = false
end

return Christmas2021SpinBtn
