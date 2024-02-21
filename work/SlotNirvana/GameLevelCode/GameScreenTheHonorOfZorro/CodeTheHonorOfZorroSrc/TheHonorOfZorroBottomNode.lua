---
--xcyy
--2018年5月23日
--TheHonorOfZorroBottomNode.lua

local TheHonorOfZorroBottomNode = class("TheHonorOfZorroBottomNode",util_require("views.gameviews.GameBottomNode"))

--获取当前Bet序号
function TheHonorOfZorroBottomNode:getBetIndexById(betId)
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
function TheHonorOfZorroBottomNode:changeBetCoinNumToHight()
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
function TheHonorOfZorroBottomNode:changeBetCoinNumToLow()
    
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

function TheHonorOfZorroBottomNode:playCoinWinEffectUI(winCoins,callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)

        local m_lb_coins = coinBottomEffectNode:findChild("m_lb_coins")
        if m_lb_coins then
            m_lb_coins:setString("+"..util_formatCoins(winCoins,50))
            self:updateLabelSize({label=m_lb_coins,sx=1,sy=1},425)
        end

        coinBottomEffectNode:runCsbAction("actionframe",false,function()
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

return TheHonorOfZorroBottomNode