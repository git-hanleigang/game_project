---
--xcyy
--2018年5月23日
--MedusaManiaJackPotBarView.lua

local MedusaManiaJackPotBarView = class("MedusaManiaJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"

function MedusaManiaJackPotBarView:initUI(_isJackpot)

    self.isJackpot = _isJackpot
    if self.isJackpot then
        self:createCsbNode("MedusaMania_duofuduocaijackpot.csb")
    else
        self:createCsbNode("MedusaMania_jackpot.csb")
        self:runCsbAction("idle",true)
    end

    -- self:runCsbAction("idleframe",true)

end

function MedusaManiaJackPotBarView:onEnter()

    MedusaManiaJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function MedusaManiaJackPotBarView:onExit()
    MedusaManiaJackPotBarView.super.onExit(self)
end

function MedusaManiaJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function MedusaManiaJackPotBarView:updateJackpotInfo()
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

function MedusaManiaJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    local fontSize = 190
    if self.isJackpot then
        fontSize = 160
    end
    self:updateLabelSize(info1,fontSize)
    self:updateLabelSize(info2,fontSize)
    self:updateLabelSize(info3,fontSize)
    self:updateLabelSize(info4,fontSize)
end

function MedusaManiaJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return MedusaManiaJackPotBarView
