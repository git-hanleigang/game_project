---
--xcyy
--2018年5月23日
--BunnysLockSpinBtn.lua

local BunnysLockSpinBtn = class("BunnysLockSpinBtn",util_require("views.gameviews.SpinBtn"))

function BunnysLockSpinBtn:btnStopTouchBegan()
    self:printDebug("-------------------btnStopTouchBegan")
    globalData.slotRunData.m_autoNum = 0
    globalData.slotRunData.m_isAutoSpinAction = false
end

function BunnysLockSpinBtn:btnStopTouchEnd()
    self:printDebug("-------------------btnStopTouchEnd")
    if self.m_btnStopTouch then
        return
    end

    if globalData.slotRunData.gameSpinStage ~= GAME_MODE_ONE_RUN then
        return
    end

    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then -- 自动 模式
        -- self:autoSpinOver()
        globalData.slotRunData.currSpinMode = NORMAL_SPIN_MODE
        return
    end

    self.m_btnStopTouch = true

    gLobalNoticManager:postNotification(ViewEventType.RESPIN_TOUCH_SPIN_BTN)
end

return BunnysLockSpinBtn
