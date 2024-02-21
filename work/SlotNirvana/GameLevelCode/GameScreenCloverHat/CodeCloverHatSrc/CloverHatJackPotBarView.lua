---
--xcyy
--2018年5月23日
--CloverHatJackPotBarView.lua

local CloverHatJackPotBarView = class("CloverHatJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

function CloverHatJackPotBarView:initUI()

    self:createCsbNode("CloverHat_jackpot.csb")

    self:runCsbAction("ilde")

end

function CloverHatJackPotBarView:onExit()
 
end

function CloverHatJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function CloverHatJackPotBarView:onEnter()

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function CloverHatJackPotBarView:updateJackpotInfo()
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

function CloverHatJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=1.3,sy=1.3}
    local label2=self.m_csbOwner[MajorName]
    local info2={label=label2,sx=1.3,sy=1.3}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1.3,sy=1.3}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1.3,sy=1.3}
    self:updateLabelSize(info1,182)
    self:updateLabelSize(info2,138)
    self:updateLabelSize(info3,120)
    self:updateLabelSize(info4,102)
end

function CloverHatJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end





return CloverHatJackPotBarView