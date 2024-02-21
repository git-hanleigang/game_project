---
--xcyy
--2018年5月23日
--PiggyLegendPirateJackPotBarView.lua

local PiggyLegendPirateJackPotBarView = class("PiggyLegendPirateJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_0"
local MajorName = "m_lb_coins_1"
local MinorName = "m_lb_coins_2"
local MiniName = "m_lb_coins_3" 

function PiggyLegendPirateJackPotBarView:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("PiggyLegendPirate_jackpot.csb")

    self:runCsbAction("idle",true)

    self.m_jackpotChuFa = {}
    local jackpotNode = {"grand", "major", "minor", "mini"}
    for i=1,4 do
        self.m_jackpotChuFa[i] = util_createAnimation("PiggyLegendPirate_jackpot_chufa.csb")
        self:findChild(jackpotNode[i]):addChild(self.m_jackpotChuFa[i])
        self.m_jackpotChuFa[i]:setVisible(false)
        for j=1,4 do
            self.m_jackpotChuFa[i]:findChild(jackpotNode[j]):setVisible(false)
        end
        self.m_jackpotChuFa[i]:findChild(jackpotNode[i]):setVisible(true)
    end
    
end

function PiggyLegendPirateJackPotBarView:playJackPotActionframe(index)
    local nodeName = {"grand","major","minor","mini"}
    for k,v in pairs(nodeName) do
        local node =  self:findChild(v)
        if node then
            if v == index then
                self.m_jackpotChuFa[k]:setVisible(true)
                self:runCsbAction("chufa",false,function()
                    self:runCsbAction("idle",true)
                end)
                local particle = self.m_jackpotChuFa[k]:findChild("Particle_1")
                particle:setDuration(0.5)
                particle:stopSystem()
                particle:resetSystem() 
                self.m_jackpotChuFa[k]:runCsbAction("actionframe",false,function()
                    particle:stopSystem()
                end)
            else
                self.m_jackpotChuFa[k]:setVisible(false)
            end
        end
    end
end

function PiggyLegendPirateJackPotBarView:onEnter()

    PiggyLegendPirateJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function PiggyLegendPirateJackPotBarView:onExit()
    PiggyLegendPirateJackPotBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function PiggyLegendPirateJackPotBarView:updateJackpotInfo()
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

function PiggyLegendPirateJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.95,sy=0.95}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.9,sy=0.9}
    self:updateLabelSize(info1,250)
    self:updateLabelSize(info2,230)
    self:updateLabelSize(info3,201)
    self:updateLabelSize(info4,201)
end

function PiggyLegendPirateJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,30,nil,nil,true))
end



return PiggyLegendPirateJackPotBarView