---
--xcyy
--2018年5月23日
--CharmsFSJackPotBar.lua

local CharmsFSJackPotBar = class("CharmsFSJackPotBar",util_require("base.BaseView"))


function CharmsFSJackPotBar:initUI()

    self:createCsbNode("JackPotBar_Charms_0.csb")

end

function CharmsFSJackPotBar:onExit()
 
end

function CharmsFSJackPotBar:initMachine(machine)
    self.m_machine = machine
end

function CharmsFSJackPotBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function CharmsFSJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("m_lb_grand_0"),1,true)
    self:changeNode(self:findChild("m_lb_major_0"),2,true)
    self:updateSize()
end

function CharmsFSJackPotBar:updateSize()

    local label1=self.m_csbOwner["m_lb_grand_0"]
    local label2=self.m_csbOwner["m_lb_major_0"]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.94,sy=0.94}


    self:updateLabelSize(info1,350)
    self:updateLabelSize(info2,350)
end

function CharmsFSJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end

function CharmsFSJackPotBar:toAction(actionName)

    self:runCsbAction(actionName)
end


return CharmsFSJackPotBar