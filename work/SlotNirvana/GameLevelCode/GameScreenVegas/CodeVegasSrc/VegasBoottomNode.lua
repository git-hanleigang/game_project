---
--xcyy
--2018年5月23日
--VegasBoottomNode.lua

local VegasBoottomNode = class("VegasBoottomNode",util_require("views.gameviews.GameBottomNode"))


function VegasBoottomNode:notifyUpdateWinLabel(winCoin,isUpdateTopUI,isPlayAnim)

    self:resetWinLabel()
    self.m_isUpdateTopUI = isUpdateTopUI

    if globalData.slotRunData.lastWinCoin ~= 0 then
        self.m_spinWinCount = globalData.slotRunData.lastWinCoin
    else
        self.m_spinWinCount = winCoin
    end

    if self.m_spinWinCount == 0 then
        return
    end

    local function updateComplete()
        if self.m_isUpdateTopUI == true then
            self:notifyTopWinCoin()
            self:checkClearWinLabel()
        end

        self:resetWinLabel()
    end



    if isPlayAnim == false then

        self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount))

        updateComplete()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE,1)
        return
    end

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winCoin / totalBet
    local showTime = 2
    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2
    elseif winRate > 6 then
        showTime = 2.5
    end
    local coinRiseNum =  winCoin / (showTime * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)


    coinRiseNum = math.floor(coinRiseNum )

    local curSpinCount = 0

    if globalData.slotRunData.lastWinCoin ~= 0 then
       curSpinCount = globalData.slotRunData.lastWinCoin - winCoin
    else
        curSpinCount = 0
    end


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        curSpinCount = curSpinCount + coinRiseNum

        if curSpinCount >= self.m_spinWinCount then
            curSpinCount = self.m_spinWinCount
            updateComplete()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE,0.5)
        end
        self:updateWinCount(util_getFromatMoneyStr(curSpinCount))
    end)

end


return VegasBoottomNode