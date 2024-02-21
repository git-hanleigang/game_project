---
--xcyy
--2018年5月23日
--LuxuryDiamondBoottomUiView.lua

local LuxuryDiamondBoottomUiView = class("LuxuryDiamondBoottomUiView",util_require("views.gameviews.GameBottomNode"))
local GameBetBarControl = util_require("views.gameviews.GameBetBarControl"):getInstance()

-- -- 增加堵住筹码
-- function LuxuryDiamondBoottomUiView:addBetCoinNum()
--     local lastBetIdx = globalData.slotRunData.iLastBetIdx
--     local betData = globalData.slotRunData:getBetDataByIdx(globalData.slotRunData.iLastBetIdx , 1)
--     local coins = self:getBetLevelCoins(self.m_machine.m_iBetLevel + 1)
--     if globalData.slotRunData.isDeluexeClub == true or (coins > betData.p_totalBetValue and not globalData.slotRunData:checkCurBetIsMaxbet() ) then
--         globalData.slotRunData.iLastBetIdx = betData.p_betId
--         self:postPiggy("add", lastBetIdx)
--         self:updateBetCoin()
    
--         globalNoviceGuideManager:removeNewPop(GUIDE_LEVEL_POP.MaxBet)
--         if globalNoviceGuideManager.guideBubbleAddBetPopup then
--             globalNoviceGuideManager.guideBubbleAddBetPopup = nil
--         end
--     else
--         local betId = self:getBetLevelBetId(self.m_machine.m_iBetLevel)
--         self:changeBetCoinNum(betId)
--     end
-- end
-- ---
-- -- 减少赌注筹码
-- function LuxuryDiamondBoottomUiView:subBetCoinNum()
--     local betData = globalData.slotRunData:getBetDataByIdx(globalData.slotRunData.iLastBetIdx , -1)
--     local maxData = globalData.slotRunData:getMaxBetData()
--     local coins = self:getBetLevelCoins(self.m_machine.m_iBetLevel)
--     if globalData.slotRunData.isDeluexeClub == true or (coins <= betData.p_totalBetValue and maxData.p_betId ~= betData.p_betId) then
--         globalData.slotRunData.iLastBetIdx = betData.p_betId
--         self:postPiggy("sub")
--         self:updateBetCoin()
--     else
--         local curBetId = maxData.p_betId
--         if self.m_machine.m_iBetLevel < 4 then
--             local betId = self:getBetLevelBetId(self.m_machine.m_iBetLevel + 1)
--             local nextBetData = globalData.slotRunData:getBetDataByIdx(betId , -1)
--             curBetId = nextBetData.p_betId
--         end
--         self:changeBetCoinNum(curBetId)
--     end
-- end

-- function LuxuryDiamondBoottomUiView:getBetLevelCoins(index)
--     local betList = globalData.slotRunData.machineData:getMachineCurBetList() or {}
--     local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets or {}
--     local betValue = nil
--     if index == 0 then
--         betValue = betList[1].p_totalBetValue
--     elseif index == 5 then  --最大bet值为4,+1后就是5,所以返回列表的最大值
--         betValue = betList[#betList].p_totalBetValue
--     else
--         betValue = specialBets[index].p_totalBetValue
--     end
--     return betValue
-- end

-- function LuxuryDiamondBoottomUiView:getBetLevelBetId(index)
--     local betList = globalData.slotRunData.machineData:getMachineCurBetList() or {}
--     local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets or {}
--     local betValue = nil
--     if index == 0 then
--         betValue = betList[1].p_betId
--     else
--         betValue = specialBets[index].p_betId
--     end
--     return betValue
-- end

function LuxuryDiamondBoottomUiView:postPiggy(type, lastBetIdx, _curBetValue)
    if type == 'add' then
        if globalData.slotRunData:checkCurBetIsMaxbet() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "max"})
        elseif self:checkBetIsMaxbet(lastBetIdx) then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "sub"})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "add"})
        end
    elseif type == 'max' then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "max"})
    elseif type == 'sub' then
        if globalData.slotRunData:checkCurBetIsMaxbet() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "max"})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "sub"})
        end
    elseif type == 'change' then
        if globalData.slotRunData:checkCurBetIsMaxbet() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "max"})
        else
            local curBetValue = _curBetValue
            local lastBetValue = globalData.slotRunData:getCurBetValueByIndex(lastBetIdx) * self.m_machine.p_curBetMultiply
            if lastBetValue > curBetValue then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "sub"})
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "add"})
            end
        end
    end
