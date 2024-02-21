local GhostCaptainBoottomUIView = class("GhostCaptainBoottomUIView",util_require("views.gameviews.GameBottomNode"))

function GhostCaptainBoottomUIView:postPiggy(type, lastBetIdx, _curBetValue)
    if type == "change" then
        if globalData.slotRunData:checkCurBetIsMaxbet() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "max"})
        else
            local curBetValue = _curBetValue
            local lastBetValue = globalData.slotRunData:getCurBetValueByIndex(lastBetIdx) * globalData.slotRunData.m_curBetMultiply
            if lastBetValue > curBetValue then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "sub"})
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "add"})
            end
        end
    else
        GhostCaptainBoottomUIView.super.postPiggy(self,type, lastBetIdx, _curBetValue)
    end
end

--改变筹码
function GhostCaptainBoottomUIView:changeBetCoinNum(_betId,_curBetValue)
    local lastBetIdx = globalData.slotRunData.iLastBetIdx
    local betData = globalData.slotRunData:getBetDataByIdx(_betId , 0)
    globalData.slotRunData.iLastBetIdx = betData.p_betId
    self:postPiggy("change", lastBetIdx, _curBetValue)
    self:updateBetCoin()
end

function GhostCaptainBoottomUIView:getCoinsShowTimes(winCoin)
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

-- 修改已创建的收集反馈效果
function GhostCaptainBoottomUIView:changeCoinWinEffectUI(_levelName, _csbName)
    if nil ~= self.coinBottomEffectNode and nil ~= _csbName then
        self.coinBottomEffectNode:removeFromParent()
        self.coinBottomEffectNode = nil
        self.coinBottomEffectNode = util_spineCreate(_csbName, true, true)
        self.coinWinNode:addChild(self.coinBottomEffectNode, 99)
        self.coinBottomEffectNode:setVisible(false)
    end
end

function GhostCaptainBoottomUIView:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        util_spinePlay(coinBottomEffectNode, "actionframe", false)
        util_spineEndCallFunc(coinBottomEffectNode, "actionframe", function ()
            coinBottomEffectNode:setVisible(false)
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

function GhostCaptainBoottomUIView:changeBigWinLabUi(_csbPath)
    if not self.coinWinNode then
        return
    end
    if not CCFileUtils:sharedFileUtils():isFileExist(_csbPath) then
        return
    end
    --资源创建
    if self.m_bigWinLabCsb ~= nil then
        self.m_bigWinLabCsb:removeFromParent()
        self.m_bigWinLabCsb = nil
    end
    self.m_bigWinLabCsb = util_createAnimation(_csbPath)
    self.coinWinNode:addChild(self.m_bigWinLabCsb, 100)
    self.m_bigWinLabCsb:setVisible(false)
    --初始化适配参数
    local labCoins = self.m_bigWinLabCsb:findChild("m_lb_coins")
    local labInfo = {}
    labInfo.label = labCoins
    local labSize = labCoins:getContentSize()
    labInfo.width = labSize.width
    labInfo.sx = labCoins:getScaleX()
    labInfo.sy = labCoins:getScaleY()
    self:setBigWinLabInfo(labInfo)
end

return GhostCaptainBoottomUIView