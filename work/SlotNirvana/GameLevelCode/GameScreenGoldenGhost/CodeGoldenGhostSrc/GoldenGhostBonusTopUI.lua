local JmsBaseView = util_require("base.BaseView")
local GoldenGhostBonusTopUI = class("GoldenGhostBonusTopUI", util_require("base.BaseView"))

function GoldenGhostBonusTopUI:ctor()
    JmsBaseView.ctor(self)
    self.m_leftScore = 0
    self.m_rightScore = 0
end

function GoldenGhostBonusTopUI:initUI()
    self:createCsbNode("GoldenGhost_Jackpot_0.csb")
    self:runCsbAction("idle",true)

    self.lbLeftCoin = self:findChild("m_lb_leftCoins")
    self.lbRightCoin = self:findChild("m_lb_rightCoins")
end

function GoldenGhostBonusTopUI:setExtraInfo(machine)
    self.machine = machine
    self.goldMidTopUI = machine.goldMidTopUI
end

function GoldenGhostBonusTopUI:setTopScore(leftScore,rightScore,goldScore)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local numStr = "0"
    if leftScore ~= nil then
        -- numStr = util_formatCoins(totalBet * leftScore,3)
        numStr = self.machine:getCoinsByScore(leftScore)
        self.lbLeftCoin:setString(numStr)
    end
    if rightScore ~= nil and rightScore ~= self.m_rightScore then
        self.m_rightScore = rightScore
        -- numStr = util_formatCoins(totalBet * rightScore,3)
        numStr = self.machine:getCoinsByScore(rightScore)
        self.lbRightCoin:setString(numStr)
        self:runCsbAction("actionframe",false)
    end
    if goldScore ~= nil then
        self.goldMidTopUI:setScore(goldScore)
    end
end

function GoldenGhostBonusTopUI:addTopScore(leftScore,rightScore,goldScore)
    local lbLeftCoin = self.lbLeftCoin
    local lbRightCoin = self.lbRightCoin
    local goldMidTopUI = self.goldMidTopUI

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local numStr = "0"
    -- if leftScore ~= nil then
    --     self.m_leftScore = self.m_leftScore + leftScore
    --     numStr = util_formatCoins(totalBet * self.m_leftScore,3)
    --     lbLeftCoin:setString(numStr)
    -- end
    if rightScore ~= nil then
        local preRightScoreScale = lbRightCoin:getScale()
        self.m_rightScore = self.m_rightScore + rightScore
        -- numStr = util_formatCoins(totalBet * self.m_rightScore,3)
        numStr = self.machine:getCoinsByScore(self.m_rightScore)
        lbRightCoin:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2,0.9),
            cc.ScaleTo:create(0.1,0,0.9),
            cc.CallFunc:create(function(sender)
                lbRightCoin:setString(numStr)
            end),cc.ScaleTo:create(0.1,0.9),cc.ScaleTo:create(0.2,preRightScoreScale,preRightScoreScale))
        )
    end
    if goldScore ~= nil then
        if goldMidTopUI then
            local preGoldScore = goldMidTopUI:getScore()
            goldMidTopUI:setAnimScore(preGoldScore,goldScore)
        end
    end
end

return GoldenGhostBonusTopUI