
local AZTECShowBetView = class("AZTECShowBetView",util_require("Levels.BaseLevelDialog"))


function AZTECShowBetView:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("AZTEC/GameScreenAZTEC_RaiseBetTips.csb")

    self.m_betIdx = 1
    self.m_canClick = false

    self:setUI()
    self:runCsbAction("start", false, function()
        self.m_canClick = true
    end)

    if not self.m_waitNode then
        self.m_waitNode = cc.Node:create()
        self:addChild(self.m_waitNode)
    end
    performWithDelay(self.m_waitNode, function()
        self.m_canClick = false
        self:runCsbAction("over", false, function()
            self:removeFromParent()
        end)

    end, 2.5)

    self:addClick(self:findChild("Panel_1"))
end

--默认按钮监听回调
function AZTECShowBetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    
    if name == "Panel_1" then
        if self.m_canClick then
            self.m_waitNode:stopAllActions()
            self.m_canClick = false
            self:runCsbAction("over", false, function()
                self:removeFromParent()
            end)
        end
    end

end

function AZTECShowBetView:onEnter()
    AZTECShowBetView.super.onEnter(self)
end

function AZTECShowBetView:onExit()
    AZTECShowBetView.super.onExit(self)
end

function AZTECShowBetView:setUI()
    local betCoin = globalData.slotRunData:getCurTotalBet()
    self.m_betIdx = 1
    if self.m_machine then
        if self.m_machine.m_specialBets and #self.m_machine.m_specialBets > 0 then
            self.m_betIdx = #self.m_machine.m_specialBets + 1
            for i = 1, #self.m_machine.m_specialBets do
                if betCoin < self.m_machine.m_specialBets[i].p_totalBetValue then
                    self.m_betIdx = i
                    break
                end
            end
        else
            self.m_betIdx = 1
        end
        if globalData.slotRunData.isDeluexeClub == true then
            self.m_betIdx = 5
        end
    end
    
    for i = 1, 4 do
        local low = self:findChild("icon" .. (i - 1) .. "_low")
        local high = self:findChild("icon" .. (i - 1) .. "_high")

        
        if (6 - i) <= self.m_betIdx then
            high:setVisible(true)
            low:setVisible(false)
        else
            high:setVisible(false)
            low:setVisible(true)
        end
    end

    if self.m_betIdx == 5 then
        self:findChild("text1"):setVisible(false)
    else
        self:findChild("text1"):setVisible(true)
    end

    local num = self.m_betIdx
    self:findChild("m_lb_num"):setString(tostring(num))
end

return AZTECShowBetView