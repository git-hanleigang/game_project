---
--xcyy
--2018年5月23日
--MiningManiaJackPotBarView.lua

local MiningManiaJackPotBarView = class("MiningManiaJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

function MiningManiaJackPotBarView:initUI()

    self:createCsbNode("MiningMania_JackPotBar.csb")

    self.m_lightJp = {}
    self.m_lightJp[1] = self:findChild("grand_tx")
    self.m_lightJp[2] = self:findChild("major_tx")
    self.m_lightJp[3] = self:findChild("minor_tx")
    self.m_lightJp[4] = self:findChild("mini_tx")

    self.m_triggerData = {}

    self:setJpIdle()
end

function MiningManiaJackPotBarView:onEnter()
    MiningManiaJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function MiningManiaJackPotBarView:onExit()
    MiningManiaJackPotBarView.super.onExit(self)
end

function MiningManiaJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

-- jackpot触发
function MiningManiaJackPotBarView:triggerJackpot(_jpIndex)
    self.m_triggerData[_jpIndex] = true
    for i=1, #self.m_lightJp do
        if self.m_triggerData[i] then
            self.m_lightJp[i]:setVisible(true)
        else
            self.m_lightJp[i]:setVisible(false)
        end
    end
    self:runCsbAction("actionframe",true)
end

function MiningManiaJackPotBarView:setJpIdle()
    self.m_triggerData = {}
    self:runCsbAction("idleframe",true)
end

-- 更新jackpot 数值信息
--
function MiningManiaJackPotBarView:updateJackpotInfo()
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

function MiningManiaJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.8,sy=0.8}
    local info2={label=label2,sx=0.83,sy=0.83}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.84,sy=0.84}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.81,sy=0.81}
    self:updateLabelSize(info1,302)
    self:updateLabelSize(info2,222)
    self:updateLabelSize(info3,227)
    self:updateLabelSize(info4,227)
end

function MiningManiaJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return MiningManiaJackPotBarView
