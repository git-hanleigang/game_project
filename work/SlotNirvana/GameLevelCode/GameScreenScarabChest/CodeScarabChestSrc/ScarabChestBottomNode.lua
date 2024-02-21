---
--xcyy
--2018年5月23日
--ScarabChestBottomNode.lua

local ScarabChestBottomNode = class("ScarabChestBottomNode",util_require("views.gameviews.GameBottomNode"))

function ScarabChestBottomNode:initUI(...)
    ScarabChestBottomNode.super.initUI(self, ...)
end

-- 修改已创建的收集反馈效果
function ScarabChestBottomNode:changeCoinWinEffectUI(_levelName, _spineName)
    if nil ~= self.coinBottomEffectNode and nil ~= _spineName then
        self.coinBottomEffectNode:removeFromParent()
        self.coinBottomEffectNode = nil
        self.coinBottomEffectNode = util_spineCreate(_spineName,true,true)
        self.coinWinNode:addChild(self.coinBottomEffectNode)
        self.coinBottomEffectNode:setVisible(false)
        -- self.coinBottomEffectNode:setPositionY(-20)
    end
end

function ScarabChestBottomNode:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        util_spinePlay(coinBottomEffectNode, "actionframe", false)
        util_spineEndCallFunc(coinBottomEffectNode, "actionframe", function()
            if type(callBack) == "function" then
                callBack()
            end
        end)
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

function ScarabChestBottomNode:getCoinsShowTimes(winCoin)
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
        showTime = 2.5
    end
    return showTime
end

function ScarabChestBottomNode:notifyUpdateWinLabel(winCoin, isUpdateTopUI, isPlayAnim, beiginCoins)
    if self.m_machine.m_addBotomCoins then
        ScarabChestBottomNode.super.notifyUpdateWinLabel(self, winCoin, isUpdateTopUI, isPlayAnim, beiginCoins)
    end
end

return ScarabChestBottomNode
