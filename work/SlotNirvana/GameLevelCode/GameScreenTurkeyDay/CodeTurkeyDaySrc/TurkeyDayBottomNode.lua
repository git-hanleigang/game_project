---
--xcyy
--2018年5月23日
--TurkeyDayBottomNode.lua

local TurkeyDayBottomNode = class("TurkeyDayBottomNode",util_require("views.gameviews.GameBottomNode"))

function TurkeyDayBottomNode:initUI(...)
    TurkeyDayBottomNode.super.initUI(self, ...)

    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1
        self.m_skipBtn = util_createView("CodeTurkeyDaySrc.TurkeyDaySkipSpinBtn")
        spinParent:addChild(self.m_skipBtn, order)
        self.m_skipBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_skipBtn:setGeminiJourneMachine(self.m_machine)
        self:setSkipBtnVisible(false)
    end
end

function TurkeyDayBottomNode:setSkipBtnVisible(_vis)
    if nil ~= self.m_skipBtn then
        self.m_skipBtn:setVisible(_vis)
    end
end

function TurkeyDayBottomNode:getCoinsShowTimes(winCoin)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winCoin / totalBet
    local showTime = 2
    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2.5
    elseif winRate > 6 then
        showTime = 3
    end
    if self.m_machine.collectBonus then
        showTime = 1.5
    end
    return showTime
end

return TurkeyDayBottomNode
