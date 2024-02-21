---
--xcyy
--2018年5月23日
--WingsOfPhoelinxJackPotBarView.lua

local WingsOfPhoelinxJackPotBarView = class("WingsOfPhoelinxJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_GRAND"
local MajorName = "m_lb_coins_MAJOR"
local MinorName = "m_lb_coins_MINOR"
local MiniName = "m_lb_coins_MINI" 

function WingsOfPhoelinxJackPotBarView:initUI()

    self:createCsbNode("WingsOfPhoelinx_jackpotkuang.csb")


end



function WingsOfPhoelinxJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function WingsOfPhoelinxJackPotBarView:onEnter()

    WingsOfPhoelinxJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function WingsOfPhoelinxJackPotBarView:onExit()
    WingsOfPhoelinxJackPotBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function WingsOfPhoelinxJackPotBarView:updateJackpotInfo()
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

function WingsOfPhoelinxJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.31,sy=0.31}
    local info2={label=label2,sx=0.31,sy=0.31}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.31,sy=0.31}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.31,sy=0.31}
    self:updateLabelSize(info1,697)
    self:updateLabelSize(info2,644)
    self:updateLabelSize(info3,595)
    self:updateLabelSize(info4,512)
end

function WingsOfPhoelinxJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end



return WingsOfPhoelinxJackPotBarView