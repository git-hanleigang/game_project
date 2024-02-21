---
--xcyy
--2018年5月23日
--BeerGirlJackPotBarView.lua

local BeerGirlJackPotBarView = class("BeerGirlJackPotBarView",util_require("base.BaseView"))


function BeerGirlJackPotBarView:initUI()

    self:createCsbNode("BeerGirl_jackpot.csb")

    self:runCsbAction("idleframe",true)

end

function BeerGirlJackPotBarView:onExit()
 
end

function BeerGirlJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function BeerGirlJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function BeerGirlJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("font_grand"),1,true)
    self:changeNode(self:findChild("font_major"),2,true)
    self:changeNode(self:findChild("font_minor"),3)
    self:changeNode(self:findChild("font_mini"),4)
    self:updateSize()
end

function BeerGirlJackPotBarView:updateSize()

    local label1=self.m_csbOwner["font_grand"]
    local label2=self.m_csbOwner["font_major"]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}

    local label3=self.m_csbOwner["font_minor"]
    local label4=self.m_csbOwner["font_mini"]
    local info3={label=label3,sx=1,sy=1}
    local info4={label=label4,sx=1,sy=1}

    self:updateLabelSize(info1,189)
    self:updateLabelSize(info2,189)
    self:updateLabelSize(info3,189)
    self:updateLabelSize(info4,133)
end

function BeerGirlJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function BeerGirlJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return BeerGirlJackPotBarView