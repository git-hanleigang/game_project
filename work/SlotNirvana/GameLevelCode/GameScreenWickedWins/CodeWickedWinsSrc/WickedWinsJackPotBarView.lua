---
--xcyy
--2018年5月23日
--WickedWinsJackPotBarView.lua

local WickedWinsJackPotBarView = class("WickedWinsJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_grand_coins"
local MajorName = "m_lb_major_coins"
local MinorName = "m_lb_minor_coins"
local MiniName = "m_lb_mini_coins" 

function WickedWinsJackPotBarView:initUI()

    self:createCsbNode("WickedWins_Jackpot.csb")

    self:runCsbAction("idle",true)

end

function WickedWinsJackPotBarView:onEnter()

    WickedWinsJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function WickedWinsJackPotBarView:onExit()
    WickedWinsJackPotBarView.super.onExit(self)
end

function WickedWinsJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function WickedWinsJackPotBarView:getGrandNodePos()
    local endPos = util_convertToNodeSpace(self:findChild("Node_grand"), self.m_machine:findChild("Node_cut_scene"))
    return endPos
end

-- 更新jackpot 数值信息
--
function WickedWinsJackPotBarView:updateJackpotInfo()
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

function WickedWinsJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.97,sy=1}
    local info2={label=label2,sx=0.79,sy=0.83}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.79,sy=0.81}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.79,sy=0.80}
    self:updateLabelSize(info1,278)
    self:updateLabelSize(info2,233)
    self:updateLabelSize(info3,214)
    self:updateLabelSize(info4,188)
end

function WickedWinsJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return WickedWinsJackPotBarView
