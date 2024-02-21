local GoldenGhostGoldMidTopUI = class("GoldenGhostGoldMidTopUI", util_require("base.BaseView"))

local CodeGameScreenGoldenGhostMachine = util_require("CodeGameScreenGoldenGhostMachine")

function GoldenGhostGoldMidTopUI:initUI()
    self:createCsbNode("GoldenGhost_coins.csb")

    -- self.m_pot = util_createAnimation("GoldenGhost_pot.csb")
    -- self:findChild("Node_1"):addChild(self.m_pot, -1)
    
    self:runCsbAction("actionframe",false)
    local lbScore = self:findChild("m_lb_coins")
    self.lbScore = lbScore
    lbScore:setVisible(false)
    self:addParticle()
end

function GoldenGhostGoldMidTopUI:addParticle()
    local pos = cc.p(self.lbScore:getPosition())
    --先注释 collectEffect
    -- local collectEffect = cc.ParticleSystemQuad:create("Effect/GoldenGhost_bg_lizi.plist")
    -- collectEffect:setPosition(cc.p(pos.x,pos.y - 110))
    -- self:addChild(collectEffect,-1)
end

function GoldenGhostGoldMidTopUI:setScore(score,playAnimFlag)
    if self.score == score then return end
    self.score = score
    local lbScore = self.lbScore
    local strScore = util_formatCoins(score,3)
    lbScore:setString(strScore)
    lbScore:setVisible(score > 0)
    self:runCsbAction("shouji",false)
end

function GoldenGhostGoldMidTopUI:setAnimScore(preScore,score)
    self.score = preScore + score
    local lbScore = self.lbScore
    local preScoreScale = lbScore:getScale()
    lbScore:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2,1.3),
        cc.ScaleTo:create(0.1,0,1.3),
        cc.CallFunc:create(function(sender)
            local strScore = util_formatCoins(preScore + score,3)
            lbScore:setString(strScore)
        end),cc.ScaleTo:create(0.1,1.3),cc.ScaleTo:create(0.2,preScoreScale))
    )
end

function GoldenGhostGoldMidTopUI:getScore()
    return self.score
end

return GoldenGhostGoldMidTopUI