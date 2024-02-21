---
--xcyy
--2018年5月23日
--BingoldKoiSpinBtn.lua

local BingoldKoiSpinBtn = class("BingoldKoiSpinBtn",util_require("views.gameviews.SpinBtn"))

function BingoldKoiSpinBtn:btnStopTouchBegan()
    self:printDebug("-------------------btnStopTouchBegan")
    local oldMode = globalData.slotRunData.currSpinMode
    BingoldKoiSpinBtn.super.btnStopTouchBegan(self)
    globalData.slotRunData.currSpinMode = oldMode
end

function BingoldKoiSpinBtn:btnStopTouchEnd()
    self:printDebug("-------------------btnStopTouchEnd")
    if self.m_btnStopTouch then
        return
    end

    self.m_btnStopTouch = true
    if globalData.slotRunData.gameSpinStage ~= GAME_MODE_ONE_RUN then
        return
    end

    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then -- 自动 模式
        -- self:autoSpinOver()
        globalData.slotRunData.currSpinMode = NORMAL_SPIN_MODE
        return
    end

    gLobalNoticManager:postNotification(ViewEventType.RESPIN_TOUCH_SPIN_BTN)
end

return BingoldKoiSpinBtn
