---
--xcyy
--2018年5月23日
--FarmJackPotBarView.lua

local FarmJackPotBarView = class("FarmJackPotBarView",util_require("base.BaseView"))


function FarmJackPotBarView:initUI()

    self:createCsbNode("Farm_JackPot.csb")

end

function FarmJackPotBarView:onExit()
 
end

function FarmJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function FarmJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function FarmJackPotBarView:updateJackpotInfo()
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

function FarmJackPotBarView:updateSize()

    local label1=self.m_csbOwner["font_grand"]
    local label2=self.m_csbOwner["font_major"]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}

    local label3=self.m_csbOwner["font_minor"]
    local label4=self.m_csbOwner["font_mini"]
    local info3={label=label3,sx=1,sy=1}
    local info4={label=label4,sx=1,sy=1}

    self:updateLabelSize(info1,262)
    self:updateLabelSize(info2,236)
    self:updateLabelSize(info3,210)
    self:updateLabelSize(info4,170)
end

function FarmJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function FarmJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return FarmJackPotBarView