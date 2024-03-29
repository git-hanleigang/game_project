---
--xcyy
--2018年5月23日
--ChameleonRichesBottomNode.lua

local ChameleonRichesBottomNode = class("ChameleonRichesBottomNode",util_require("views.gameviews.GameBottomNode"))

---
-- wincoin 是本次赢取了多少钱
-- @param 第三个参数，用来处理显示赢钱时 不需要播放数字变化动画
--
function ChameleonRichesBottomNode:notifyUpdateWinLabel(winCoin, isUpdateTopUI, isPlayAnim, beiginCoins)
    local updateComplete = function()
        if self.m_isUpdateTopUI == true then
            -- self.m_addWinCount = 0
            self:notifyTopWinCoin()
            self:resetWinLabel()
            self:checkClearWinLabel()
            
        else
            self:resetWinLabel()
        end
    end
    
    -- self:resetWinLabel()
    self.m_isUpdateTopUI = isUpdateTopUI

    if globalData.slotRunData.lastWinCoin ~= 0 then
        self.m_spinWinCount = globalData.slotRunData.lastWinCoin
    else
        self.m_spinWinCount = winCoin
    end

    if self.m_spinWinCount == 0 then
        return
    end

    if isPlayAnim == false then
        self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount))

        updateComplete()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE, 1)
        return
    end

    local showTime = self:getCoinsShowTimes(winCoin)

    local changeTims = self:getChangeJumpTime() -- 特殊逻辑
    showTime = changeTims or showTime

    local coinRiseNum = winCoin / (showTime * 60) -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AUTO_SPIN_DELAY_TIME, showTime)

    coinRiseNum = math.floor(coinRiseNum)

    local curSpinCount = 0

    if globalData.slotRunData.lastWinCoin ~= 0 then
        curSpinCount = globalData.slotRunData.lastWinCoin - winCoin
    else
        curSpinCount = 0
    end

    if curSpinCount == 0 then
        if beiginCoins then
            curSpinCount = beiginCoins
        end
    end

    local spinWinCount = self.m_spinWinCount

    if self.m_updateCoinHandlerID then
        return
    end

    updateComplete()

    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            curSpinCount = curSpinCount + coinRiseNum

            if curSpinCount >= self.m_spinWinCount then
                curSpinCount = self.m_spinWinCount
                updateComplete()
                self.m_spinWinCount = 0
                self:updateWinCount(util_getFromatMoneyStr(curSpinCount))
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE, 0.5)
            else
                self:updateWinCount(util_getFromatMoneyStr(curSpinCount))
            end
        end
    )
end

return ChameleonRichesBottomNode