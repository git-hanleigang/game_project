---
--xcyy
--2018年5月23日
--CharmsJackPotBar.lua

local CharmsJackPotBar = class("CharmsJackPotBar",util_require("base.BaseView"))


function CharmsJackPotBar:initUI()

    self:createCsbNode("Socre_CandyBingo_jackPot_1.csb")

end

function CharmsJackPotBar:onExit()
 
end

function CharmsJackPotBar:initMachine(machine)
    self.m_machine = machine
end

function CharmsJackPotBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function CharmsJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("m_lb_grand"),1,true)
    self:changeNode(self:findChild("m_lb_major"),2,true)
    self:changeNode(self:findChild("m_lb_minor"),3)
    self:changeNode(self:findChild("m_lb_mini"),4)
    self:updateSize()
end

function CharmsJackPotBar:updateSize()

    local label1=self.m_csbOwner["m_lb_grand"]
    local label2=self.m_csbOwner["m_lb_major"]
    local info1={label=label1,sx=0.9,sy=0.9}
    local info2={label=label2,sx=0.9,sy=0.9}

    local label3=self.m_csbOwner["m_lb_minor"]
    local label4=self.m_csbOwner["m_lb_mini"]
    local info3={label=label3,sx=0.8,sy=0.8}
    local info4={label=label4,sx=0.8,sy=0.8}

    self:updateLabelSize(info1,439)
    self:updateLabelSize(info2,281)
    self:updateLabelSize(info3,202)
    self:updateLabelSize(info4,202)
end

function CharmsJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end

function CharmsJackPotBar:toAction(actionName)

    self:runCsbAction(actionName)
end


return CharmsJackPotBar