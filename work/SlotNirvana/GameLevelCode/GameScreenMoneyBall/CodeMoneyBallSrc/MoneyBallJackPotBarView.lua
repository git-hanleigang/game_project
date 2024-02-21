---
--xcyy
--2018年5月23日
--MoneyBallJackPotBarView.lua

local MoneyBallJackPotBarView = class("MoneyBallJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_coins"
local MajorName = "m_lb_coins_2"
local MinorName = "m_lb_coins_3"
local MiniName = "m_lb_coins_4" 

function MoneyBallJackPotBarView:initUI()

    self:createCsbNode("MoneyBall_jackpot.csb")

    -- self:runCsbAction("idleframe",true)

end



function MoneyBallJackPotBarView:onExit()
 
end

function MoneyBallJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function MoneyBallJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function MoneyBallJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function MoneyBallJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.5,sy=0.5}
    local info2={label=label2,sx=0.5,sy=0.5}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.39,sy=0.39}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.39,sy=0.39}
    self:updateLabelSize(info1,650)
    self:updateLabelSize(info2,650)
    self:updateLabelSize(info3,560)
    self:updateLabelSize(info4,560)
end

function MoneyBallJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function MoneyBallJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return MoneyBallJackPotBarView