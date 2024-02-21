local CashRushJackpotsBottomNode = class("CashRushJackpotsBottomNode", util_require("views.gameviews.GameBottomNode"))

--获取当前Bet序号
function CashRushJackpotsBottomNode:getBetIndexById(betId)
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
function CashRushJackpotsBottomNode:changeBetCoinNumToUnLock(_index)
    local index = _index
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    local betId = specialBets[index].p_betId
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

function CashRushJackpotsBottomNode:setBigWinLabInfo(_labInfo)
    self.m_bigWinLabInfo = _labInfo
    self.m_bigWinLabInfo.sx = 0.8
    self.m_bigWinLabInfo.sy = 0.8
end

return CashRushJackpotsBottomNode
