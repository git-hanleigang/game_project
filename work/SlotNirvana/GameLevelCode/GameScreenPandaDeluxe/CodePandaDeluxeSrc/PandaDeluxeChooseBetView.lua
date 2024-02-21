---
--xcyy
--2018年5月23日
--PandaDeluxeChooseBetView.lua

local PandaDeluxeChooseBetView = class("PandaDeluxeChooseBetView",util_require("base.BaseView"))

local SYMBOL_WIN_LINES = 
{
    500,150,75,
    300,75,40,
    200,60,30,
    150,50,25,
    100,25,15 
}

local SYMBOL_WIN_LINES_LOW = 
{
    100,25,15, 
    100,25,15,
    100,25,15, 
    100,25,15,
    100,25,15 
}

local SYMBOL_WIN_NUM = {5, 4, 3}

function PandaDeluxeChooseBetView:initUI(data)

    self:createCsbNode("PandaDeluxe/ChoosebetLayer.csb")
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    self.m_chooseTotal = 1
    for i = 1, #data, 1 do
        if data[i] <= betList[#betList].p_totalBetValue then
            self.m_chooseTotal = i
        else
            break
        end
    end
    

    self.m_vecTotalBet = data
    self.m_iBetID = self.m_chooseTotal + 1
    self.m_selected = false
    
    for i = 1, #self.m_vecTotalBet, 1 do
        local lab = self:findChild("m_lb_bet_"..i)
        lab:setString("BET $"..util_formatCoins(self.m_vecTotalBet[i], 4, nil, nil, true))
    end
   
    local totalBet = self.m_vecTotalBet[5]
    self:updateWinCoins(totalBet)

    for i = 1, 5, 1 do
        if i <= self.m_chooseTotal then
            self:addClick(self:findChild("click_"..i))
            self:findChild("mark_"..i):setVisible(false)
        else
            self:findChild("mark_"..i):setVisible(true)
        end
    end

    self:changeIndex()
    
    self.m_selected = true
    self:runCsbAction("open", false, function()
        
        
        self.m_idleAction = schedule(self, function()
            self:changeIndex()
        end, 1)
        self.m_selected = false
    end)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function PandaDeluxeChooseBetView:changeIndex()
    self.m_iBetID = self.m_iBetID - 1
    if self.m_iBetID == 0 then
        self.m_iBetID = self.m_chooseTotal
    end
    self:runCsbAction("actionframe"..self.m_iBetID)
    local totalBet = self.m_vecTotalBet[self.m_iBetID]
    self:updateWinCoins(totalBet)
end

function PandaDeluxeChooseBetView:updateWinCoins(totalBet, selected)
    if self.m_selected == true then
        return
    end
    self.m_selected = selected


    for i=1,15 do

        local winCoin = totalBet / 88 * SYMBOL_WIN_LINES[i]

        local winCoin_low = totalBet / 88 * SYMBOL_WIN_LINES_LOW[i]
        
        local lab = self:findChild("m_lb_coins_" .. i  )
        if lab ~= nil then
            lab:setString(util_formatCoins(winCoin_low, 3, nil, nil, true))
        end

        local labGold = self:findChild("m_sy_gold_" .. i  )
        if labGold ~= nil then
            labGold:setString(util_formatCoins(winCoin, 3, nil, nil, true))
        end


    end

  
end

function PandaDeluxeChooseBetView:onEnter()
 

end

function PandaDeluxeChooseBetView:showAdd()
    
end
function PandaDeluxeChooseBetView:onExit()
 
end

--默认按钮监听回调
function PandaDeluxeChooseBetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_selected == true then
        return
    end
    gLobalSoundManager:playSound("PandaDeluxeSounds/sound_PandaDeluxe_click_bet.mp3")
    local index = tonumber(string.sub(name, 7))
    self:stopAction(self.m_idleAction)
    local totalBet = self.m_vecTotalBet[index]
    self:updateWinCoins(totalBet, true)
    self:runCsbAction("idle"..index, true)
    for i = 1, 5, 1 do
        if i == index then
            self:findChild("mark_"..i):setVisible(false)
        else
            self:findChild("mark_"..i):setVisible(true)
        end
    end
    performWithDelay(self, function()
        
        self:clilkBet(totalBet)
        self:runCsbAction("over", false, function()
            self:removeFromParent()
        end)

    end, 1)
end

function PandaDeluxeChooseBetView:clilkBet(totalBet)

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if totalBet <= betData.p_totalBetValue then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

return PandaDeluxeChooseBetView