end

--改变筹码
function LuxuryDiamondBoottomUiView:changeBetCoinNum(betId,_curBetValue, isMustChange, _isSkipSound)
    local lastBetIdx = globalData.slotRunData.iLastBetIdx
    if betId == lastBetIdx and not isMustChange then
        return
    end
    local betData = globalData.slotRunData:getBetDataByIdx(betId , 0)
    globalData.slotRunData.iLastBetIdx = betData.p_betId
    self:postPiggy("change", lastBetIdx, _curBetValue)
    self:updateBetCoin(nil, _isSkipSound)
end


--------------------  更新bet 信息   -------------------------
function LuxuryDiamondBoottomUiView:updateBetCoin(isLevelUp, isSkipSound)
    -- local betIdex =  globalTestDataManager:getBetIndex()

    -- if betIdex then
    --     globalData.slotRunData.iLastBetIdx = betIdex
    -- end

    if globalData.slotRunData.iLastBetIdx ~= nil then
        if isLevelUp then
        else
            if globalData.slotRunData:checkCurBetIsMaxbet() then --最大BET
                if self.m_btn_MaxBet then
                    -- self.m_btn_MaxBet:setBright(false)
                    -- self.m_btn_MaxBet:setTouchEnabled(false)
                    self.m_btn_MaxBet:setVisible(false)
                end
                if self.m_btn_MaxBet1 then
                    self.m_btn_MaxBet1:setVisible(true)
                end
                self:runAnim(
                    "bet_guang",
                    false,
                    function()
                        self:runAnim("idle", true)
                        self:updateTasksBar()
                    end
                )

                --特效
                if self.m_maxBetEff then
                    self.m_maxBetEff:removeFromParent()
                    self.m_maxBetEff = nil
                end
            else
                if self.m_btn_MaxBet then
                    -- self.m_btn_MaxBet:setBright(true)
                    -- self.m_btn_MaxBet:setTouchEnabled(true)
                    self.m_btn_MaxBet:setVisible(true)
                end
                if self.m_btn_MaxBet1 then
                    self.m_btn_MaxBet1:setVisible(false)
                end
            end
        end
        local betValue = globalData.slotRunData:getCurTotalBet() * self.m_machine.p_curBetMultiply
        globalData.nowBetValue = betValue
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BET_CHANGE, {p_isLevelUp = isLevelUp})

        GameBetBarControl:changeBet(betValue)
        self:updateTotalBet(betValue)
    end
    if DEBUG == 2 then
        local function creatBmt(name)
            local bmtLabel = ccui.TextBMFont:create()
            bmtLabel:setFntFile("Common/font_white.fnt")
            bmtLabel:setString("")
            bmtLabel:setName(name)
            bmtLabel:setScale(0.5)
            bmtLabel:setAnchorPoint(1, 0.5)
            return bmtLabel
        end
        if not self.m_betIndexLabel then
            self.m_betIndexLabel = creatBmt("betIndexLabel")
            self.m_betIndexLabel:setPosition(-250, 100)
            self:addChild(self.m_betIndexLabel, 1)
        end
        self.m_betIndexLabel:setString("betIndex=" .. globalData.slotRunData:getCurBetIndex())
    end
end

return LuxuryDiamondBoottomUiView