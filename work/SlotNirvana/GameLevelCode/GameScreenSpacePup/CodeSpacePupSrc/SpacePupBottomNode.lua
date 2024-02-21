---
--xcyy
--2018年5月23日
--SpacePupBottomNode.lua

local SpacePupBottomNode = class("SpacePupBottomNode",util_require("views.gameviews.GameBottomNode"))


function SpacePupBottomNode:initUI(...)

    SpacePupBottomNode.super.initUI(self, ...)

end

function SpacePupBottomNode:getCoinsShowTimes(winCoin)
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
        showTime = 1.0
    end
    return showTime
end

function SpacePupBottomNode:playCoinWinEffectUI(_endCoins, _isFlyCoins, callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        local particle = coinBottomEffectNode:findChild("Particle_1")
        local coinsText = coinBottomEffectNode:findChild("m_lb_coins")
        if _isFlyCoins then
            local strCoins = "+" .. util_formatCoins(_endCoins,15)
            coinsText:setString(strCoins)
            coinsText:setVisible(true)
        else
            coinsText:setVisible(false)
        end
        particle:resetSystem()
        coinBottomEffectNode:runCsbAction("actionframe",false,function()
            particle:stopSystem()
            -- coinBottomEffectNode:setVisible(false)
            if callBack ~= nil then
                callBack()
            end
        end)
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

return SpacePupBottomNode
