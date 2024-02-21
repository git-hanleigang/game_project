---
--xcyy
--2018年5月23日
--AZTECChooseBetView.lua

local AZTECChooseBetView = class("AZTECChooseBetView",util_require("base.BaseView"))

local SYMBOL_WIN_LINES_5 =
{
    {1000,200,100},
    {500,100,50},
    {300,60,30},
    {200,40,20},
    {100,20,10},
    {1000,200,100},
    {500,100,50},
    {300,60,30},
    {200,40,20},
    {50,10,4},
    {50,10,4},
    {50,10,4},
    {3800,1800,800}
}
local SYMBOL_WIN_LINES_4 =
{
    {100,20,10},
    {700,140,70},
    {400,80,40},
    {300,60,30},
    {200,40,20},
    {100,20,10},
    {700,140,70},
    {400,80,40},
    {300,60,30},
    {100,20,10},
    {100,20,10},
    {100,20,10},
    {3800,1800,800}
}
local SYMBOL_WIN_LINES_3 =
{
    {120,24,12},
    {120,24,12},
    {500,100,50},
    {400,80,40},
    {300,60,30},
    {120,24,12},
    {120,24,12},
    {500,100,50},
    {400,80,40},
    {120,24,12},
    {120,24,12},
    {120,24,12},
    {3800,1800,800}
}
local SYMBOL_WIN_LINES_2 =
{
    {200,40,20},
    {200,40,20},
    {200,40,20},
    {400,120,60},
    {300,60,30},
    {200,40,20},
    {200,40,20},
    {200,40,20},
    {400,120,60},
    {150,30,14},
    {150,30,14},
    {150,30,14},
    {3800,1800,800}
}
local SYMBOL_WIN_LINES_1 =
{
    {200,40,20},
    {200,40,20},
    {200,40,20},
    {200,40,20},
    {700,120,60},
    {200,40,20},
    {200,40,20},
    {200,40,20},
    {200,40,20},
    {100,20,10},
    {100,20,10},
    {100,20,10},
    {3800,1800,800}
}

local SYMBOL_WIN_NUM = {5, 4, 3}

function AZTECChooseBetView:initUI(data)

    self:createCsbNode("AZTEC/GameScreenAZTEC_bet.csb")
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    self.m_chooseTotal = 1
    for i = 1, #data, 1 do
        if data[i] <= betList[#betList].p_totalBetValue then
            self.m_chooseTotal = i
        else
            break
        end
    end
    for i = 1, 5, 1 do
        if i <= self.m_chooseTotal then
            self:addClick(self:findChild("click_"..i))
            self:findChild("mark_"..i):setVisible(false)
        else
            self:findChild("mark_"..i):setVisible(true)
        end
    end
    -- self:addClick(self:findChild("click_1")) -- 非按钮节点得手动绑定监听
    -- self:addClick(self:findChild("click_2"))
    -- self:addClick(self:findChild("click_3"))
    -- self:addClick(self:findChild("click_4"))
    -- self:addClick(self:findChild("click_5"))

    self.m_vecTotalBet = data
    self.m_iBetID = self.m_chooseTotal
    self.m_selected = false
    
    for i = 1, #self.m_vecTotalBet, 1 do
        local lab = self:findChild("m_lb_bet_"..i)
        lab:setString("BET $"..util_formatCoins(self.m_vecTotalBet[i], 4, nil, nil, true))
    end

    local totalBet = self.m_vecTotalBet[5]
    self:updateWinCoins(totalBet)
    self:runCsbAction("open", false, function()
        self:changeIndex()
        self.m_idleAction = schedule(self, function()
            self:changeIndex()
        end, 1)
    end)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function AZTECChooseBetView:changeIndex()
    self.m_iBetID = self.m_iBetID - 1
    if self.m_iBetID == 0 then
        self.m_iBetID = self.m_chooseTotal
    end
    self:runCsbAction("actionframe"..self.m_iBetID)
    local totalBet = self.m_vecTotalBet[self.m_iBetID]
    self:updateWinCoins(totalBet)
end

function AZTECChooseBetView:getwinLinesList(id)
    if id == 5 then
        return SYMBOL_WIN_LINES_5
    elseif id == 4 then
        return SYMBOL_WIN_LINES_4
    elseif id == 3 then
        return SYMBOL_WIN_LINES_3
    elseif id == 2 then
        return SYMBOL_WIN_LINES_2
    elseif id == 1 then
        return SYMBOL_WIN_LINES_1
    end
end

function AZTECChooseBetView:updateWinCoins(totalBet, selected)
    if self.m_selected == true then
        return
    end
    self.m_selected = selected
    local winLinsList = self:getwinLinesList(self.m_iBetID)
    local index = 0
    while true do
        local lab5 = self:findChild("symbol_" .. index .. "_5" )
        if lab5 ~= nil then
            local winCoin = totalBet * 0.01 * winLinsList[index + 1][1] 
            lab5:setString(util_formatCoins(winCoin, 3, nil, nil, true))

            local lab4 = self:findChild("symbol_" .. index .. "_4" )
            winCoin = totalBet * 0.01 * winLinsList[index + 1][2] 
            lab4:setString(util_formatCoins(winCoin, 3, nil, nil, true))

            local lab3 = self:findChild("symbol_" .. index .. "_3" )
            winCoin = totalBet * 0.01 * winLinsList[index + 1][3] 
            lab3:setString(util_formatCoins(winCoin, 3, nil, nil, true))
        else
            break
        end
        index = index + 1
    end
end

function AZTECChooseBetView:onEnter()
    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end

end

function AZTECChooseBetView:showAdd()
    
end
function AZTECChooseBetView:onExit()
 
end

--默认按钮监听回调
function AZTECChooseBetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_selected == true then
        return
    end
    gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_click_bet.mp3")
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
        -- self:runCsbAction("over", false, function()
        --     self:removeFromParent()
        -- end)
        -- self:runAction(cc.Sequence:create(cc.FadeOut:create(0.5), cc.CallFunc:create(function ()
        --     self:removeFromParent()
        -- end)))
        
        self:findChild("root"):runAction(cc.Sequence:create(cc.EaseBackIn:create(cc.ScaleTo:create(0.5, 0)), cc.CallFunc:create(function ()
            self:removeFromParent()
        end)))
    end, 1)
end

function AZTECChooseBetView:clilkBet(totalBet)

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

return AZTECChooseBetView