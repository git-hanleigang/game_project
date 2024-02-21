
local WildJurassicGameBottomNode = class("WildJurassicGameBottomNode", util_require("views.gameviews.GameBottomNode"))

function WildJurassicGameBottomNode:getCoinsShowTimes(winCoin)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winCoin / totalBet
    local showTime = 1.2
    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.2
    elseif winRate > 3 and winRate <= 6 then
        showTime = 1.2
    elseif winRate > 6 then
        showTime = 1.2
    end

    return showTime
end

return  WildJurassicGameBottomNode