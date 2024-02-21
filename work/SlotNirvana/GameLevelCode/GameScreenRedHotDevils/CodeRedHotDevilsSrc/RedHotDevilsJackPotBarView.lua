---
--xcyy
--2018年5月23日
--RedHotDevilsJackPotBarView.lua

local RedHotDevilsJackPotBarView = class("RedHotDevilsJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_GRAND"
local MajorName = "m_lb_coins_MAJOR"
local MinorName = "m_lb_coins_MINOR"
local MiniName = "m_lb_coins_MINI" 

function RedHotDevilsJackPotBarView:initUI(_isJackpot)

    self.isJackpot = _isJackpot

    if self.isJackpot then
        self:createCsbNode("RedHotDevils_jackpotkuang_jackpot.csb")
    else
        self:createCsbNode("RedHotDevils_jackpotkuang_base.csb")
        self:runCsbAction("idle",true)
    end

    -- self:runCsbAction("idleframe",true)

end

function RedHotDevilsJackPotBarView:onEnter()

    RedHotDevilsJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function RedHotDevilsJackPotBarView:onExit()
    RedHotDevilsJackPotBarView.super.onExit(self)
end

function RedHotDevilsJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function RedHotDevilsJackPotBarView:updateJackpotInfo()
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

function RedHotDevilsJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,245)
    self:updateLabelSize(info2,245)
    self:updateLabelSize(info3,240)
    self:updateLabelSize(info4,240)
end

function RedHotDevilsJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return RedHotDevilsJackPotBarView