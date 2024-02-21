---
--xcyy
--2018年5月23日
--CleosCoffersBottomNode.lua

local CleosCoffersBottomNode = class("CleosCoffersBottomNode",util_require("views.gameviews.GameBottomNode"))

function CleosCoffersBottomNode:initUI(...)
    CleosCoffersBottomNode.super.initUI(self, ...)

    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1
        self.m_skipBtn = util_createView("CodeCleosCoffersBetSrc.CleosCoffersSkipSpinBtn")
        spinParent:addChild(self.m_skipBtn, order)
        self.m_skipBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_skipBtn:setCleosCoffersMachine(self.m_machine)
        self:setSkipBtnVisible(false)
    end
end

function CleosCoffersBottomNode:setSkipBtnVisible(_vis)
    if nil ~= self.m_skipBtn then
        self.m_skipBtn:setVisible(_vis)
    end
end

function CleosCoffersBottomNode:postPiggy(type, lastBetIdx, _curBetValue)
    if type == "change" then
        if globalData.slotRunData:checkCurBetIsMaxbet() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "max"})
        else
            local curBetValue = _curBetValue
            local lastBetValue = globalData.slotRunData:getCurBetValueByIndex(lastBetIdx) * globalData.slotRunData:getCurBetMultiply()
            if lastBetValue > curBetValue then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "sub"})
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "add"})
            end
        end
    else
        CleosCoffersBottomNode.super.postPiggy(self,type, lastBetIdx, _curBetValue)
    end
end

--改变筹码
function CleosCoffersBottomNode:changeBetCoinNum(_betId,_curBetValue)
    local lastBetIdx = globalData.slotRunData.iLastBetIdx
    local betData = globalData.slotRunData:getBetDataByIdx(_betId , 0)
    globalData.slotRunData.iLastBetIdx = betData.p_betId
    self:postPiggy("change", lastBetIdx, _curBetValue)
    self:updateBetCoin()
end

-- 修改已创建的收集反馈效果
function CleosCoffersBottomNode:changeCoinWinEffectUI(_levelName, _spineName)
    if nil ~= self.coinBottomEffectNode and nil ~= _spineName then
        self.coinBottomEffectNode:removeFromParent()
        self.coinBottomEffectNode = nil
        self.coinBottomEffectNode = util_spineCreate(_spineName,true,true)
        self.coinWinNode:addChild(self.coinBottomEffectNode)
        self.coinBottomEffectNode:setVisible(false)
        self.coinBottomEffectNode:setPositionY(-20)
    end
end

function CleosCoffersBottomNode:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        util_spinePlay(coinBottomEffectNode, "actionframe", false)
        util_spineEndCallFunc(coinBottomEffectNode, "actionframe", function()
            coinBottomEffectNode:setVisible(false)
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

function CleosCoffersBottomNode:getCoinsShowTimes(winCoin)
    local showTime = CleosCoffersBottomNode.super.getCoinsShowTimes(winCoin)
    if self.m_machine.m_collectBonus then
        showTime = 1.0
    end
    return showTime
end

return CleosCoffersBottomNode
