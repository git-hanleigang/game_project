--
--
-- 游戏中 spin 按钮
local BingoPriatesSpinBtnView = class("BingoPriatesSpinBtnView",util_require("views.gameviews.SpinBtn"))

function BingoPriatesSpinBtnView:btnStopTouchEnd()
    self:printDebug("-------------------btnStopTouchEnd")
    if self.m_btnStopTouch then
        return
    end

    self.m_btnStopTouch = true

    if globalData.slotRunData.gameSpinStage ~= GAME_MODE_ONE_RUN then
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
        self:normalQuickStop()
    end

end

---
--
function BingoPriatesSpinBtnView:btnTouchEnd()
    self:printDebug("-------------------btnTouchEnd")
    self:clearTimingHandler()
    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN then
        return
    end

    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        self:printDebug("触发了 respin 按钮点击  btnTouchEnd")
        gLobalNoticManager:postNotification(ViewEventType.RESPIN_TOUCH_SPIN_BTN)
        return
    end

    if globalData.slotRunData.gameSpinStage == IDLE and globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        -- 处于等待中， 并且free spin 那么提前结束倒计时开始执行spin

        self:printDebug("STR_TOUCH_SPIN_BTN 触发了 free mode")
        gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
        self:printDebug("btnTouchEnd 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
    else
        if self.m_bIsAuto == false then
            self.m_autoSpinChooseNode:hide()
            self:printDebug("STR_TOUCH_SPIN_BTN 触发了 normal")
            gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
            self:printDebug("btnTouchEnd m_bIsAuto == false 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
        end
    end
end

return BingoPriatesSpinBtnView