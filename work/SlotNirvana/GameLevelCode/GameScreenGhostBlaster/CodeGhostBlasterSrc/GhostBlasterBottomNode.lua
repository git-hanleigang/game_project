---
--xcyy
--2018年5月23日
--GhostBlasterBottomNode.lua

local GhostBlasterBottomNode = class("GhostBlasterBottomNode",util_require("views.gameviews.GameBottomNode"))

--获取当前Bet序号
function GhostBlasterBottomNode:getBetIndexById(betId)
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
function GhostBlasterBottomNode:changeBetCoinNumToHight()
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

--[[
    切换至低bet
]]
function GhostBlasterBottomNode:changeBetCoinNumToLow()
    
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    local betId = specialBets[1].p_betId
    if globalData.slotRunData:getCurBetIndex() < self:getBetIndexById(betId) then
        return
    end
    local betData = globalData.slotRunData:getBetDataByIdx(betId, -1)
    globalData.slotRunData.iLastBetIdx = betData.p_betId
    self:postPiggy("sub")
    self:updateBetCoin()
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.AdjustBetSmall)
    end

    self:checkShowBaseTips()
    self:showBetTipsView()
    self:delCardBetChip()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_BET_CHANGE)
    gLobalSendDataManager:getLogSlots():setGameBet()
end

function GhostBlasterBottomNode:getCoinsShowTimes(winCoin)
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
    if self.m_machine.m_isJackpot then
        showTime = 0.5
    end

    return showTime
end

return GhostBlasterBottomNode