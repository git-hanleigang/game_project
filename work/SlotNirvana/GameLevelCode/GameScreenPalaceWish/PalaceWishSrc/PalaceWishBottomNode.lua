---
--xcyy
--2018年5月23日
--PalaceWishBottomNode.lua

local PalaceWishBottomNode = class("PalaceWishBottomNode",util_require("views.gameviews.GameBottomNode"))

--获取当前Bet序号
function PalaceWishBottomNode:getBetIndexById(betId)
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
function PalaceWishBottomNode:changeBetCoinNumToHight()
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

--播放粒子
function PalaceWishBottomNode:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        coinBottomEffectNode:runCsbAction("actionframe",false,function()
            -- coinBottomEffectNode:setVisible(false)
            if callBack ~= nil then
                callBack()
            end
        end)
        --改
        local p1 = coinBottomEffectNode:findChild("Particle_1")
        local p2 = coinBottomEffectNode:findChild("Particle_2")
        if p1 then
            p1:resetSystem()
        end
        if p2 then
            p2:resetSystem()
        end
        --改
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

return PalaceWishBottomNode