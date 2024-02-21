---
--xcyy
--2018年5月23日
--ClawStallJackPotBarView.lua

local ClawStallJackPotBarView = class("ClawStallJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins1"
local MajorName = "m_lb_coins1_0"
local MinorName = "m_lb_coins1_1"
local MiniName = "m_lb_coins1_2" 

function ClawStallJackPotBarView:initUI(params)

    self:initMachine(params.machine)
    self:createCsbNode("ClawStall_Machine_JackpotView.csb")

    self:runCsbAction("idle",true)

    self.m_jackpotLights = {}

end

function ClawStallJackPotBarView:onEnter()

    ClawStallJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function ClawStallJackPotBarView:onExit()
    ClawStallJackPotBarView.super.onExit(self)
end

function ClawStallJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function ClawStallJackPotBarView:updateJackpotInfo()
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

function ClawStallJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,280)
    self:updateLabelSize(info2,280)
    self:updateLabelSize(info3,280)
    self:updateLabelSize(info4,280)
end

function ClawStallJackPotBarView:changeNode(label,index,isJump)
    local avgbet
    local fsExtra = self.m_machine.m_runSpinResultData.p_fsExtraData
    if self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE and fsExtra and fsExtra.avgBet then
        avgbet = fsExtra.avgBet
    end
    local value=self.m_machine:BaseMania_updateJackpotScore(index,avgbet)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--[[
    显示中奖光效
]]
function ClawStallJackPotBarView:showJackpotLight(jackpotType)
    if self.m_jackpotLights[jackpotType] then
        return
    end
    local light = util_createAnimation("ClawStall_caijin.csb")
    self:findChild("zj_"..jackpotType):addChild(light)
    light:runCsbAction("actionframe",true)

    self.m_jackpotLights[jackpotType] = true
end

--[[
    隐藏中奖光效
]]
function ClawStallJackPotBarView:hideJackpotLight(jackpotType)
    
    if jackpotType then
        self.m_jackpotLights[jackpotType] = false
        self:findChild("zj_"..jackpotType):removeAllChildren()
    else
        self:findChild("zj_grand"):removeAllChildren()
        self:findChild("zj_major"):removeAllChildren()
        self:findChild("zj_minor"):removeAllChildren()
        self:findChild("zj_mini"):removeAllChildren()
        self.m_jackpotLights = {}
    end
    
end


return ClawStallJackPotBarView