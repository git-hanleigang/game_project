---
--xcyy
--2018年5月23日
--ChicEllaJackPotBarView.lua

local ChicEllaJackPotBarView = class("ChicEllaJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins3"
local MajorName = "m_lb_coins1"
local MinorName = "m_lb_coins2"

function ChicEllaJackPotBarView:initUI()

    self:createCsbNode("ChicElla_jackpot.csb")

    self:runCsbAction("idleframe",true)

end


function ChicEllaJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function ChicEllaJackPotBarView:onEnter()
    ChicEllaJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function ChicEllaJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)

    self:updateSize()
end

function ChicEllaJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.55,sy=0.55}
    local info2={label=label2,sx=0.45,sy=0.45}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.42,sy=0.42}

    self:updateLabelSize(info1,614)
    self:updateLabelSize(info2,614)
    self:updateLabelSize(info3,614)

end

function ChicEllaJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end



return ChicEllaJackPotBarView