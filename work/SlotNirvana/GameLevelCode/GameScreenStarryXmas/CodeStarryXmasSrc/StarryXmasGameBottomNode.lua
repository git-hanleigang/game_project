--
-- 气泡下UI
-- Author:{author}
-- Date: 2018-12-22 16:34:48

local GameBottomNode = require "views.gameviews.GameBottomNode"

local StarryXmasGameBottomNode = class("StarryXmasGameBottomNode", util_require("views.gameviews.GameBottomNode"))
StarryXmasGameBottomNode.isAddLineWin = true

function StarryXmasGameBottomNode:setMachine(machine )
    self.m_machine = machine
end

function StarryXmasGameBottomNode:setIsAddLineWin(isAdd)
    self.isAddLineWin = isAdd
end

---
-- wincoin 是本次赢取了多少钱
-- @param 第三个参数，用来处理显示赢钱时 不需要播放数字变化动画
--
function StarryXmasGameBottomNode:notifyUpdateWinLabel(winCoin,isUpdateTopUI,isPlayAnim)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local pickGame = selfData.PickGame or ""
    local litterWin = selfData.LitterGameWin or 0
    local changeFreespinOver = false
    if  self.m_machine then
        if pickGame == "Litter" and self.isAddLineWin then
            winCoin = winCoin - litterWin
            isUpdateTopUI = false
        elseif pickGame == "FreeGame" then
            isUpdateTopUI = false
        end
        if self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
            local isFreeSpinOver = self.m_machine:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
            if isFreeSpinOver then
                changeFreespinOver = true
            end
        end
    end
    

    self:resetWinLabel()
    self.m_isUpdateTopUI = isUpdateTopUI

    if globalData.slotRunData.lastWinCoin ~= 0 then
        if pickGame == "Litter" and self.isAddLineWin then
            self.m_spinWinCount = winCoin
        else
            self.m_spinWinCount = globalData.slotRunData.lastWinCoin
        end
        
    else
        -- if pickGame == "Litter" and not self.isAddLineWin then
        --     self.m_spinWinCount = litterWin
        -- else
            self.m_spinWinCount = winCoin
        -- end
    end

    if self.m_spinWinCount == 0 then
        return
    end

    local function updateComplete()
        if self.m_isUpdateTopUI == true then
            self:notifyTopWinCoin()
            self:checkClearWinLabel()
        end
        
        self:resetWinLabel()
    end



    if isPlayAnim == false then

        self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount))

        updateComplete()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE,1)
        return
    end

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winCoin / totalBet
    local showTime = 2
    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2.5
        if changeFreespinOver then
            showTime = 2
        end
    elseif winRate > 6 then
        showTime = 3
        if changeFreespinOver then
            showTime = 3
        end
    end
    local coinRiseNum =  winCoin / (showTime * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AUTO_SPIN_DELAY_TIME, showTime)

    coinRiseNum = math.floor(coinRiseNum ) 
    
    local curSpinCount = 0

    if globalData.slotRunData.lastWinCoin ~= 0 then
        if pickGame == "Litter" and self.isAddLineWin then
            curSpinCount = 0
        else
            curSpinCount = globalData.slotRunData.lastWinCoin - winCoin
        end
    else
        if pickGame == "Litter" and not self.isAddLineWin then
            curSpinCount = winCoin - litterWin
        else
            curSpinCount = 0
        end
        
    end

    
    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        curSpinCount = curSpinCount + coinRiseNum

        if curSpinCount >= self.m_spinWinCount then
            curSpinCount = self.m_spinWinCount
            updateComplete()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE,0.5)
            self.isAddLineWin = true
        end
        self:updateWinCount(util_getFromatMoneyStr(curSpinCount))
    end)
end

function StarryXmasGameBottomNode:clearWinLabel( )
    self:checkClearWinLabel()
end

return  StarryXmasGameBottomNode