--Score 界面
local LuxuryDiamondScoreView = class("LuxuryDiamondScoreView", util_require("Levels.BaseLevelDialog"))

function LuxuryDiamondScoreView:initUI(machine)
    self.m_machine = machine
    self.m_click = true
    self.m_showIdx = 1

    local resourceFilename = "LuxuryDiamond_Paytable.csb"
    self:createCsbNode(resourceFilename)

    
    self.m_scoreNodes = {}
    for i=1,7 do
        local node = self:findChild("Node_1" .. i)
        local numView = util_createAnimation("LuxuryDiamond_paytableshu.csb")
        node:addChild(numView)
        table.insert(self.m_scoreNodes, numView)

        util_setCascadeOpacityEnabledRescursion(node, true)
    end
    
    self.m_showNodes = {}
    for i=3,5 do
        local node = self:findChild("Node_" .. i)
        table.insert(self.m_showNodes, node)
        node:setVisible(false)
    end
    self:updateShowUI()

end

function LuxuryDiamondScoreView:initViewData()

end

function LuxuryDiamondScoreView:onEnter()
    LuxuryDiamondScoreView.super.onEnter(self)
    schedule(self, function()
        self:updateShowUI()
    end, 3)
end

function LuxuryDiamondScoreView:updateShowUI()
    self:trans(function()
        for i=1,#self.m_showNodes do
            self.m_showNodes[i]:setVisible(i == self.m_showIdx)
        end
    
        self.m_showIdx = self.m_showIdx + 1
        if self.m_showIdx > 3 then
            self.m_showIdx = 1
        end
    end)
end

function LuxuryDiamondScoreView:trans(func1, func2)
    self:runCsbAction("animation1", false, function()
        if func1 then
            func1()
        end
        self:runCsbAction("animation0", false, function()
            if func2 then
                func2()
            end
        end)
    end)
end

function LuxuryDiamondScoreView:updateScore()
    if self.m_machine.m_signalCredit then
        local betCoin = globalData.slotRunData:getCurTotalBet() or 0
        -- betCoin = betCoin / self.m_machine:getCurBetLevelMulti()
        
        if self.m_machine.m_iAverageBet then
            betCoin = self.m_machine.m_iAverageBet
        end

        for i=1,#self.m_scoreNodes do
            local baseNum = 199
            baseNum = baseNum + i
            -- 7种普通符号的分数，用于右侧显示，该分数*玩家押注/上一条的betMulti
            local score = self.m_machine.m_signalCredit[tostring(baseNum)]
            local labelNum = self.m_scoreNodes[i]:findChild("m_lb_coins")
            
            labelNum:setString(util_formatCoins(score * betCoin, 3))
            self:updateLabelSize({label = labelNum, sx = 0.6, sy = 0.6}, 80)
            
        end
    end
    
end

function LuxuryDiamondScoreView:onExit()
    LuxuryDiamondScoreView.super.onExit(self)
end

function LuxuryDiamondScoreView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then

    end
end

return LuxuryDiamondScoreView