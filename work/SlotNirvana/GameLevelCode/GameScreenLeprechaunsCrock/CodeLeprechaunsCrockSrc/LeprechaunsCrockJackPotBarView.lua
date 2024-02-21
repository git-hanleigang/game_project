---
--xcyy
--2018年5月23日
--LeprechaunsCrockJackPotBarView.lua

local LeprechaunsCrockJackPotBarView = class("LeprechaunsCrockJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_1"
local MegaName = "m_lb_coins_2"
local MajorName = "m_lb_coins_3"
local MinorName = "m_lb_coins_4"
local MiniName = "m_lb_coins_5" 

function LeprechaunsCrockJackPotBarView:initUI()

    self:createCsbNode("LeprechaunsCrock_jackpot_base.csb")

    self:runCsbAction("idleframe",true)

end

function LeprechaunsCrockJackPotBarView:onEnter()

    LeprechaunsCrockJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function LeprechaunsCrockJackPotBarView:onExit()
    LeprechaunsCrockJackPotBarView.super.onExit(self)
end

function LeprechaunsCrockJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function LeprechaunsCrockJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MegaName),2,true)
    self:changeNode(self:findChild(MajorName),3)
    self:changeNode(self:findChild(MinorName),4)
    self:changeNode(self:findChild(MiniName),5)

    self:updateSize()
end

function LeprechaunsCrockJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MegaName]
    local info1={label=label1,sx=0.85,sy=1}
    local info2={label=label2,sx=0.81,sy=1}
    local label3=self.m_csbOwner[MajorName]
    local info3={label=label3,sx=0.81,sy=1}
    local label4=self.m_csbOwner[MinorName]
    local info4={label=label4,sx=0.81,sy=1}
    local label5=self.m_csbOwner[MiniName]
    local info5={label=label5,sx=0.81,sy=1}
    self:updateLabelSize(info1,221)
    self:updateLabelSize(info2,221)
    self:updateLabelSize(info3,221)
    self:updateLabelSize(info4,221)
    self:updateLabelSize(info5,221)
end

function LeprechaunsCrockJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return LeprechaunsCrockJackPotBarView