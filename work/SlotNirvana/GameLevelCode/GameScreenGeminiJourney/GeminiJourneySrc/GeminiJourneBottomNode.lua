
local GeminiJourneBottomNode = class("GeminiJourneBottomNode", util_require("views.gameviews.GameBottomNode"))

function GeminiJourneBottomNode:initUI(...)
    GeminiJourneBottomNode.super.initUI(self, ...)

    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1
        self.m_skipRespinBtn = util_createView("GeminiJourneySrc.GeminiJourneySkipSpinBtn")
        spinParent:addChild(self.m_skipRespinBtn, order)
        self.m_skipRespinBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_skipRespinBtn:setGeminiJourneMachine(self.m_machine)
        self:setSkipRespinBtnVisible(false)
    end
end

function GeminiJourneBottomNode:setSkipRespinBtnVisible(_vis)
    if nil ~= self.m_skipRespinBtn then
        self.m_skipRespinBtn:setVisible(_vis)
    end
end

--获取当前Bet序号
function GeminiJourneBottomNode:getBetIndexById(betId)
    local machineCurBetList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #machineCurBetList do
        local betData = machineCurBetList[i]
        if betData.p_betId == betId then
            return i
        end
    end

    return 1
end

--[[
    切换至高bet
]]
function GeminiJourneBottomNode:changeBetCoinNumToUnLock(_index)
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    local betId = specialBets[1].p_betId
    if globalData.slotRunData:getCurBetIndex() >= self:getBetIndexById(betId) then
        return
    end
    globalData.slotRunData.iLastBetIdx = betId
    self:postPiggy("add", betId)
    self:updateBetCoin()
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.AdjustBetBig)
    end
    globalNoviceGuideManager:removeNewPop(GUIDE_LEVEL_POP.MaxBet)
    if globalNoviceGuideManager.guideBubbleAddBetPopup then
        globalNoviceGuideManager.guideBubbleAddBetPopup = nil
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect("guideBubbleAddBetClick", false)
        end
    end

    self:checkShowBaseTips()
    self:showBetTipsView()
    self:addCardBetChip()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_BET_CHANGE)
    gLobalSendDataManager:getLogSlots():setGameBet()
end

-- 修改已创建的收集反馈效果
function GeminiJourneBottomNode:changeCoinWinEffectUI(_levelName, _spineName)
    if nil ~= self.coinBottomEffectNode and nil ~= _spineName then
        self.coinBottomEffectNode:removeFromParent()
        self.coinBottomEffectNode = nil
        self.coinBottomEffectNode = util_spineCreate(_spineName,true,true)
        self.coinWinNode:addChild(self.coinBottomEffectNode)
        self.coinBottomEffectNode:setVisible(false)
        self.coinBottomEffectNode:setPositionY(-20)
    end
end

function GeminiJourneBottomNode:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        util_spinePlay(coinBottomEffectNode, "actionframe_totalwin", false)
        util_spineEndCallFunc(coinBottomEffectNode, "actionframe_totalwin", function()
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

function GeminiJourneBottomNode:getCoinsShowTimes(winCoin)
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
        showTime = 0.3
    end
    return showTime
end

return GeminiJourneBottomNode
