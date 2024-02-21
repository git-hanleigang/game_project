
local PenguinsBoomsGameBottomNode = class("PenguinsBoomsGameBottomNode",util_require("views.gameviews.GameBottomNode"))

function PenguinsBoomsGameBottomNode:initUI(...)
    PenguinsBoomsGameBottomNode.super.initUI(self, ...)

    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1
        self.m_skipBonusBtn = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsSpin")
        spinParent:addChild(self.m_skipBonusBtn, order)
        self.m_skipBonusBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_skipBonusBtn:setPenguinsBoomsMachine(self.m_machine)
        self:setSkipBonusBtnVisible(false)
    end
end

function PenguinsBoomsGameBottomNode:setSkipBonusBtnVisible(_vis)
    if nil ~= self.m_skipBonusBtn then
        self.m_skipBonusBtn:setVisible(_vis)
    end
end

--获取当前Bet序号
function PenguinsBoomsGameBottomNode:getBetIndexById(betId)
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
    根据level切换bet
]]
function PenguinsBoomsGameBottomNode:changeBetCoinNumByLevels(betLevel)
    if betLevel == self.m_machine.m_iBetLevel then
        return
    end
    if betLevel == 0 then
        self:changeBetCoinNumToLow()
        return
    end

    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    local betId
    if specialBets[betLevel] then
        betId = specialBets[betLevel].p_betId
    end

    if not betId then
        return
    end

    globalData.slotRunData.iLastBetIdx = betId
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
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_BET_CHANGE)
    gLobalSendDataManager:getLogSlots():setGameBet()

    if globalData.slotRunData:getCurBetIndex() >= self:getBetIndexById(betId) then
        self:postPiggy("add", betId)
        self:addCardBetChip()
    else
        self:postPiggy("sub")
        
        self:delCardBetChip()
    end
    

    
end

--[[
    切换至低bet
]]
function PenguinsBoomsGameBottomNode:changeBetCoinNumToLow()
    
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    local betId = specialBets[1].p_betId
    if globalData.slotRunData:getCurBetIndex() < self:getBetIndexById(betId) then
        return
    end
    local betData = globalData.slotRunData:getBetDataByIdx(betId, -1)
    if not betData then
        self:buglyPrintMsg(betId)
    end
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

function PenguinsBoomsGameBottomNode:buglyPrintMsg(_betId)
    local sMsg = string.format("[PenguinsBoomsGameBottomNode:buglyPrintMsg] betId = %s",tostring(_betId) or "nil")
    util_printLog(sMsg, true)
    local machineData = globalData.slotRunData.machineData
    if not machineData then
        util_printLog("[PenguinsBoomsGameBottomNode:buglyPrintMsg] machineData is nil", true)
        return
    end
    local machineCurBetList = machineData:getMachineCurBetList() or {}
    for i,_betData in ipairs(machineCurBetList) do
        local sBetId = tostring(_betData.p_betId) or "nil"
        util_printLog(string.format("[PenguinsBoomsGameBottomNode:buglyPrintMsg] betListId = %s",sBetId), true)
    end
end
return PenguinsBoomsGameBottomNode