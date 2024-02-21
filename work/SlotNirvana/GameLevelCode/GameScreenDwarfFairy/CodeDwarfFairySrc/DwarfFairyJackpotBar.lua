---
--xhkj
--2018年6月11日
--DwarfFairyJackpotBar.lua

local DwarfFairyJackpotBar = class("DwarfFairyJackpotBar", util_require("base.BaseView"))

function DwarfFairyJackpotBar:initUI(data)
    local resourceFilename="DwarfFairy_Jackpot.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)
end

function DwarfFairyJackpotBar:initMachine(machine)
    self.m_machine = machine
end

function DwarfFairyJackpotBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function DwarfFairyJackpotBar:updateJackpotInfo()
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

function DwarfFairyJackpotBar:updateSize()

    local label1=self.m_csbOwner["m_lb_grand"]
    local label2=self.m_csbOwner["m_lb_major"]
    local info1={label=label1}
    local info2={label=label2}
    self:updateLabelSize(info1,320,{info2})

    -- self:updateLabelSize(info2,265)

    local label3=self.m_csbOwner["m_lb_minor"]
    local label4=self.m_csbOwner["m_lb_mini"]
    local info3={label=label3}
    local info4={label=label4}
    self:updateLabelSize(info3,200,{info4})
end

function DwarfFairyJackpotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end

function DwarfFairyJackpotBar:toAction(actionName)

    self:runCsbAction(actionName)
end


return DwarfFairyJackpotBar