---
--xcyy
--2018年5月23日
--PiggyLegendTreasureJackPotBarView.lua

local PiggyLegendTreasureJackPotBarView = class("PiggyLegendTreasureJackPotBarView",util_require("Levels.BaseLevelDialog"))

local superName = "m_lb_coins_0"

function PiggyLegendTreasureJackPotBarView:initUI()

    self:createCsbNode("PiggyLegendTreasure_super.csb")

    -- self:runCsbAction("idleframe",true)

end

function PiggyLegendTreasureJackPotBarView:onEnter()

    PiggyLegendTreasureJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function PiggyLegendTreasureJackPotBarView:onExit()
    PiggyLegendTreasureJackPotBarView.super.onExit(self)
end

function PiggyLegendTreasureJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function PiggyLegendTreasureJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(superName),1,true)

    self:updateSize()
end

function PiggyLegendTreasureJackPotBarView:updateSize()

    local label1=self.m_csbOwner[superName]
    local info1={label=label1,sx=0.6,sy=0.6}
    
    self:updateLabelSize(info1,600)
end

function PiggyLegendTreasureJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return PiggyLegendTreasureJackPotBarView