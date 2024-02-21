---
--xcyy
--2018年5月23日
--PomiJackPotBarView.lua

local PomiJackPotBarView = class("PomiJackPotBarView",util_require("base.BaseView"))

function PomiJackPotBarView:initUI()

    self:createCsbNode("LinkReels/PomiLink/4in1_Pomi_Jackpot.csb")
 
end

function PomiJackPotBarView:onExit()
 
end



function PomiJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function PomiJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end



-- 更新jackpot 数值信息
--
function PomiJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("ml_b_coins1"),1,true)
    self:changeNode(self:findChild("ml_b_coins2"),2,true)
    self:changeNode(self:findChild("ml_b_coins3"),3)
    self:changeNode(self:findChild("ml_b_coins4"),4)

    self:updateSize()
end

function PomiJackPotBarView:updateSize()

    local label1=self.m_csbOwner["ml_b_coins1"]
    local label2=self.m_csbOwner["ml_b_coins2"]
    local label3=self.m_csbOwner["ml_b_coins3"]
    local label4=self.m_csbOwner["ml_b_coins4"]


    local info1={label=label1,sx = 1,sy = 1}
    local info2={label=label2,sx = 0.87,sy = 0.87}
    local info3={label=label3,sx = 0.78,sy = 0.78}
    local info4={label=label4,sx = 0.78,sy = 0.78}


    self:updateLabelSize(info1,560)
    self:updateLabelSize(info2,518)
    self:updateLabelSize(info3,417)
    self:updateLabelSize(info4,331)

end


function PomiJackPotBarView:changeNode(label,index,isJump)

        local value=self.m_machine:BaseMania_updateJackpotScore(index)

        label:setString(util_formatCoins(value,20))

    
end



return PomiJackPotBarView