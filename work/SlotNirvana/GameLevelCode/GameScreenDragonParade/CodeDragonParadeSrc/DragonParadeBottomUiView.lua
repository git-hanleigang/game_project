
local DragonParadeBottomUiView = class("DragonParadeBottomUiView",util_require("views.gameviews.GameBottomNode"))

--播放粒子
-- function DragonParadeBottomUiView:playCoinWinEffectUI(callBack, numStr)
--     local coinBottomEffectNode = self.coinBottomEffectNode
--     if coinBottomEffectNode ~= nil then
--         coinBottomEffectNode:setVisible(true)
--         coinBottomEffectNode:runCsbAction("actionframe",false,function()
--             -- coinBottomEffectNode:setVisible(false)
--             if callBack ~= nil then
--                 callBack()
--             end
--         end)
--         --改
--         local label = coinBottomEffectNode:findChild("m_lb_coins")
--         label:setString(numStr)

--     else
--         if callBack ~= nil then
--             callBack()
--         end
--     end
-- end


DragonParadeBottomUiView.m_newWinTimes = 0
DragonParadeBottomUiView.m_isUseMachineWinLabel = false

function DragonParadeBottomUiView:getCoinsShowTimes(winCoin)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winCoin / totalBet
    local showTime = 2

    if self.m_newWinTimes ~= 0 then    --设置赢钱时间
        return self.m_newWinTimes
    end

    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2.5
    elseif winRate > 6 then
        showTime = 3
    end

    return showTime
end

function DragonParadeBottomUiView:setNewWinTime(newWinTimes)
    self.m_newWinTimes = newWinTimes
end

-- function DragonParadeBottomUiView:updateWinCount(goldCountStr)
--     if self.m_isUseMachineWinLabel then
--         if self.m_machine.m_respinWinLabel then
--             local _label = self.m_machine.m_respinWinLabel:findChild("m_lb_coins")
--             _label:setString(goldCountStr)
--             if globalData.slotRunData:isMachinePortrait() then
--                 self:updateLabelSize({label = _label}, 383)
--             else
--                 self:updateLabelSize({label = _label}, 428)
--             end

--         end
        
--     else
--         if self.m_machine.m_respinWinLabel then
--             if self.m_machine.m_respinWinLabel:isVisible() then
--                 self.m_machine.m_respinWinLabel:setVisible(false)
--             end
--         end
        
--         DragonParadeBottomUiView.super.updateWinCount(self, goldCountStr)
--     end
    
    
-- end

-- function DragonParadeBottomUiView:setUseMachineWinLabel( isUse )
--     self.m_isUseMachineWinLabel = isUse
-- end

-- function DragonParadeBottomUiView:isShowMachineWinLabel( isShow )
--     if self.m_machine.m_respinWinLabel then
--         self.m_machine.m_respinWinLabel:setVisible(isShow)
--     end
    
-- end

-- function DragonParadeBottomUiView:runWinLabelAnim( isFirst )
--     if self.m_machine.m_respinWinLabel then
--         if isFirst then
--             self.m_machine.m_respinWinLabel:runCsbAction("actionframe")
--         else
--             self.m_machine.m_respinWinLabel:runCsbAction("actionframe2")
--         end
        
--     end
-- end

-- function DragonParadeBottomUiView:checkClearWinLabel()
--     self:updateWinCount("")

--     if self.m_machine.m_respinWinLabel then
--         if self.m_machine.m_respinWinLabel:isVisible() then
--             self.m_machine.m_respinWinLabel:setVisible(false)
--         end
--     end
-- end

function DragonParadeBottomUiView:notifyUpdateWinLabel(winCoin, isUpdateTopUI, isPlayAnim, beiginCoins)
    local updateComplete = function()
        if self.m_isUpdateTopUI == true then
            -- self.m_addWinCount = 0
            self:notifyTopWinCoin()
            self:resetWinLabel()
            self:checkClearWinLabel()
            self.m_spinWinCount = 0
        else
            self:resetWinLabel()
        end
    end
    updateComplete()
    -- self:resetWinLabel()
    self.m_isUpdateTopUI = isUpdateTopUI

    if globalData.slotRunData.lastWinCoin ~= 0 then
        self.m_spinWinCount = globalData.slotRunData.lastWinCoin
    else
        self.m_spinWinCount = winCoin
    end

    if self.m_spinWinCount == 0 then
        return
    end
    -- if self.m_clearHandlerID ~= nil  then
    --     scheduler.unscheduleGlobal(self.m_clearHandlerID)
    --     self.m_clearHandlerID = nil
    -- end

    -- local function updateComplete()
    --     if self.m_isUpdateTopUI == true then
    --         self:notifyTopWinCoin()
    --         self:resetWinLabel()
    --         self:checkClearWinLabel()
    --     else
    --         self:resetWinLabel()
    --     end
    -- end

    if isPlayAnim == false then
        self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount))

        updateComplete()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE, 1)
        return
    end

    local onceWin = false
    if globalData.slotRunData.lastWinCoin == 0 and beiginCoins ~= nil then
        onceWin = true
    end
    local showTime = 1
    if onceWin then --改
        showTime = self:getCoinsShowTimes(math.max(winCoin - beiginCoins, 0))
    else
        showTime = self:getCoinsShowTimes(winCoin)
    end
    -- local showTime = self:getCoinsShowTimes(winCoin)

    local changeTims = self:getChangeJumpTime() -- 特殊逻辑
    showTime = changeTims or showTime

    local coinRiseNum
    if onceWin then --改
        coinRiseNum = math.max(winCoin - beiginCoins, 0) / (showTime * 60) -- 每秒60帧
    else
        coinRiseNum = winCoin / (showTime * 60) -- 每秒60帧
    end
    -- local coinRiseNum = winCoin / (showTime * 60) -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AUTO_SPIN_DELAY_TIME, showTime)

    coinRiseNum = math.floor(coinRiseNum)

    local curSpinCount = 0

    if globalData.slotRunData.lastWinCoin ~= 0 then
        curSpinCount = globalData.slotRunData.lastWinCoin - winCoin
    else
        curSpinCount = 0
    end

    if curSpinCount == 0 then
        if beiginCoins then
            curSpinCount = beiginCoins
        end
    end

    local spinWinCount = self.m_spinWinCount
    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            curSpinCount = curSpinCount + coinRiseNum

            if curSpinCount >= spinWinCount then
                curSpinCount = spinWinCount
                updateComplete()
                self:updateWinCount(util_getFromatMoneyStr(curSpinCount))
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE, 0.5)
            else
                self:updateWinCount(util_getFromatMoneyStr(curSpinCount))
            end
        end
    )
end

return DragonParadeBottomUiView