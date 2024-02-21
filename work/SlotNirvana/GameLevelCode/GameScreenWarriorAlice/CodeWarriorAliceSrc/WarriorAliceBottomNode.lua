---
--xcyy
--2018年5月23日
--WarriorAliceBottomNode.lua

local WarriorAliceBottomNode = class("WarriorAliceBottomNode",util_require("views.gameviews.GameBottomNode"))

function WarriorAliceBottomNode:getCoinsShowTimes(winCoin)
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

    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        showTime = 0.5
    end

    return showTime
end

return WarriorAliceBottomNode