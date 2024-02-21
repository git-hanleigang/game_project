---
--xcyy
--2018年5月23日
--MiningManiaBottomNode.lua

local MiningManiaBottomNode = class("MiningManiaBottomNode",util_require("views.gameviews.GameBottomNode"))


function MiningManiaBottomNode:initUI(...)

    MiningManiaBottomNode.super.initUI(self, ...)

end

function MiningManiaBottomNode:getCoinsShowTimes(winCoin)
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
        showTime = 0.5
    end
    return showTime
end

return MiningManiaBottomNode
