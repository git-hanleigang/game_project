---
--xcyy
--2018年5月23日
--BankCrazeBottomNode.lua

local BankCrazeBottomNode = class("BankCrazeBottomNode",util_require("views.gameviews.GameBottomNode"))

function BankCrazeBottomNode:initUI(...)
    BankCrazeBottomNode.super.initUI(self, ...)
end

function BankCrazeBottomNode:getCoinsShowTimes(winCoin)
    local showTime = BankCrazeBottomNode.super.getCoinsShowTimes(winCoin)
    if self.m_machine.collectJackpotBonus then
        showTime = 1.5
    elseif self.m_machine.collectBonus then
        showTime = 0.1
    end
    return showTime
end

function BankCrazeBottomNode:playBigWinLabAnim(_params)
    if not self.m_bigWinLabCsb then
        return 
    end
    --[[
        _params = {
            beginCoins = 0,
            overCoins  = 100,
            jumpTime   = 3,
            actType    = 1,             --(二选一)通用的几种放大缩小表现
            animName   = "actionframe", --(二选一)工程内的时间线

            fnActOver  = function,
            fnJumpOver = function,
        }
    ]]
    if _params.isPlayCoins then
        local overCoins = _params.overCoins or 100
        _params.fnActOver = _params.fnActOver or function() end
        self:stopUpDateBigWinLab()
        self:setBigWinLabCoins(overCoins)
        --文本放大缩小 分为通用动作或时间线
        self:playBigWinLabActionByType(_params)
        self:playBigWinLabTimeLineByName(_params)
    else
        BankCrazeBottomNode.super.playBigWinLabAnim(self, _params)
    end
end

return BankCrazeBottomNode
