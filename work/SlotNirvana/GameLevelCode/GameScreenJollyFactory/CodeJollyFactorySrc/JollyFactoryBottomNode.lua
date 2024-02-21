---
--xcyy
--2018年5月23日
--JollyFactoryBottomNode.lua

local JollyFactoryBottomNode = class("JollyFactoryBottomNode",util_require("views.gameviews.GameBottomNode"))


function JollyFactoryBottomNode:getCoinsShowTimes(winCoin)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    -- 大数除法没有浮点数，所以除之前要 * 100
    local _rate = (toLongNumber(winCoin) * 100) / totalBet
    -- LongNumber转number，必须保证不越界
    local winRate = tonumber("" .. _rate) / 100
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

    return showTime
end

return JollyFactoryBottomNode